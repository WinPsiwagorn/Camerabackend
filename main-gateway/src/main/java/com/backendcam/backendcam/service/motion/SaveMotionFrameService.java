package com.backendcam.backendcam.service.motion;

import com.backendcam.backendcam.model.dto.motion.MotionEvent;
import com.backendcam.backendcam.service.firestore.FirebaseAdminBootstrap;
import com.backendcam.backendcam.service.kafka.MotionEventProducer;

import com.google.cloud.storage.Bucket;
import com.google.cloud.storage.Blob;
import com.google.firebase.cloud.StorageClient;
import org.bytedeco.javacv.Frame;
import org.bytedeco.javacv.Java2DFrameConverter;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;

@Service
public class SaveMotionFrameService {

    private final FirebaseAdminBootstrap bootstrap;
    private final MotionEventProducer motionEventProducer;

    public SaveMotionFrameService(FirebaseAdminBootstrap bootstrap,
                                  MotionEventProducer motionEventProducer) {
        this.bootstrap = bootstrap;
        this.motionEventProducer = motionEventProducer;
    }

    /**
     * Deep copy a frame to BufferedImage
     * Creates a new converter each time to avoid buffer sharing issues
     */
    private BufferedImage deepCopyFrameToImage(Frame frame) {
        if (frame == null || frame.image == null) {
            return null;
        }
        
        // Create a NEW converter for each conversion to avoid buffer sharing
        Java2DFrameConverter converter = new Java2DFrameConverter();
        BufferedImage original = converter.convert(frame);
        
        if (original == null) {
            return null;
        }
        
        // Create a completely new BufferedImage with copied data
        // Use TYPE_3BYTE_BGR which is well-supported for JPEG encoding
        BufferedImage copy = new BufferedImage(
            original.getWidth(), 
            original.getHeight(), 
            BufferedImage.TYPE_3BYTE_BGR
        );
        
        // CRITICAL: Dispose Graphics to prevent memory leak
        java.awt.Graphics g = copy.getGraphics();
        try {
            g.drawImage(original, 0, 0, null);
        } finally {
            g.dispose();
        }
        
        return copy;
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

        motionEventProducer.send(MotionEvent.builder()
                .cameraId(cameraId)
                .timestamp(System.currentTimeMillis())
                .imageUrl(url)
                .build());
    }
}
