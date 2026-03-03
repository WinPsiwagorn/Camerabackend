package com.motion_detect.motion_detect.service.kafka;

import com.motion_detect.motion_detect.model.dto.MotionEvent;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class MotionEventProducer {

    private static final String TOPIC = "motion-event";

    private final KafkaTemplate<String, Object> kafkaTemplate;

    public MotionEventProducer(KafkaTemplate<String, Object> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public void send(MotionEvent event) {
        kafkaTemplate.send(
                TOPIC,
                event.getCameraId(), // key (partition by camera)
                event
        );
    }
}
