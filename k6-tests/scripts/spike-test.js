import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate } from 'k6/metrics';

// Custom metrics
const errorCounter = new Counter('errors');
const errorRate = new Rate('error_rate');

// Spike test configuration - sudden increases in load
export let options = {
  stages: [
    { duration: '1m', target: 5 },    // Start with 5 users
    { duration: '30s', target: 100 }, // Sudden spike to 100 users
    { duration: '2m', target: 100 },  // Stay at 100 users
    { duration: '30s', target: 5 },   // Drop back to 5 users
    { duration: '1m', target: 5 },    // Stay at 5 users
    { duration: '30s', target: 150 }, // Another spike to 150 users
    { duration: '2m', target: 150 },  // Stay at 150 users
    { duration: '1m', target: 0 },    // Ramp down to 0
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95% of requests must be below 2s (very lenient for spike test)
    http_req_failed: ['rate<0.3'],     // Error rate must be below 30%
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export function setup() {
  console.log(`Starting spike test against: ${BASE_URL}`);
  
  // Verify the application is ready
  let response = http.get(`${BASE_URL}/actuator/health`);
  if (response.status !== 200) {
    throw new Error(`Application is not healthy. Status: ${response.status}`);
  }
  
  return { baseUrl: BASE_URL };
}

export default function (data) {
  // Test critical endpoints during spike
  
  // Health check
  let response = http.get(`${data.baseUrl}/actuator/health`);
  let success = check(response, {
    'Health endpoint handles spike': (r) => [200, 503].includes(r.status),
  });
  
  if (!success) {
    errorCounter.add(1);
    errorRate.add(true);
  } else {
    errorRate.add(false);
  }
  
  // Main endpoint
  response = http.get(`${data.baseUrl}/`);
  success = check(response, {
    'Main endpoint handles spike': (r) => [200, 503, 504].includes(r.status), // Allow timeouts
  });
  
  if (!success) {
    errorCounter.add(1);
    errorRate.add(true);
  } else {
    errorRate.add(false);
  }
  
  // Very short sleep to create more pressure
  sleep(0.3);
}

export function teardown(data) {
  console.log('Spike test completed');
  console.log(`Application resilience tested against sudden load spikes at: ${data.baseUrl}`);
}
