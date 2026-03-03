package com.motion_detect.motion_detect.config;

import org.bytedeco.ffmpeg.global.avutil;
import org.bytedeco.javacv.FFmpegFrameGrabber;
import org.bytedeco.javacv.Frame;
import org.bytedeco.javacv.FrameGrabber.ImageMode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Configures FFmpeg frame grabber for RTSP stream input with retry logic.
 * Used for motion detection - ensures reliable connection and proper frame
 * quality.
 */
@Slf4j
@Component
public class FFmpegGrabberConfig {

    private static final int MAX_INIT_RETRIES = 5;
    private static final int INIT_RETRY_DELAY_MS = 3000;
    private static final int MAX_DIMENSION_RETRIES = 5;
    private static final int DIMENSION_RETRY_DELAY_MS = 1000;

    /**
     * Create and start an RTSP grabber with automatic retries on failure.
     * Also handles HEVC dimension-detection probing.
     */
    public FFmpegFrameGrabber startGrabberWithRetry(String rtspUrl, String cameraId) throws Exception {
        Exception lastException = null;

        for (int attempt = 1; attempt <= MAX_INIT_RETRIES; attempt++) {
            if (Thread.currentThread().isInterrupted()) {
                throw new InterruptedException("Interrupted during grabber init");
            }

            FFmpegFrameGrabber grabber = null;
            try {
                grabber = new FFmpegFrameGrabber(rtspUrl);
                configureGrabber(grabber);

                // Dimension detection with retries (HEVC cameras may need probing)
                int width = grabber.getImageWidth();
                int height = grabber.getImageHeight();

                for (int dr = 0; dr < MAX_DIMENSION_RETRIES && (width <= 0 || height <= 0); dr++) {
                    log.warn("Camera {} - Invalid dimensions {}x{}, probing {}/{}...",
                            cameraId, width, height, dr + 1, MAX_DIMENSION_RETRIES);
                    for (int i = 0; i < 30; i++) {
                        Frame probeFrame = grabber.grabImage();
                        if (probeFrame != null)
                            probeFrame.close();
                        Thread.sleep(100);
                    }
                    width = grabber.getImageWidth();
                    height = grabber.getImageHeight();
                    if (width <= 0 || height <= 0)
                        Thread.sleep(DIMENSION_RETRY_DELAY_MS);
                }

                if (width <= 0 || height <= 0) {
                    throw new RuntimeException("Invalid resolution " + width + "x" + height);
                }

                log.info("Camera {} - Grabber ready ({}x{}) on attempt {}", cameraId, width, height, attempt);
                return grabber;

            } catch (InterruptedException ie) {
                safeClose(grabber);
                throw ie;
            } catch (Exception e) {
                lastException = e;
                log.warn("Camera {} - Grabber init attempt {}/{} failed: {}",
                        cameraId, attempt, MAX_INIT_RETRIES, e.getMessage());
                safeClose(grabber);
                if (attempt < MAX_INIT_RETRIES)
                    Thread.sleep(INIT_RETRY_DELAY_MS);
            }
        }
        throw new RuntimeException("Grabber init failed after " + MAX_INIT_RETRIES + " attempts", lastException);
    }

    /**
     * Configure grabber for motion detection with proper color handling.
     */
    private void configureGrabber(FFmpegFrameGrabber grabber) throws Exception {
        avutil.av_log_set_level(avutil.AV_LOG_FATAL);

        grabber.setFormat("rtsp");
        grabber.setImageMode(ImageMode.COLOR);

        // Probe settings - must be large enough to detect HEVC/H.265 resolution
        grabber.setOption("analyzeduration", "1000000"); // 1 second to analyze stream
        grabber.setOption("probesize", "1000000"); // 1MB to detect codec params
        grabber.setOption("max_delay", "500000"); // 500ms max delay
        grabber.setOption("reorder_queue_size", "0");

        // Flags configuration for minimum latency
        grabber.setOption("fflags", "+nobuffer+discardcorrupt+igndts+genpts");
        grabber.setOption("flags", "low_delay");

        // RTSP specific settings
        grabber.setOption("rtsp_transport", "tcp");
        grabber.setOption("rtsp_flags", "prefer_tcp");

        grabber.setOption("stimeout", "5000000"); // socket timeout 5 secs
        grabber.setOption("rw_timeout", "5000000"); // read write timeout 5 secs

        grabber.setOption("allowed_media_types", "video");
        grabber.setOption("use_wallclock_as_timestamps", "1");
        // ===== CPU Optimization =====

        // decode แค่ 5 fps
        grabber.setOption("r", "5");
        grabber.setOption("vsync", "drop");

        // ปิด audio (ลด CPU อีก)
        grabber.setOption("an", "1");

        grabber.setOption("err_detect", "ignore_err");

        grabber.start();
    }

    /**
     * Safely stop and release a grabber, ignoring errors.
     */
    public void safeClose(FFmpegFrameGrabber grabber) {
        if (grabber == null)
            return;
        try {
            grabber.stop();
        } catch (Exception ignored) {
        }
        try {
            grabber.release();
        } catch (Exception ignored) {
        }
    }
}
