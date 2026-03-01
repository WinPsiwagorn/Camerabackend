package com.camerastatus.scheduler;

import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.URI;
import java.util.concurrent.CompletableFuture;

import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

@Component
public class CameraStatusChecker {

    private static final int TIMEOUT_MS = 4_000;

    /**
     * Lightweight TCP reachability check against the RTSP host:port.
     * Falls back to port 554 if the URL has no explicit port.
     * Far cheaper than spawning FFmpegFrameGrabber.
     */
    public boolean isCameraOnline(String rtspUrl) {
        try {
            URI uri = new URI(rtspUrl.trim());
            String host = uri.getHost();
            int port = uri.getPort() > 0 ? uri.getPort() : 554;

            if (host == null || host.isBlank()) return false;

            try (Socket socket = new Socket()) {
                socket.connect(new InetSocketAddress(host, port), TIMEOUT_MS);
                return true;
            }
        } catch (Exception e) {
            return false;
        }
    }

    @Async("cameraTaskExecutor")
    public CompletableFuture<Boolean> isCameraOnlineAsync(String url) {
        return CompletableFuture.completedFuture(isCameraOnline(url));
    }
}
