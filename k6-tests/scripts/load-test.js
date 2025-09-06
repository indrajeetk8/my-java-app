import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorCounter = new Counter('errors');
const errorRate = new Rate('error_rate');
const responseTimeTrend = new Trend('response_time');

// Test configuration - can be overridden by environment variables
export let options = {
  stages: [
    { duration: '2m', target: 10 }, // Ramp up to 10 users
    { duration: '5m', target: 10 }, // Stay at 10 users
    { duration: '2m', target: 20 }, // Ramp up to 20 users
    { duration: '5m', target: 20 }, // Stay at 20 users
    { duration: '2m', target: 0 },  // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests must be below 500ms
    http_req_failed: ['rate<0.1'],    // Error rate must be below 10%
    errors: ['count<10'],             // Total errors must be below 10
  },
  ext: {
    loadimpact: {
      distribution: {
        'amazon:us:ashburn': { loadZone: 'amazon:us:ashburn', percent: 100 },
      },
    },
  },
};

// Environment configuration
const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';
const TEST_DURATION = __ENV.TEST_DURATION || '10m';

// Test data
const testUsers = [
  { username: 'testuser1', email: 'test1@example.com' },
  { username: 'testuser2', email: 'test2@example.com' },
  { username: 'testuser3', email: 'test3@example.com' },
];

export function setup() {
  console.log(`Starting load test against: ${BASE_URL}`);
  
  // Verify the application is ready
  let response = http.get(`${BASE_URL}/actuator/health`);
  if (response.status !== 200) {
    throw new Error(`Application is not healthy. Status: ${response.status}`);
  }
  
  console.log('Application health check passed');
  return { baseUrl: BASE_URL };
}

export default function (data) {
  // Test 1: Health Check Endpoint
  testHealthEndpoint(data.baseUrl);
  
  // Test 2: API Endpoints (adjust based on your actual endpoints)
  testAPIEndpoints(data.baseUrl);
  
  // Test 3: User Operations (if you have user management)
  testUserOperations(data.baseUrl);
  
  sleep(1); // Wait between iterations
}

function testHealthEndpoint(baseUrl) {
  let response = http.get(`${baseUrl}/actuator/health`);
  
  let success = check(response, {
    'Health check status is 200': (r) => r.status === 200,
    'Health check response time < 200ms': (r) => r.timings.duration < 200,
  });
  
  if (!success) {
    errorCounter.add(1);
    errorRate.add(true);
  } else {
    errorRate.add(false);
  }
  
  responseTimeTrend.add(response.timings.duration);
}

function testAPIEndpoints(baseUrl) {
  // Test main application endpoint
  let response = http.get(`${baseUrl}/`);
  
  let success = check(response, {
    'Main endpoint status is 200': (r) => r.status === 200,
    'Main endpoint response time < 500ms': (r) => r.timings.duration < 500,
  });
  
  if (!success) {
    errorCounter.add(1);
    errorRate.add(true);
  } else {
    errorRate.add(false);
  }
  
  responseTimeTrend.add(response.timings.duration);
  
  // Test API info endpoint (common in Spring Boot apps)
  response = http.get(`${baseUrl}/actuator/info`);
  
  success = check(response, {
    'Info endpoint status is 200': (r) => r.status === 200,
    'Info endpoint response time < 300ms': (r) => r.timings.duration < 300,
  });
  
  if (!success) {
    errorCounter.add(1);
    errorRate.add(true);
  } else {
    errorRate.add(false);
  }
  
  responseTimeTrend.add(response.timings.duration);
}

function testUserOperations(baseUrl) {
  // Example: Test user-related endpoints (adjust based on your API)
  const randomUser = testUsers[Math.floor(Math.random() * testUsers.length)];
  
  // Example GET request for users
  let response = http.get(`${baseUrl}/api/users`, {
    headers: {
      'Content-Type': 'application/json',
    },
  });
  
  let success = check(response, {
    'Users endpoint accessible': (r) => [200, 404].includes(r.status), // 404 is OK if endpoint doesn't exist
    'Users endpoint response time < 1s': (r) => r.timings.duration < 1000,
  });
  
  if (!success && response.status !== 404) {
    errorCounter.add(1);
    errorRate.add(true);
  } else {
    errorRate.add(false);
  }
  
  responseTimeTrend.add(response.timings.duration);
}

export function teardown(data) {
  console.log('Load test completed');
  console.log(`Test ran against: ${data.baseUrl}`);
}
