package com.backendcam.backendcam.service.hls;

import org.bytedeco.javacv.FFmpegFrameGrabber;
import org.bytedeco.javacv.Frame;
import org.bytedeco.javacv.FrameGrabber.ImageMode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.bytedeco.ffmpeg.global.avutil;

/**
 * Configures FFmpeg frame grabber for RTSP stream input.
 * Singleton bean — stateless, safe for concurrent use across streams.
 */
@Component
public class FFmpegGrabberConfig {

    private static final Logger logger = LoggerFactory.getLogger(FFmpegGrabberConfig.class);

    private static final int MAX_INIT_RETRIES = 5;
    private static final int INIT_RETRY_DELAY_MS = 3000;
    private static final int MAX_DIMENSION_RETRIES = 5;
    private static final int DIMENSION_RETRY_DELAY_MS = 1000;

    // ─── Public API: create grabber with full retry logic ─────────────

    /**
     * Create and start an RTSP grabber with automatic retries on failure.
     * Also handles HEVC dimension-detection probing.
     *
     * @param rtspUrl    RTSP source URL
     * @param streamName for logging
     * @param context    stream context (checked for shouldStop, grabber reference stored here)
     * @return a started FFmpegFrameGrabber with valid width/height
     * @throws Exception if all retries exhausted or interrupted
     */
    public FFmpegFrameGrabber startGrabberWithRetry(String rtspUrl, String streamName,
                                                     StreamContext context) throws Exception {
        Exception lastException = null;

        for (int attempt = 1; attempt <= MAX_INIT_RETRIES; attempt++) {
            if (context.shouldStop || Thread.currentThread().isInterrupted()) {
                throw new InterruptedException("Stream stopped during grabber init");
            }

            FFmpegFrameGrabber grabber = null;
            try {
                grabber = new FFmpegFrameGrabber(rtspUrl);
                context.grabber = grabber;
                configureGrabber(grabber); // sets options + calls start()

                // Dimension detection with retries (HEVC cameras may need probing)
                int width = grabber.getImageWidth();
                int height = grabber.getImageHeight();

                for (int dr = 0; dr < MAX_DIMENSION_RETRIES && (width <= 0 || height <= 0); dr++) {
                    logger.warn("Stream {} - Invalid dimensions {}x{}, probing {}/{}...",
                            streamName, width, height, dr + 1, MAX_DIMENSION_RETRIES);
                    for (int i = 0; i < 30; i++) {
                        Frame probeFrame = grabber.grabImage();
                        if (probeFrame != null) probeFrame.close();
                    }
                    width = grabber.getImageWidth();
                    height = grabber.getImageHeight();
                    if (width <= 0 || height <= 0) Thread.sleep(DIMENSION_RETRY_DELAY_MS);
                }

                if (width <= 0 || height <= 0) {
                    throw new RuntimeException("Invalid resolution " + width + "x" + height);
                }

                logger.info("Stream {} - Grabber ready ({}x{}) on attempt {}", streamName, width, height, attempt);
                return grabber;

            } catch (InterruptedException ie) {
                safeClose(grabber);
                context.grabber = null;
                throw ie;
            } catch (Exception e) {
                lastException = e;
                logger.warn("Stream {} - Grabber init attempt {}/{} failed: {}",
                        streamName, attempt, MAX_INIT_RETRIES, e.getMessage());
                safeClose(grabber);
                context.grabber = null;
                if (attempt < MAX_INIT_RETRIES) Thread.sleep(INIT_RETRY_DELAY_MS);
            }
        }
        throw new RuntimeException("Grabber init failed after " + MAX_INIT_RETRIES + " attempts", lastException);
    }

    /**
     * Safely stop and release a grabber, ignoring errors.
     */
    public void safeClose(FFmpegFrameGrabber grabber) {
        if (grabber == null) return;
        try { grabber.stop(); } catch (Exception ignored) {}
        try { grabber.release(); } catch (Exception ignored) {}
    }

    // ─── Internal: configure options ──────────────────────────────────

    /**
     * Configure grabber for LIVE STREAMING (low latency, optimized for HLS output)
     * Use this for real-time streaming where latency matters more than frame quality
     * 
     * @param grabber The FFmpegFrameGrabber to configure
     * @throws Exception if configuration fails
     */
    private void configureGrabber(FFmpegFrameGrabber grabber) throws Exception {
        avutil.av_log_set_level(avutil.AV_LOG_FATAL);

        grabber.setFormat("rtsp");
        grabber.setImageMode(ImageMode.COLOR);

        // Probe settings - must be large enough to detect HEVC/H.265 resolution
        // Too small (e.g. 32) causes "Picture size 0x0" errors on HEVC cameras
        grabber.setOption("analyzeduration", "1000000");  // 1 second to analyze stream
        grabber.setOption("probesize", "1000000");        // 1MB to detect codec params
        grabber.setOption("max_delay", "500000");          // 500ms max delay
        grabber.setOption("reorder_queue_size", "0");

        // Flags configuration for minimum latency
        grabber.setOption("fflags", "+nobuffer+discardcorrupt+igndts+genpts");
        grabber.setOption("flags", "low_delay");

        // RTSP specific settings
        grabber.setOption("rtsp_transport", "tcp");
        grabber.setOption("rtsp_flags", "prefer_tcp");

        grabber.setOption("stimeout", "5000000"); //socket timeout 5 secs
        grabber.setOption("rw_timeout", "5000000"); //read write timeout 5 secs

        grabber.setOption("allowed_media_types", "video");
        grabber.setOption("use_wallclock_as_timestamps", "1");

        grabber.setOption("err_detect", "ignore_err");

        grabber.start();
    }

    /**
     * Configure grabber for MOTION DETECTION (proper frame quality for image saving)
     * Use this when you need to save/upload frames with correct colors.
     * NOTE: This does NOT have retry logic — add if needed.
     * 
     * @param grabber The FFmpegFrameGrabber to configure
     * @throws Exception if configuration fails
     */
    public void configureGrabberForMotionDetection(FFmpegFrameGrabber grabber) throws Exception {
        grabber.setFormat("rtsp");
        grabber.setImageMode(ImageMode.COLOR);
        
        // Set pixel format to ensure proper color conversion
        grabber.setPixelFormat(org.bytedeco.ffmpeg.global.avutil.AV_PIX_FMT_BGR24);

        // Sufficient values for proper codec detection and frame quality
        grabber.setOption("analyzeduration", "2000000");  // 2 seconds to analyze stream format
        grabber.setOption("probesize", "5000000");        // 5MB to detect codec parameters
        grabber.setOption("max_delay", "500000");         // 500ms max delay
        
        // Request keyframe at start for proper H.264 decoding
        grabber.setOption("skip_frame", "nokey");         // Don't skip keyframes
        grabber.setOption("skip_loop_filter", "all");     // Skip loop filter for speed

        // Flags - keep frames intact for proper decoding
        grabber.setOption("fflags", "+genpts");
        grabber.setOption("flags", "low_delay");

        // RTSP specific settings
        grabber.setOption("rtsp_transport", "tcp");
        grabber.setOption("rtsp_flags", "prefer_tcp");

        grabber.setOption("stimeout", "5000000"); //socket timeout 5 secs
        grabber.setOption("rw_timeout", "5000000"); //read write timeout 5 secs

        grabber.setOption("allowed_media_types", "video");
        grabber.setOption("use_wallclock_as_timestamps", "1");

        grabber.start();
    }
}
