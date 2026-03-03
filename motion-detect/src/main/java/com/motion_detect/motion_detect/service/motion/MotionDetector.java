package com.motion_detect.motion_detect.service.motion;

import lombok.extern.slf4j.Slf4j;
import org.bytedeco.javacpp.indexer.DoubleIndexer;
import org.bytedeco.javacv.Frame;
import org.bytedeco.javacv.OpenCVFrameConverter;
import org.bytedeco.opencv.opencv_core.*;
import org.bytedeco.opencv.opencv_video.BackgroundSubtractorMOG2;

import static org.bytedeco.opencv.global.opencv_core.*;
import static org.bytedeco.opencv.global.opencv_imgproc.*;
import static org.bytedeco.opencv.global.opencv_video.createBackgroundSubtractorMOG2;

@Slf4j
public class MotionDetector {

    // Max width used for detection — full resolution is not needed
    private static final int DETECTION_MAX_WIDTH = 640;

    private BackgroundSubtractorMOG2 mog2;
    private final OpenCVFrameConverter.ToMat converter = new OpenCVFrameConverter.ToMat();

    // Pre-allocated, reused every frame — no per-call heap allocation
    private Mat fgMask;
    private Mat kernel;
    private Mat resized;   // downscaled frame for MOG2
    private Mat gray;      // grayscale for sharpness
    private Mat laplacian; // laplacian output for sharpness

    // Pre-allocated Mat outputs for meanStdDev — Scalar is not accepted by this binding
    private Mat meanMat  = new Mat();
    private Mat stdMat   = new Mat();

    private int detectionWidth;
    private int detectionHeight;
    private boolean needsResize;

    public void initialize(int width, int height) {
        // Downscale to at most DETECTION_MAX_WIDTH, keep aspect ratio, ensure even dims
        double scale = Math.min(1.0, (double) DETECTION_MAX_WIDTH / width);
        detectionWidth  = ((int) (width  * scale)) & ~1;
        detectionHeight = ((int) (height * scale)) & ~1;
        needsResize = (detectionWidth < width || detectionHeight < height);

        mog2      = createBackgroundSubtractorMOG2(100, 16, true);
        fgMask    = new Mat(detectionHeight, detectionWidth, CV_8UC1);
        resized   = new Mat(detectionHeight, detectionWidth, CV_8UC3);
        gray      = new Mat(detectionHeight, detectionWidth, CV_8UC1);
        laplacian = new Mat(detectionHeight, detectionWidth, CV_64F);
        kernel    = getStructuringElement(MORPH_RECT, new Size(3, 3));
        
        log.info("MotionDetector initialized: {}x{}, resize={}", detectionWidth, detectionHeight, needsResize);
    }

    /**
     * Convert Frame to Mat once — call this in the orchestrator and pass the
     * result to both detectMotion() and calculateSharpness() to avoid
     * converting the same frame twice.
     */
    public Mat convertFrame(Frame frame) {
        if (frame == null || frame.image == null || frame.image.length == 0) {
            return null;
        }
        
        // Validate buffer capacity to avoid null pointer in native code
        try {
            for (int i = 0; i < frame.image.length; i++) {
                if (frame.image[i] == null || frame.image[i].capacity() <= 0) {
                    return null;
                }
            }
            Mat result = converter.convert(frame);
            
            // CRITICAL: Validate converted Mat is not empty
            if (result == null || result.empty() || result.cols() <= 0 || result.rows() <= 0) {
                log.debug("Converted Mat is null or empty");
                return null;
            }
            
            return result;
        } catch (Exception e) {
            // Catch JavaCV native pointer exceptions gracefully
            log.debug("Frame conversion failed: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Detect motion using the pre-allocated, downscaled pipeline.
     * Accepts a Mat so the caller can reuse a single conversion.
     */
    public boolean detectMotion(Mat mat) {
        if (mat == null || mat.empty()) return false;

        // Downscale to detection resolution before running MOG2
        Mat input = mat;
        if (needsResize) {
            try {
                resize(mat, resized, new Size(detectionWidth, detectionHeight));
                // Validate resize succeeded
                if (resized.empty() || resized.cols() != detectionWidth || resized.rows() != detectionHeight) {
                    log.debug("Resize failed or produced invalid Mat");
                    return false;
                }
                input = resized;
            } catch (Exception e) {
                log.debug("Exception during resize: {}", e.getMessage());
                return false;
            }
        }

        try {
            mog2.apply(input, fgMask);
            
            // Validate MOG2 output
            if (fgMask.empty()) {
                log.debug("MOG2 produced empty fgMask");
                return false;
            }
            
            morphologyEx(fgMask, fgMask, MORPH_OPEN, kernel);

            int motionPixels = countNonZero(fgMask);
            int totalPixels  = fgMask.rows() * fgMask.cols();
            
            if (totalPixels <= 0) return false;

            return (double) motionPixels / totalPixels > 0.02; // 2% threshold
        } catch (Exception e) {
            log.debug("Exception in motion detection: {}", e.getMessage());
            return false;
        }
    }

    /**
     * Calculate Laplacian sharpness using pre-allocated Mats.
     * IMPORTANT: Does NOT reuse resized from detectMotion() to avoid pointer lifecycle issues.
     * Always works with the input mat parameter directly to ensure valid pointers.
     */
    public double calculateSharpness(Mat mat) {
        if (mat == null || mat.empty()) return 0;

        try {
            // Always resize fresh into our buffer (do NOT reuse from detectMotion)
            Mat src = mat;
            if (needsResize) {
                resize(mat, resized, new Size(detectionWidth, detectionHeight));
                // Validate resize succeeded
                if (resized.empty()) {
                    log.debug("Resize for sharpness failed");
                    return 0;
                }
                src = resized;
            }

            cvtColor(src, gray, COLOR_BGR2GRAY);
            if (gray.empty()) {
                log.debug("cvtColor produced empty gray Mat");
                return 0;
            }
            
            Laplacian(gray, laplacian, CV_64F);
            if (laplacian.empty()) {
                log.debug("Laplacian produced empty Mat");
                return 0;
            }

            // meanStdDev requires Mat outputs in this JavaCV binding, not Scalar
            meanStdDev(laplacian, meanMat, stdMat);

            // stdMat is a 1×1 CV_64F Mat — read the single double via DoubleIndexer
            DoubleIndexer idx = stdMat.createIndexer();
            double sigmaVal = idx.get(0);
            idx.close();
            return sigmaVal * sigmaVal;
        } catch (Exception e) {
            log.debug("Exception in calculateSharpness: {}", e.getMessage());
            return 0;
        }
    }

    public void cleanup() {
        // Close the converter first (releases its internal Mat)
        if (converter != null) {
            try { converter.close(); } catch (Exception e) { /* ignore */ }
        }
        if (fgMask    != null) fgMask.close();
        if (kernel    != null) kernel.close();
        if (resized   != null) resized.close();
        if (gray      != null) gray.close();
        if (laplacian != null) laplacian.close();
        if (meanMat   != null) meanMat.close();
        if (stdMat    != null) stdMat.close();
    }
}
