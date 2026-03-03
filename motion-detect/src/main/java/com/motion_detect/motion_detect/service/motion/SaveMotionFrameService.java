package com.motion_detect.motion_detect.service.motion;

import com.motion_detect.motion_detect.model.dto.MotionEvent;
import com.motion_detect.motion_detect.firestore.FirebaseAdminBootstrap;
import com.motion_detect.motion_detect.service.kafka.MotionEventProducer;

import com.google.cloud.storage.Bucket;
import com.google.cloud.storage.Blob;
import com.google.firebase.cloud.StorageClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.bytedeco.javacv.Frame;
import org.bytedeco.javacv.Java2DFrameConverter;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;

@Slf4j
@Service
@RequiredArgsConstructor
public class SaveMotionFrameService {

    private final FirebaseAdminBootstrap bootstrap;
    private final MotionEventProducer motionEventProducer;

    /**
     * Deep copy a frame to BufferedImage.
     * Creates and immediately closes a converter to avoid native memory leak.
     */
    private BufferedImage deepCopyFrameToImage(Frame frame) {
        if (frame == null || frame.image == null) {
            return null;
        }
        
        Java2DFrameConverter converter = new Java2DFrameConverter();
        try {
            BufferedImage original = converter.convert(frame);
            if (original == null) {
                return null;
            }
            
            BufferedImage copy = new BufferedImage(
                original.getWidth(), 
                original.getHeight(), 
                BufferedImage.TYPE_3BYTE_BGR
            );
            
            java.awt.Graphics g = copy.getGraphics();
            try {
                g.drawImage(original, 0, 0, null);
            } finally {
                g.dispose();
            }
            
            return copy;
        } finally {
            try { converter.close(); } catch (Exception e) { /* ignore */ }
        }
    }

    /**
     * Upload a Frame to Firebase Storage
     */
    public void uploadMotionFrame(Frame frame, String cameraId) {
        if (!bootstrap.isInitialized()) return;

        try {
            BufferedImage image = deepCopyFrameToImage(frame);
            if (image == null) return;
            uploadBufferedImage(image, cameraId);
        } catch (Exception e) {
            throw new RuntimeException("Upload frame to Firebase Storage failed", e);
        }
    }

    /**
     * Upload a BufferedImage directly to Firebase Storage
     * Used when we've already selected the best frame
     */
    public void uploadMotionFrame(BufferedImage image, String cameraId) {
        if (!bootstrap.isInitialized()) return;
        if (image == null) return;

        try {
            uploadBufferedImage(image, cameraId);
        } catch (Exception e) {
            throw new RuntimeException("Upload BufferedImage to Firebase Storage failed", e);
        }
    }

    /**
     * Common upload logic for BufferedImage.
     * After a successful upload, fires a MotionEvent to Kafka so downstream
     * consumers (accident-ai, license-plate, etc.) are notified automatically.
     */
    private void uploadBufferedImage(BufferedImage image, String cameraId) throws Exception {
        byte[] bytes;
        try (ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            ImageIO.write(image, "jpg", baos);
            bytes = baos.toByteArray();
        }

        String path = "motion/" + cameraId + "/" + System.currentTimeMillis() + ".jpg";

        Bucket bucket = StorageClient.getInstance().bucket();
        Blob blob = bucket.create(path, bytes, "image/jpeg");

        String url = "https://storage.googleapis.com/"
                + bucket.getName() + "/"
                + blob.getName();

        log.info("Motion frame uploaded for camera {}", cameraId);

        motionEventProducer.send(MotionEvent.builder()
                .cameraId(cameraId)
                .timestamp(System.currentTimeMillis())
                .imageUrl(url)
                .build());
        
        log.info("Kafka event sent for camera {}", cameraId);
    }
}
