package com.camerastatus.scheduler;

import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.URI;
import java.util.concurrent.CompletableFuture;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

@Component
public class CameraStatusChecker {

    private static final Logger log = LoggerFactory.getLogger(CameraStatusChecker.class);
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

            if (host == null || host.isBlank()) {
                log.warn("[Checker] Could not parse host from URL: {}", rtspUrl);
                return false;
            }

            log.debug("[Checker] Probing {}:{} (url={})", host, port, rtspUrl);
            try (Socket socket = new Socket()) {
                socket.connect(new InetSocketAddress(host, port), TIMEOUT_MS);
                log.debug("[Checker] ONLINE  {}:{}", host, port);
                return true;
            }
        } catch (Exception e) {
            log.debug("[Checker] OFFLINE - {} | reason: {}", rtspUrl, e.getMessage());
            return false;
        }
    }

    @Async("cameraTaskExecutor")
    public CompletableFuture<Boolean> isCameraOnlineAsync(String url) {
        return CompletableFuture.completedFuture(isCameraOnline(url));
    }
}
