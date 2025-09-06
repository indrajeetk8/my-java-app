import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate } from 'k6/metrics';

// Custom metrics
const errorCounter = new Counter('errors');
const errorRate = new Rate('error_rate');

// Smoke test configuration - minimal load to verify basic functionality
export let options = {
  stages: [
    { duration: '30s', target: 1 },  // Single user for 30 seconds
    { duration: '1m', target: 1 },   // Continue with single user
    { duration: '30s', target: 0 },  // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<300'],   // 95% of requests must be below 300ms
    http_req_failed: ['rate<0.05'],     // Error rate must be below 5%
    errors: ['count<3'],                // Total errors must be below 3
  },
};

const BASE_URL = __ENV.BASE_URL || 'https://prod.myapp.com';

export function setup() {
  console.log(`Starting smoke test against: ${BASE_URL}`);
  return { baseUrl: BASE_URL };
}

export default function (data) {
  // Smoke test focuses on critical path verification
  
  // 1. Health Check - Most critical endpoint
  let response = http.get(`${data.baseUrl}/actuator/health`);
  let success = check(response, {
    'Health endpoint is accessible': (r) => r.status === 200,
    'Health endpoint responds quickly': (r) => r.timings.duration < 200,
  });
  
  if (!success) {
    errorCounter.add(1);
    errorRate.add(true);
  } else {
    errorRate.add(false);
  }
  
  // 2. Main Application Endpoint
  response = http.get(`${data.baseUrl}/`);
  success = check(response, {
    'Main page loads': (r) => r.status === 200,
    'Main page loads quickly': (r) => r.timings.duration < 500,
  });
  
  if (!success) {
    errorCounter.add(1);
    errorRate.add(true);
  } else {
    errorRate.add(false);
  }
  
  // 3. Application Info (if available)
  response = http.get(`${data.baseUrl}/actuator/info`);
  success = check(response, {
    'Info endpoint responds': (r) => [200, 404].includes(r.status), // 404 is acceptable
    'Info endpoint timing': (r) => r.timings.duration < 300,
  });
  
  if (!success && response.status !== 404) {
    errorCounter.add(1);
    errorRate.add(true);
  } else {
    errorRate.add(false);
  }
  
  // 4. Basic API endpoint check (adjust based on your application)
  response = http.get(`${data.baseUrl}/api/status`, {
    headers: {
      'Accept': 'application/json',
      'User-Agent': 'k6-smoke-test/1.0',
    },
  });
  
  success = check(response, {
    'API status endpoint': (r) => [200, 404].includes(r.status), // 404 is acceptable if endpoint doesn't exist
    'API response time': (r) => r.timings.duration < 400,
  });
  
  if (!success && response.status !== 404) {
    errorCounter.add(1);
    errorRate.add(true);
  } else {
    errorRate.add(false);
  }
  
  // Longer sleep for smoke test to reduce load
  sleep(2);
}

export function teardown(data) {
  console.log('Smoke test completed');
  console.log(`Basic functionality verified for: ${data.baseUrl}`);
}
