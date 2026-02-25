package com.backendcam.backendcam.service.hls;

import java.io.File;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.bytedeco.javacv.FFmpegFrameGrabber;
import org.bytedeco.javacv.FFmpegFrameRecorder;
import org.bytedeco.javacv.Frame;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;

@Service
public class HLSStreamService {

    private static final Logger logger = LoggerFactory.getLogger(HLSStreamService.class);
    private static final int MAX_RECONNECT_ATTEMPTS = 10;
    private static final int RECONNECT_DELAY_MS = 3000;
    private static final int MAX_NULL_FRAMES = 100;
    private static final int MAX_FULL_RESTARTS = 3; // Full pipeline restart attempts
    private static final long FULL_RESTART_DELAY_MS = 5000; // Delay before full restart

    private final Map<String, Thread> streamThreads = new ConcurrentHashMap<>();
    private final Map<String, StreamContext> streamContexts = new ConcurrentHashMap<>();

    @Autowired
    private FFmpegGrabberConfig grabberConfig;

    @Autowired
    private FFmpegRecorderConfig recorderConfig;

    @Autowired
    private StreamResourceManager resourceManager;

    // Cleanup on startup
    @PostConstruct
    public void init() {
        resourceManager.cleanupAllStreams();
    }

    /**
     * Gracefully shutdown all streams when application stops
     */
    @PreDestroy
    public void shutdown() {
        logger.info("Shutting down HLSStreamService - stopping all streams...");
        String[] streamNames = streamThreads.keySet().toArray(new String[0]);
        for (String streamName : streamNames) {
            try {
                stopHLSStream(streamName);
            } catch (Exception e) {
                logger.error("Error stopping stream {} during shutdown: {}", streamName, e.getMessage());
            }
        }
        logger.info("HLSStreamService shutdown complete");
    }

    // ─── Main entry point ─────────────────────────────────────────────

