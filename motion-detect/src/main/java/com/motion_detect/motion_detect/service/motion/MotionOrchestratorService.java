package com.motion_detect.motion_detect.service.motion;

import org.bytedeco.javacv.Frame;
import org.bytedeco.javacv.Java2DFrameConverter;
import org.bytedeco.opencv.opencv_core.Mat;
import lombok.extern.slf4j.Slf4j;

import java.awt.Graphics;
import java.awt.image.BufferedImage;

@Slf4j
// Not a Spring bean — instantiated per-camera by MotionDetectionService
// Single-threaded: detect → snapshot → upload → loop (no extra threads)
public class MotionOrchestratorService {

    private static final long   MOTION_COOLDOWN_MS  = 3000;
    private static final double SHARPNESS_THRESHOLD = 120.0;
    private static final int    FRAME_SKIP = 0;

    private final SaveMotionFrameService saveService;

    // Used only for the snapshot deep-copy
    private final Java2DFrameConverter snapshotConverter = new Java2DFrameConverter();

    private MotionDetector detector;
    private long lastMotionTime = 0;
    private int  frameCounter   = 0;

    public MotionOrchestratorService(SaveMotionFrameService saveService, String cameraId) {
        this.saveService = saveService;
    }

    public void initialize(int width, int height) {
        detector = new MotionDetector();
        detector.initialize(width, height);
    }

    public void processFrame(Frame frame, String cameraId) {
        if (frame == null || frame.image == null) return;
        if (frame.imageWidth <= 0 || frame.imageHeight <= 0) return;

        if (FRAME_SKIP > 0 && ++frameCounter % FRAME_SKIP != 0) return;

        try {
            Mat mat = detector.convertFrame(frame);
            if (mat == null) return;

            boolean hasMotion = detector.detectMotion(mat);
            if (!hasMotion) return;

            long now = System.currentTimeMillis();
            if (now - lastMotionTime < MOTION_COOLDOWN_MS) return;

            double sharpness = detector.calculateSharpness(mat);
            if (sharpness < SHARPNESS_THRESHOLD) {
                log.debug("Motion detected but sharpness too low: {} for camera: {}", sharpness, cameraId);
                return;
            }

            log.info("Motion detected! Sharpness: {} for camera: {}", sharpness, cameraId);
            lastMotionTime = now;

            // Snapshot + upload on the SAME thread (no extra thread needed)
            final BufferedImage snapshot = deepCopy(frame);
            if (snapshot != null) {
                saveService.uploadMotionFrame(snapshot, cameraId);
            }

        } catch (Exception e) {
            log.debug("Error processing frame for camera {}: {}", cameraId, e.getMessage());
        }
        // Do NOT close mat — it's the converter's internal buffer
    }

    /** Copies the frame's pixel data into a standalone BufferedImage. */
    private BufferedImage deepCopy(Frame frame) {
        if (frame == null || frame.image == null) return null;
        if (frame.imageWidth <= 0 || frame.imageHeight <= 0) return null;
        
        BufferedImage original = snapshotConverter.convert(frame);
        if (original == null) return null;

        BufferedImage copy = new BufferedImage(
                original.getWidth(), original.getHeight(), BufferedImage.TYPE_3BYTE_BGR);
        Graphics g = copy.getGraphics();
        try {
            g.drawImage(original, 0, 0, null);
        } finally {
            g.dispose();
        }
        return copy;
    }

    public void cleanup() {
        if (snapshotConverter != null) {
            try { snapshotConverter.close(); } catch (Exception e) { /* ignore */ }
        }
        if (detector != null) {
            detector.cleanup();
        }
    }
}
