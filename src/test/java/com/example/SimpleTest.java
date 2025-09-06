package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Simple unit tests that don't require Spring Boot context
 */
public class SimpleTest {

    @Test
    void testBasicAssertion() {
        assertTrue(true, "Basic assertion test");
    }
    
    @Test
    void testStringOperation() {
        String result = "Hello World";
        assertEquals("Hello World", result);
        assertNotNull(result);
    }
    
    @Test
    void testMathOperation() {
        int sum = 2 + 2;
        assertEquals(4, sum, "2 + 2 should equal 4");
    }
}
