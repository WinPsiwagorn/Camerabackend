package com.motion_detect.motion_detect.service.kafka;

import com.motion_detect.motion_detect.model.dto.MotionEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class MotionEventProducer {

    private static final String TOPIC = "motion-event";
    private final KafkaTemplate<String, Object> kafkaTemplate;

    public void send(MotionEvent event) {
        try {
            CompletableFuture<SendResult<String, Object>> future = kafkaTemplate.send(
                    TOPIC,
                    event.getCameraId(),
                    event
            );
            
            // Wait for send to complete (with timeout to avoid blocking forever)
            future.get(5, TimeUnit.SECONDS);
            
        } catch (Exception e) {
            throw new RuntimeException("Kafka send failed: " + e.getMessage(), e);
        }
    }
}
