package com.backendcam.backendcam.service.motion;

import org.bytedeco.javacpp.indexer.DoubleIndexer;
import org.bytedeco.javacv.Frame;
import org.bytedeco.javacv.OpenCVFrameConverter;
import org.bytedeco.opencv.opencv_core.*;
import org.bytedeco.opencv.opencv_video.BackgroundSubtractorMOG2;

import static org.bytedeco.opencv.global.opencv_core.*;
import static org.bytedeco.opencv.global.opencv_imgproc.*;
import static org.bytedeco.opencv.global.opencv_video.createBackgroundSubtractorMOG2;

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
    }

    /**
     * Convert Frame to Mat once — call this in the orchestrator and pass the
     * result to both detectMotion() and calculateSharpness() to avoid
     * converting the same frame twice.
     */
    public Mat convertFrame(Frame frame) {
        return converter.convert(frame);
    }

    /**
     * Detect motion using the pre-allocated, downscaled pipeline.
     * Accepts a Mat so the caller can reuse a single conversion.
     */
    public boolean detectMotion(Mat mat) {
        if (mat == null) return false;

        // Downscale to detection resolution before running MOG2
        Mat input = mat;
        if (needsResize) {
            resize(mat, resized, new Size(detectionWidth, detectionHeight));
            input = resized;
        }

        mog2.apply(input, fgMask);
        morphologyEx(fgMask, fgMask, MORPH_OPEN, kernel);

        int motionPixels = countNonZero(fgMask);
        int totalPixels  = fgMask.rows() * fgMask.cols();

        return (double) motionPixels / totalPixels > 0.02; // 2%
    }

    /**
     * Calculate Laplacian sharpness using pre-allocated Mats.
     * Uses the already-downscaled Mat to avoid redundant resizing.
     */
    public double calculateSharpness(Mat mat) {
        if (mat == null) return 0;

        // Reuse the already-resized buffer if downscaling was applied
        Mat src = needsResize ? resized : mat;

        cvtColor(src, gray, COLOR_BGR2GRAY);
        Laplacian(gray, laplacian, CV_64F);

        // meanStdDev requires Mat outputs in this JavaCV binding, not Scalar
        meanStdDev(laplacian, meanMat, stdMat);

        // stdMat is a 1×1 CV_64F Mat — read the single double via DoubleIndexer
        DoubleIndexer idx = stdMat.createIndexer();
        double sigmaVal = idx.get(0);
        idx.close();
        return sigmaVal * sigmaVal;
    }

    public void cleanup() {
        if (fgMask    != null) fgMask.close();
        if (kernel    != null) kernel.close();
        if (resized   != null) resized.close();
        if (gray      != null) gray.close();
        if (laplacian != null) laplacian.close();
        if (meanMat   != null) meanMat.close();
        if (stdMat    != null) stdMat.close();
    }
}