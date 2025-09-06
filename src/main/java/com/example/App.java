package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public final class App {
    
    private App() {
        // Private constructor to prevent instantiation
    }
    
    public static void main(final String[] args) {
        System.out.println("Starting My Java Web App...");
        SpringApplication.run(App.class, args);
    }
}
