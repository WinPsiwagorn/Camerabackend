package com.motion_detect.motion_detect.service.motion;

/**
 * Represents an active motion detection session for a camera
 */
class DetectionSession {
    private final String cameraId;
    private final String rtspUrl;
    private volatile boolean running = true;

    public DetectionSession(String cameraId, String rtspUrl) {
        this.cameraId = cameraId;
        this.rtspUrl = rtspUrl;
    }

    public String getCameraId() {
        return cameraId;
    }

    public String getRtspUrl() {
        return rtspUrl;
    }

    public boolean isRunning() {
        return running;
    }

    public void stop() {
        running = false;
    }
}
