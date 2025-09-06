import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate } from 'k6/metrics';

// Custom metrics
const errorCounter = new Counter('errors');
const errorRate = new Rate('error_rate');

// Stress test configuration - gradually increase load to find breaking point
export let options = {
  stages: [
    { duration: '2m', target: 10 },   // Ramp up to 10 users
    { duration: '5m', target: 10 },   // Stay at 10 users
    { duration: '2m', target: 20 },   // Ramp up to 20 users
    { duration: '5m', target: 20 },   // Stay at 20 users
    { duration: '2m', target: 50 },   // Ramp up to 50 users
    { duration: '5m', target: 50 },   // Stay at 50 users
    { duration: '2m', target: 100 },  // Ramp up to 100 users
    { duration: '5m', target: 100 },  // Stay at 100 users
    { duration: '5m', target: 0 },    // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<1000'], // 95% of requests must be below 1s (more lenient for stress test)
    http_req_failed: ['rate<0.2'],     // Error rate must be below 20%
    errors: ['count<50'],              // Total errors must be below 50
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export function setup() {
  console.log(`Starting stress test against: ${BASE_URL}`);
  
  // Verify the application is ready
  let response = http.get(`${BASE_URL}/actuator/health`);
  if (response.status !== 200) {
    throw new Error(`Application is not healthy. Status: ${response.status}`);
  }
  
  return { baseUrl: BASE_URL };
}

export default function (data) {
  // Focus on the most critical endpoints under stress
  
  // Health check
  let response = http.get(`${data.baseUrl}/actuator/health`);
  let success = check(response, {
    'Health endpoint survives stress': (r) => r.status === 200,
  });
  
  if (!success) {
    errorCounter.add(1);
    errorRate.add(true);
  } else {
    errorRate.add(false);
  }
  
  // Main application endpoint
  response = http.get(`${data.baseUrl}/`);
  success = check(response, {
    'Main endpoint survives stress': (r) => [200, 503].includes(r.status), // 503 is acceptable under stress
  });
  
  if (!success) {
    errorCounter.add(1);
    errorRate.add(true);
  } else {
    errorRate.add(false);
  }
  
  // Shorter sleep for stress test
  sleep(0.5);
}

export function teardown(data) {
  console.log('Stress test completed');
  console.log(`Maximum load tested against: ${data.baseUrl}`);
}
