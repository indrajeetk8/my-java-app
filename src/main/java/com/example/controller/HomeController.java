package com.example.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Home controller for the web application.
 * This class is designed for extension and provides web endpoints.
 */
@Controller
public class HomeController {

    /**
     * Home page endpoint.
     * @param model the model to add attributes to
     * @return the view name
     */
    @GetMapping("/home")
    public String home(final Model model) {
        model.addAttribute("title", "My Java Web App");
        model.addAttribute("message", "Welcome to My Java Spring Boot Application!");
        model.addAttribute("timestamp", LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        model.addAttribute("version", "2.0.0");
        return "index";
    }

    /**
     * Web Status API endpoint.
     * @return JSON status response
     */
    @GetMapping("/api/web-status")
    @ResponseBody
    public String status() {
        final String timestamp = LocalDateTime.now()
                .format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        
        return "{\n"
                + "  \"status\": \"running\",\n"
                + "  \"application\": \"my-java-app\",\n"
                + "  \"version\": \"2.0.0\",\n"
                + "  \"timestamp\": \"" + timestamp + "\",\n"
                + "  \"deployed_to\": \"Nexus Repository\"\n"
                + "}";
    }

    /**
     * Hello API endpoint.
     * @return greeting message
     */
    @GetMapping("/api/hello")
    @ResponseBody
    public String hello() {
        return "Hello, CI/CD World! This is a Spring Boot Web Application.";
    }

    /**
     * Health check endpoint.
     * @return health status
     */
    @GetMapping("/health")
    @ResponseBody
    public String health() {
        return "UP";
    }
}
