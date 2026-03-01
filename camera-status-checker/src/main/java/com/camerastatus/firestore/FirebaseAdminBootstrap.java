package com.camerastatus.firestore;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

@Configuration
public class FirebaseAdminBootstrap {

    private static final Logger log = LoggerFactory.getLogger(FirebaseAdminBootstrap.class);
    private volatile boolean initialized = false;

    @Autowired
    private ResourceLoader resourceLoader;

    @Value("${firebase.credentials.path:}")
    private String saPath;

    @Value("${firebase.storage.bucket:}")
    private String storageBucket;

    @PostConstruct
    public void init() {
        try {
            if (!FirebaseApp.getApps().isEmpty()) {
                initialized = true;
                return;
            }

            List<String> tried = new ArrayList<>();
            Resource resource = null;

            if (saPath != null && !saPath.isBlank()) {
                tried.add(saPath);
                resource = resourceLoader.getResource(saPath);
            }

            if (resource == null || !resource.exists()) {
                String env = System.getenv("GOOGLE_APPLICATION_CREDENTIALS");
                if (env != null && !env.isBlank()) {
                    String envRef = env.startsWith("file:") ? env : "file:" + env;
                    tried.add(envRef);
                    resource = resourceLoader.getResource(envRef);
                }
            }

            if (resource == null || !resource.exists()) {
                String fallback = "file:/secrets/serviceAccount.json";
                tried.add(fallback);
                resource = resourceLoader.getResource(fallback);
            }

            if (resource == null || !resource.exists()) {
                log.warn("Firebase NOT initialized. Tried: {}. Firestore features will be disabled.", tried);
                return;
            }

            try (InputStream in = resource.getInputStream()) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(in))
                        .setStorageBucket(storageBucket)
                        .build();
                FirebaseApp.initializeApp(options);
                initialized = true;
                log.info("Firebase Admin SDK initialized successfully.");
            }
        } catch (Exception e) {
            log.warn("Firebase init failed: {}", e.getMessage());
        }
    }

    public boolean isInitialized() {
        boolean ok = initialized || !FirebaseApp.getApps().isEmpty();
        if (!ok) log.warn("Firestore is NOT initialized. Skipping operation.");
        return ok;
    }
}
