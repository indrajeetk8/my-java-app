package com.example.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.HashMap;
import java.util.Map;

@RestController
public class HealthController {

    @GetMapping("/")
    public ResponseEntity<Map<String, String>> home() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Welcome to My Java App!");
        response.put("status", "running");
        response.put("version", "2.0.0");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/api/status")
    public ResponseEntity<Map<String, Object>> status() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "healthy");
        response.put("timestamp", System.currentTimeMillis());
        response.put("uptime", "running");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/api/users")
    public ResponseEntity<Map<String, Object>> users() {
        Map<String, Object> response = new HashMap<>();
        response.put("users", new String[]{"user1", "user2", "user3"});
        response.put("count", 3);
        return ResponseEntity.ok(response);
    }
}
