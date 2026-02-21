package com.backendcam.backendcam.service.hls;

import java.io.File;

import org.bytedeco.ffmpeg.global.avcodec;
import org.bytedeco.javacv.FFmpegFrameRecorder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Configures FFmpeg frame recorder for HLS output.
 * Singleton bean — stateless, safe for concurrent use across streams.
 */
@Component
class FFmpegRecorderConfig {

    private static final Logger logger = LoggerFactory.getLogger(FFmpegRecorderConfig.class);

    private static final int TARGET_FPS = 25;
    private static final int HLS_TIME = 1;
    private static final int VIDEO_BITRATE = 800_000; // 800 Kbps - optimized for 20 concurrent streams
    private static final int MAX_INIT_RETRIES = 5;
    private static final int INIT_RETRY_DELAY_MS = 3000;

    // ─── Public API: create recorder with full retry logic ────────────

    /**
     * Create and start an HLS recorder with automatic retries on failure.
     * Recreates output directory on each attempt if needed.
     *
     * @param hlsOutput  path to stream.m3u8
     * @param outputDir  HLS segment output directory
     * @param width      video width
     * @param height     video height
     * @param streamName for logging
     * @param context    stream context (checked for shouldStop, recorder reference stored here)
     * @return a started FFmpegFrameRecorder
     * @throws Exception if all retries exhausted or interrupted
     */
    public FFmpegFrameRecorder startRecorderWithRetry(String hlsOutput, File outputDir,
                                                       int width, int height,
                                                       String streamName,
                                                       StreamContext context) throws Exception {
        Exception lastException = null;

        for (int attempt = 1; attempt <= MAX_INIT_RETRIES; attempt++) {
            if (context.shouldStop || Thread.currentThread().isInterrupted()) {
                throw new InterruptedException("Stream stopped during recorder init");
            }

            FFmpegFrameRecorder recorder = null;
            try {
                // Ensure output dir exists (may have been cleaned on prior attempt)
                if (!outputDir.exists() && !outputDir.mkdirs()) {
                    throw new RuntimeException("Cannot create dir: " + outputDir.getAbsolutePath());
                }

                recorder = new FFmpegFrameRecorder(hlsOutput, width, height, 0);
                context.recorder = recorder;
                configureRecorder(recorder, outputDir); // sets options + calls start()

                logger.info("Stream {} - Recorder ready on attempt {}", streamName, attempt);
                return recorder;

            } catch (InterruptedException ie) {
                safeClose(recorder);
                context.recorder = null;
                throw ie;
            } catch (Exception e) {
                lastException = e;
                logger.warn("Stream {} - Recorder init attempt {}/{} failed: {}",
                        streamName, attempt, MAX_INIT_RETRIES, e.getMessage());
                safeClose(recorder);
                context.recorder = null;
                if (attempt < MAX_INIT_RETRIES) Thread.sleep(INIT_RETRY_DELAY_MS);
            }
        }
        throw new RuntimeException("Recorder init failed after " + MAX_INIT_RETRIES + " attempts", lastException);
    }

    /**
     * Safely stop and release a recorder, ignoring errors.
     */
    public void safeClose(FFmpegFrameRecorder recorder) {
        if (recorder == null) return;
        try { recorder.stop(); } catch (Exception ignored) {}
        try { recorder.release(); } catch (Exception ignored) {}
    }

    // ─── Internal: configure options ──────────────────────────────────

    /**
     * Configure recorder with all necessary options for HLS streaming
     * 
     * @param recorder  The FFmpegFrameRecorder to configure
     * @param outputDir The output directory for HLS files
     * @throws Exception if configuration fails
     */
    private void configureRecorder(FFmpegFrameRecorder recorder, File outputDir) throws Exception {
        // Normalize path to forward slashes for FFmpeg compatibility
        String normalizedPath = outputDir.getAbsolutePath().replace('\\', '/');
        
        recorder.setVideoCodec(avcodec.AV_CODEC_ID_H264);
        recorder.setFormat("hls");
        
        // Video quality settings
        recorder.setVideoBitrate(VIDEO_BITRATE);
        recorder.setVideoQuality(23); // CRF value (lower = better quality, 18-28 typical)
        
        // timing & keyframes
        recorder.setFrameRate(TARGET_FPS);
        recorder.setGopSize(TARGET_FPS * HLS_TIME);
        recorder.setOption("keyint_min", String.valueOf(TARGET_FPS * HLS_TIME));
        recorder.setOption("sc_threshold", "0");
        recorder.setOption("x264-params", "no-scenecut=1:force-cfr=1");
        recorder.setOption(
            "force_key_frames",
            "expr:gte(t,n_forced*" + HLS_TIME + ")"
        );
        
        // HLS specific settings
        recorder.setOption("hls_time", String.valueOf(HLS_TIME)); //segment duration
        recorder.setOption("hls_list_size", "3"); //number of segments to keep
        recorder.setOption("hls_delete_threshold", "1"); //segment to keep before delete_segments
        recorder.setOption("hls_allow_cache", "0"); //disable cache
        recorder.setOption("hls_segment_type", "mpegts"); //segment format (mpegts = legacy, compatible) / (fmp4 = modern, ll-hls)
        recorder.setOption("hls_flags", "delete_segments+omit_endlist+temp_file+program_date_time+independent_segments");
  

        // Segment filename pattern - use normalized path
        String segPath = normalizedPath + "/s%04d.ts";
        recorder.setOption("hls_segment_filename", segPath);

        // Thread configuration
        recorder.setOption("threads", "1"); //Comment if production have multiple core/thread

        // Encoder performance / latency - ultrafast to minimize CPU for many concurrent streams
        recorder.setOption("preset", "ultrafast");
        recorder.setOption("tune", "zerolatency");
        recorder.setOption("bf", "0");
        recorder.setOption("refs", "1"); // Minimal reference frames for lower CPU
        recorder.setOption("vsync", "cfr");

        // start
        recorder.start();
    }
}