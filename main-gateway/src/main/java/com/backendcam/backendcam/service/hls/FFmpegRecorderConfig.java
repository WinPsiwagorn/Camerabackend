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

    // SD Quality Settings (Standard Definition)
    private static final int TARGET_FPS = 15;
    private static final int HLS_TIME = 1;
    private static final int VIDEO_BITRATE = 800_000; // 800 Kbps - optimized for 20 concurrent streams
    private static final int MAX_INIT_RETRIES = 5;
    private static final int INIT_RETRY_DELAY_MS = 3000;

    // HD Quality Settings (High Definition - 720p/1080p) - Optimized for Low
    // Latency
    private static final int HD_TARGET_FPS = 10;
    private static final int HD_HLS_TIME = 1; // 1-second segments for lower latency
    private static final int HD_VIDEO_BITRATE_720P = 2500_000; // 2.5 Mbps for 720p
    private static final int HD_VIDEO_BITRATE_1080P = 4500_000; // 4.5 Mbps for 1080p
    private static final int HD_CRF_QUALITY = 23; // Balanced quality for faster encoding

    // FPS is kept at 15 — encoding true 4K at 30fps realtime requires dedicated
    // hardware (NVENC/VAAPI)
    private static final int UHD_TARGET_FPS = 15; // 15fps — max stable for software 4K encoding
    private static final int UHD_HLS_TIME = 2; // 2-second segments — 4K needs more time to flush per segment
    private static final int UHD_VIDEO_BITRATE_2160P = 20_000_000; // 20 Mbps — minimum acceptable for 4K detail
    private static final int UHD_CRF_QUALITY = 28; // Higher CRF = less work per frame, keeps encoder from falling
                                                   // behind

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
     * @param context    stream context (checked for shouldStop, recorder reference
     *                   stored here)
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
                if (attempt < MAX_INIT_RETRIES)
                    Thread.sleep(INIT_RETRY_DELAY_MS);
            }
        }
        throw new RuntimeException("Recorder init failed after " + MAX_INIT_RETRIES + " attempts", lastException);
    }

    /**
     * Create and start an HD HLS recorder with automatic retries.
     * Uses HD-optimized configuration based on resolution (720p/1080p).
     *
     * @param hlsOutput  path to stream.m3u8
     * @param outputDir  HLS segment output directory
     * @param width      video width (1280 for 720p, 1920 for 1080p)
     * @param height     video height (720 or 1080)
     * @param streamName for logging
     * @param context    stream context (checked for shouldStop, recorder reference
     *                   stored here)
     * @return a started FFmpegFrameRecorder configured for HD
     * @throws Exception if all retries exhausted or interrupted
     */
    public FFmpegFrameRecorder startRecorderWithRetryHD(String hlsOutput, File outputDir,
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
                // Ensure output dir exists
                if (!outputDir.exists() && !outputDir.mkdirs()) {
                    throw new RuntimeException("Cannot create dir: " + outputDir.getAbsolutePath());
                }

                recorder = new FFmpegFrameRecorder(hlsOutput, width, height, 0);
                context.recorder = recorder;
                configureRecorderForHD(recorder, outputDir, width, height); // HD configuration

                logger.info("Stream {} - HD Recorder ready ({}p) on attempt {}",
                        streamName, height, attempt);
                return recorder;

            } catch (InterruptedException ie) {
                safeClose(recorder);
                context.recorder = null;
                throw ie;
            } catch (Exception e) {
                lastException = e;
                logger.warn("Stream {} - HD Recorder init attempt {}/{} failed: {}",
                        streamName, attempt, MAX_INIT_RETRIES, e.getMessage());
                safeClose(recorder);
                context.recorder = null;
                if (attempt < MAX_INIT_RETRIES)
                    Thread.sleep(INIT_RETRY_DELAY_MS);
            }
        }
        throw new RuntimeException("HD Recorder init failed after " + MAX_INIT_RETRIES + " attempts", lastException);
    }

    /**
     * Safely stop and release a recorder, ignoring errors.
     */
    public void safeClose(FFmpegFrameRecorder recorder) {
        if (recorder == null)
            return;
        try {
            recorder.stop();
        } catch (Exception ignored) {
        }
        try {
            recorder.release();
        } catch (Exception ignored) {
        }
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
                "expr:gte(t,n_forced*" + HLS_TIME + ")");

        // HLS specific settings
        recorder.setOption("hls_time", String.valueOf(HLS_TIME)); // segment duration
        recorder.setOption("hls_list_size", "3"); // number of segments to keep
        recorder.setOption("hls_delete_threshold", "1"); // segment to keep before delete_segments
        recorder.setOption("hls_allow_cache", "0"); // disable cache
        recorder.setOption("hls_segment_type", "mpegts"); // segment format (mpegts = legacy, compatible) / (fmp4 =
                                                          // modern, ll-hls)
        recorder.setOption("hls_flags",
                "delete_segments+omit_endlist+temp_file+program_date_time+independent_segments");

        // Segment filename pattern - use normalized path
        String segPath = normalizedPath + "/s%04d.ts";
        recorder.setOption("hls_segment_filename", segPath);

        // Thread configuration
        recorder.setOption("threads", "1"); // Comment if production have multiple core/thread

        // Encoder performance / latency - ultrafast to minimize CPU for many concurrent
        // streams
        recorder.setOption("preset", "ultrafast");
        recorder.setOption("tune", "zerolatency");
        recorder.setOption("bf", "0");
        recorder.setOption("refs", "1"); // Minimal reference frames for lower CPU
        recorder.setOption("vsync", "cfr");

        // start
        recorder.start();
    }

    /**
     * Configure recorder for HD HLS streaming (720p or 1080p)
     * Use this for high-definition streaming with better quality and higher
     * bitrates.
     * Automatically selects appropriate bitrate based on resolution.
     * 
     * @param recorder  The FFmpegFrameRecorder to configure
     * @param outputDir The output directory for HLS files
     * @param width     Video width (1280 for 720p, 1920 for 1080p)
     * @param height    Video height (720 or 1080)
     * @throws Exception if configuration fails
     */
    public void configureRecorderForHD(FFmpegFrameRecorder recorder, File outputDir, int width, int height)
            throws Exception {
        // Normalize path to forward slashes for FFmpeg compatibility
        String normalizedPath = outputDir.getAbsolutePath().replace('\\', '/');

        boolean is4K = (height > 1080);
        boolean is1080p = (height == 1080);
        // boolean is720p = (height <= 720);
        int bitrate = is4K ? UHD_VIDEO_BITRATE_2160P
                : is1080p ? HD_VIDEO_BITRATE_1080P
                        : HD_VIDEO_BITRATE_720P;

        int targetFPS = is4K ? UHD_TARGET_FPS : HD_TARGET_FPS;
        int hlsTime = is4K ? UHD_HLS_TIME : HD_HLS_TIME;
        int crfQuality = is4K ? UHD_CRF_QUALITY : HD_CRF_QUALITY;
        // Determine output resolution dynamically based on input height
        // Downscales to the appropriate target rather than hardcoding 1920x1080

        int targetWidth;
        int targetHeight;

        if (is4K) {
            
            // 4K input → output true 4K (no downscale)
            targetWidth = 3840;
            targetHeight = 2160;
        } else if (is1080p) {
            // 1080p input → output 1080p
            targetWidth = 1920;
            targetHeight = 1080;
        } else {
            // 720p or below → output native resolution, no upscale
            targetWidth = width;
            targetHeight = height;
        }

        recorder.setImageWidth(targetWidth);
        recorder.setImageHeight(targetHeight);
        recorder.setVideoCodec(avcodec.AV_CODEC_ID_H264);
        recorder.setFormat("hls");

        // HD Video quality settings
        recorder.setVideoBitrate(bitrate);
        recorder.setVideoQuality(crfQuality); // CRF value for quality (lower is better, 18-28 typical)

        // Timing & keyframes for HD
        recorder.setFrameRate(targetFPS);
        recorder.setGopSize(targetFPS * hlsTime);
        recorder.setOption("keyint_min", String.valueOf(targetFPS * hlsTime));
        recorder.setOption("sc_threshold", "0");
        recorder.setOption("x264-params", "no-scenecut=1:force-cfr=1");
        recorder.setOption(
                "force_key_frames",
                "expr:gte(t,n_forced*" + hlsTime + ")");

        // HLS specific settings for HD - Optimized for Low Latency
        recorder.setOption("hls_time", String.valueOf(hlsTime)); // segment duration
        recorder.setOption("hls_list_size", "5"); // 5s buffer — resilient against encode hiccups without too much delay
        recorder.setOption("hls_delete_threshold", "1"); // keep 1 segment before deleting old ones
        recorder.setOption("hls_allow_cache", "0");
        //recorder.setOption("hls_version", "3"); 
        recorder.setOption("hls_segment_type", "mpegts");
        recorder.setOption("hls_flags", "delete_segments+omit_endlist");//+temp_file+independent_segments

        // Segment filename pattern - use normalized path
        String segPath = normalizedPath + "/s%04d.ts";
        recorder.setOption("hls_segment_filename", segPath);

        // FIX: Fixed at 2 threads per stream for predictable multi-camera resource
        // control
        // Keeping this hardcoded ensures each camera gets equal, controlled CPU
        // allocation
        recorder.setOption("threads", "2");
        //recorder.setOption("threads", is4K ? "4" : "2");


        // FIX: Changed from "fast" to "superfast"
        // "fast" preset does lookahead analysis that 2 threads cannot handle in
        // realtime at HD resolution
        // "superfast" removes that lookahead pressure while still producing acceptable
        // HD quality
        recorder.setOption("preset", "superfast");

        recorder.setOption("tune", "zerolatency"); // Critical for live streaming
        recorder.setOption("bf", "0"); // No B-frames for lower latency

        // FIX: Increased refs from 2 to 4
        // profile=high supports up to refs=16 — refs=2 was underutilizing it
        // refs=4 gives better compression/quality at same bitrate with minimal extra
        // CPU at superfast preset
        recorder.setOption("refs", "2");

        recorder.setOption("vsync", "cfr");
        recorder.setOption("profile", "high"); // H.264 High profile for HD
        recorder.setOption("level", is4K ? "5.1" : "4.1"); // H.264 level 4.1 supports 1080p@30fps

        // start
        recorder.start();
    }
}