    public String startHLSStream(String RTSPUrl, String streamName) {

        if (streamThreads.containsKey(streamName)) {
            return "/api/hls/" + streamName + "/stream.m3u8";
        }

        File outputDir = new File(resourceManager.getHlsRoot(), streamName);
        if (!outputDir.exists() && !outputDir.mkdirs()) {
            throw new RuntimeException("Failed to create output directory: " + outputDir.getAbsolutePath());
        }

        StreamContext context = new StreamContext();

        Thread thread = new Thread(() -> {
            String hlsOutput = outputDir.getAbsolutePath().replace('\\', '/') + "/stream.m3u8";
            int fullRestartCount = 0;

            // ── Outer loop: full pipeline restart on fatal errors ──
            while (!Thread.currentThread().isInterrupted() && !context.shouldStop
                    && fullRestartCount <= MAX_FULL_RESTARTS) {

                FFmpegFrameGrabber grabber = null;
                FFmpegFrameRecorder recorder = null;

                try {
                    // Phase 1 — Init grabber (with retries, dimension detection)
                    grabber = grabberConfig.startGrabberWithRetry(RTSPUrl, streamName, context);
                    int width = grabber.getImageWidth();
                    int height = grabber.getImageHeight();

                    // Phase 2 — Init recorder (with retries)
                    recorder = recorderConfig.startRecorderWithRetry(hlsOutput, outputDir, width, height, streamName,
                            context);

                    logger.info("Stream {} - Flushing stale grabber buffer...", streamName);
                    int flushed = 0;
                    for (int i = 0; i < 50; i++) {
                        if (Thread.currentThread().isInterrupted() || context.shouldStop)
                            break;
                        Frame stale = grabber.grabImage();
                        if (stale == null)
                            break;
                        stale.close();
                        flushed++;
                    }
                    logger.info("Stream {} - Flushed {} stale frames", streamName, flushed);
                    // Phase 3 — Frame streaming loop
                    int nullFrameCount = 0;
                    int reconnectAttempts = 0;
                    long frameCount = 0;
                    long lastLogTime = System.currentTimeMillis();

                    while (!Thread.currentThread().isInterrupted() && !context.shouldStop) {
                        try {
                            Frame frame = grabber.grabImage();

                            if (frame == null) {
                                nullFrameCount++;
                                if (nullFrameCount == 50 || nullFrameCount == 100) {
                                    logger.warn("Stream {} - {} consecutive null frames, attempting reconnect...",
                                            streamName, nullFrameCount);

                                    if (reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
                                        reconnectAttempts++;
                                        logger.info("Stream {} - Reconnect attempt {}/{}",
                                                streamName, reconnectAttempts, MAX_RECONNECT_ATTEMPTS);
                                        try {
                                            grabberConfig.safeClose(grabber);
                                            Thread.sleep(RECONNECT_DELAY_MS);
                                            // startGrabberWithRetry creates a fresh grabber internally
                                            grabber = grabberConfig.startGrabberWithRetry(RTSPUrl, streamName, context);
                                            nullFrameCount = 0;
                                            logger.info("Stream {} - Reconnected successfully", streamName);
                                        } catch (Exception reconnectEx) {
                                            logger.error("Stream {} - Reconnect failed: {}",
                                                    streamName, reconnectEx.getMessage());
                                            Thread.sleep(RECONNECT_DELAY_MS);
                                        }
                                    } else {
                                        logger.error("Stream {} - Max reconnects reached, triggering full restart",
                                                streamName);
                                        break; // break inner loop → full restart
                                    }
                                }
                                continue;
                            }

                            // Good frame
                            nullFrameCount = 0;
                            reconnectAttempts = 0;
                            frameCount++;

                            long now = System.currentTimeMillis();
                            if (now - lastLogTime >= 30_000) {
                                logger.info("[{}] ✓ Live | Frames encoded: {}", streamName, frameCount);
                                lastLogTime = now;
                            }

                            recorder.record(frame);
                            frame.close();

                        } catch (org.bytedeco.javacv.FFmpegFrameRecorder.Exception recEx) {
                            // Recorder broken → needs full restart (re-create both grabber + recorder)
                            logger.error("Stream {} - Recorder error, triggering full restart: {}",
                                    streamName, recEx.getMessage());
                            break;
                        } catch (Exception frameEx) {
                            String msg = frameEx.getMessage() != null ? frameEx.getMessage() : "";
                            if (msg.contains("AVFormatContext") || msg.contains("Could not grab")) {
                                logger.error("Stream {} - Grabber lost context, triggering full restart", streamName);
                                break; // breaks inner loop → goes to finally → full pipeline restart
                            } else {
                                logger.warn("Stream {} - Frame error: {}", streamName, msg);
                                nullFrameCount++;
                                try {
                                    Thread.sleep(200);
                                } catch (InterruptedException ie) {
                                    Thread.currentThread().interrupt();
                                    break;
                                }
                            }
                        }
                    }

                } catch (InterruptedException ie) {
                    logger.info("Stream {} interrupted, stopping", streamName);
                    Thread.currentThread().interrupt();
                    break; // exit outer loop
                } catch (Exception e) {
                    logger.error("Stream {} - Pipeline init failed: {}", streamName, e.getMessage(), e);
                } finally {
                    // Clean up before potential restart
                    recorderConfig.safeClose(recorder);
                    context.recorder = null;
                    grabberConfig.safeClose(grabber);
                    context.grabber = null;
                }

                // ── Decide whether to restart ──
                if (!context.shouldStop && !Thread.currentThread().isInterrupted()) {
                    fullRestartCount++;
                    if (fullRestartCount <= MAX_FULL_RESTARTS) {
                        logger.info("Stream {} - Full pipeline restart {}/{}, waiting {}ms...",
                                streamName, fullRestartCount, MAX_FULL_RESTARTS, FULL_RESTART_DELAY_MS);
                        try {
                            Thread.sleep(FULL_RESTART_DELAY_MS);
                        } catch (InterruptedException ie) {
                            Thread.currentThread().interrupt();
                            break;
                        }
                    } else {
                        logger.error("Stream {} - All {} full restart attempts exhausted, giving up",
                                streamName, MAX_FULL_RESTARTS);
                    }
                }
            }

            // Final cleanup
            logger.info("Stream {} thread exiting", streamName);
            resourceManager.cleanupResources(context);
            streamContexts.remove(streamName);
            streamThreads.remove(streamName);
        });

        thread.setName("HLS-" + streamName);
        thread.setDaemon(false);

        StreamContext existingContext = streamContexts.putIfAbsent(streamName, context);
        Thread existingThread = streamThreads.putIfAbsent(streamName, thread);

        if (existingContext != null || existingThread != null) {
            streamContexts.remove(streamName, context);
            streamThreads.remove(streamName, thread);
            return "/api/hls/" + streamName + "/stream.m3u8";
        }

        thread.start();
        logger.info("Started stream thread for {}", streamName);
        return "/api/hls/" + streamName + "/stream.m3u8";
    }

    public String stopHLSStream(String streamName) {
        Thread thread = streamThreads.remove(streamName);
        StreamContext context = streamContexts.get(streamName);

        if (thread == null && context == null) {
            return "Stream not found or already stopped.";
        }

        if (context != null) {
            context.shouldStop = true;
        }

        if (thread != null) {
            thread.interrupt();
            try {
                thread.join(5000);
                if (thread.isAlive()) {
                    if (context != null) {
                        resourceManager.cleanupResources(context);
                    }
                    thread.join(2000);
                    if (thread.isAlive()) {
                        logger.error("Thread {} still alive after forced cleanup. It will be abandoned.", streamName);
                    }
                } else {
                    logger.info("Thread {} stopped gracefully", streamName);
                }
            } catch (InterruptedException e) {
                logger.warn("Interrupted while waiting for thread {} to stop", streamName);
                Thread.currentThread().interrupt();
            }
        }

        streamContexts.remove(streamName);

        try {
            Thread.sleep(500);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        resourceManager.deleteStreamDirectory(streamName);
        logger.info("Stream {} stopped and files deleted", streamName);
        return "Stream stopped and files deleted.";
    }
}
