package com.example.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Controller
public class HomeController {

    @GetMapping("/")
    public String home(Model model) {
        model.addAttribute("title", "My Java Web App");
        model.addAttribute("message", "Welcome to My Java Spring Boot Application!");
        model.addAttribute("timestamp", LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        model.addAttribute("version", "2.0.0");
        return "index";
    }

    @GetMapping("/api/status")
    @ResponseBody
    public String status() {
        return "{\n" +
                "  \"status\": \"running\",\n" +
                "  \"application\": \"my-java-app\",\n" +
                "  \"version\": \"2.0.0\",\n" +
                "  \"timestamp\": \"" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")) + "\",\n" +
                "  \"deployed_to\": \"Nexus Repository\"\n" +
                "}";
    }

    @GetMapping("/api/hello")
    @ResponseBody
    public String hello() {
        return "Hello, CI/CD World! This is a Spring Boot Web Application.";
    }

    @GetMapping("/health")
    @ResponseBody
    public String health() {
        return "UP";
    }
}
