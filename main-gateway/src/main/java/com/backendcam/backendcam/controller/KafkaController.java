package com.backendcam.backendcam.controller;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.backendcam.backendcam.model.dto.MotionEvent;
import com.backendcam.backendcam.service.kafka.MotionEventProducer;

import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/kafka")
public class KafkaController {
	
	private final MotionEventProducer motionEventProducer;

	@PostMapping("/sendMotionEvent")
	public String sendMotionEvent(@RequestBody MotionEvent dto) {

		MotionEvent motionEvent = MotionEvent.builder()
				.cameraId(dto.getCameraId())
				.timestamp(System.currentTimeMillis())
				.imageUrl(dto.getImageUrl())
				.build();

		motionEventProducer.send(motionEvent);
		return "Motion event sent to Kafka topic.";
	}
}