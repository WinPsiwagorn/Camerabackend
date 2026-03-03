package com.backendcam.backendcam.service.motion;

import org.bytedeco.javacv.Frame;
import org.bytedeco.javacv.Java2DFrameConverter;
import org.bytedeco.opencv.opencv_core.Mat;

import java.awt.Graphics;
import java.awt.image.BufferedImage;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

// Not a Spring bean — instantiated per-stream by HLSStreamService
public class MotionOrchestratorService {

    private static final long   MOTION_COOLDOWN_MS  = 5000;
    private static final double SHARPNESS_THRESHOLD = 120.0;
    /**
     * Process 1 out of every FRAME_SKIP frames for motion detection.
     * At 25 fps this gives ~8 checks/sec — perfectly sufficient for motion.
     * Cuts detection CPU by ~66%.
     */
    private static final int FRAME_SKIP = 3;

    private final SaveMotionFrameService saveService;

    // Used only for the snapshot deep-copy before async upload
    private final Java2DFrameConverter snapshotConverter = new Java2DFrameConverter();

    // Single background thread for Firebase uploads so the stream thread never blocks
    private final ExecutorService uploadExecutor = Executors.newSingleThreadExecutor(r -> {
        Thread t = new Thread(r, "motion-upload");
        t.setDaemon(true);
        return t;
    });

    private MotionDetector detector;
    private long lastMotionTime = 0;
    private int  frameCounter   = 0;

    public MotionOrchestratorService(SaveMotionFrameService saveService) {
        this.saveService = saveService;
    }

    public void init(int width, int height) {
        detector = new MotionDetector();
        detector.initialize(width, height);
    }

    public void processFrame(Frame frame, String cameraId) {
        if (frame == null || frame.image == null) return;

        // Skip frames — motion detection does not need full frame-rate
        if (++frameCounter % FRAME_SKIP != 0) return;

        try {
            // Convert Frame → Mat ONCE; pass the same Mat to both methods
            Mat mat = detector.convertFrame(frame);

            boolean hasMotion = detector.detectMotion(mat);
            if (!hasMotion) return;

            long now = System.currentTimeMillis();
            if (now - lastMotionTime < MOTION_COOLDOWN_MS) return;

            double sharpness = detector.calculateSharpness(mat);
            if (sharpness < SHARPNESS_THRESHOLD) return;

            lastMotionTime = now;

            // Deep-copy frame pixels to a JVM BufferedImage NOW (fast — pure memory copy)
            // so the stream thread can close the original frame immediately after.
            // The actual JPEG encode + Firebase upload runs asynchronously.
            final BufferedImage snapshot = deepCopy(frame);
            if (snapshot != null) {
                uploadExecutor.submit(() -> saveService.uploadMotionFrame(snapshot, cameraId));
            }

        } catch (Exception ignored) {
            // prevent stream crash
        }
    }

    /** Copies the frame's pixel data into a standalone BufferedImage. */
    private BufferedImage deepCopy(Frame frame) {
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
        if (detector != null) {
            detector.cleanup();
        }
        uploadExecutor.shutdown();
        try {
            // Give any in-flight upload up to 10 s to finish before abandoning
            if (!uploadExecutor.awaitTermination(10, TimeUnit.SECONDS)) {
                uploadExecutor.shutdownNow();
            }
        } catch (InterruptedException e) {
            uploadExecutor.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }
}