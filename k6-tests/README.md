# k6 Performance Testing Integration

This directory contains k6 performance tests integrated into the CI/CD pipeline for comprehensive performance testing of the Java application.

## Overview

The k6 integration provides automated performance testing at different stages of the deployment pipeline:

- **Development**: Basic load testing to catch performance regressions early
- **Staging**: Comprehensive testing including load, stress, and spike tests
- **Production**: Smoke tests to verify deployment success without impacting users

## Directory Structure

```
k6-tests/
├── scripts/           # k6 test scripts
│   ├── load-test.js   # Standard load testing
│   ├── stress-test.js # Stress testing (finding limits)
│   ├── spike-test.js  # Spike testing (sudden load increases)
├── configs/           # Environment-specific configurations
│   ├── dev.json       # Development environment config
│   ├── staging.json   # Staging environment config
│   └── production.json # Production environment config
├── results/           # Test result outputs (JSON format)
├── reports/           # Processed reports (JUnit XML, HTML)
├── run-k6-tests.ps1   # PowerShell script to run tests
└── process-results.ps1 # Script to process results and generate reports
```

## Test Types

### 1. Load Testing (`load-test.js`)
- **Purpose**: Verify application performance under expected load
- **Load Pattern**: Gradual ramp-up to target users, steady state, ramp-down
- **Thresholds**: 
  - 95% of requests < 500ms
  - Error rate < 10%
  - Total errors < 10

### 2. Stress Testing (`stress-test.js`)
- **Purpose**: Find the breaking point of the application
- **Load Pattern**: Gradual increase beyond normal capacity
- **Thresholds**: 
  - 95% of requests < 1000ms (more lenient)
  - Error rate < 20%
  - Total errors < 50

### 3. Spike Testing (`spike-test.js`)
- **Purpose**: Test application resilience to sudden load spikes
- **Load Pattern**: Sudden increases and decreases in load
- **Thresholds**: 
  - 95% of requests < 2000ms (very lenient)
  - Error rate < 30%

### 4. Smoke Testing (`smoke-test.js`)
- **Purpose**: Verify basic functionality with minimal load
- **Load Pattern**: Single user for basic verification
- **Thresholds**: 
  - 95% of requests < 300ms
  - Error rate < 5%
  - Total errors < 3

## Usage

### Manual Test Execution

#### Using PowerShell Script (Recommended)
```powershell
# Run load test against development environment
.\run-k6-tests.ps1 -TestType load -Environment dev

# Run stress test against staging
.\run-k6-tests.ps1 -TestType stress -Environment staging -Verbose

# Run smoke test against production
.\run-k6-tests.ps1 -TestType smoke -Environment production
```

#### Using Docker Directly
```bash
# Run load test with Docker
docker run --rm \
  -v "${PWD}/scripts:/scripts" \
  -v "${PWD}/results:/results" \
  -e BASE_URL=http://localhost:8080 \
  grafana/k6:latest run \
  --out json=/results/results.json \
  /scripts/load-test.js

# Run smoke test with Docker  
docker run --rm \
  -v "${PWD}/scripts:/scripts" \
  -e BASE_URL=http://localhost:8080 \
  grafana/k6:latest run /scripts/smoke-test.js

# Run stress test with Docker
docker run --rm \
  -v "${PWD}/scripts:/scripts" \
  -e BASE_URL=http://localhost:8080 \
  grafana/k6:latest run /scripts/stress-test.js
```

#### Using k6 Directly (if installed)
```bash
# Set environment variable and run load test
export BASE_URL="http://localhost:8080"
k6 run --out json=results/results.json scripts/load-test.js

# Run different test types
k6 run scripts/smoke-test.js
k6 run scripts/stress-test.js
k6 run scripts/spike-test.js
```

### CI/CD Pipeline Integration

The tests are automatically integrated into the Jenkins pipeline:

1. **Development Branch (`develop`)**:
   - Runs load tests after deployment
   - Results archived and published

2. **Main Branch (`main`)**:
   - Runs comprehensive performance tests on staging
   - Includes load, stress, and spike tests
   - Blocks pipeline on failure

3. **Production Deployment**:
   - Runs smoke tests before and optionally after deployment
   - Minimal impact on production environment

## Configuration

### Environment Configuration Files

Each environment has its own configuration file in the `configs/` directory:

- `dev.json`: Lightweight tests for development
- `staging.json`: Comprehensive tests with higher thresholds
- `production.json`: Minimal smoke tests only

### Customizing Tests

To customize tests for your specific application:

1. **Update Base URLs**: Modify the configuration files with your actual endpoints
2. **Adjust Test Scenarios**: Update the test scripts to target your specific API endpoints
3. **Modify Thresholds**: Adjust performance thresholds based on your requirements
4. **Add Custom Metrics**: Extend the test scripts with application-specific metrics

### Example: Adding Custom Endpoint Testing

```javascript
// In your test script, add:
function testCustomEndpoint(baseUrl) {
  let response = http.get(`${baseUrl}/api/your-endpoint`);
  check(response, {
    'Custom endpoint status is 200': (r) => r.status === 200,
    'Custom endpoint response time < 300ms': (r) => r.timings.duration < 300,
  });
}
```

## Results and Reporting

### Result Processing

The `process-results.ps1` script processes raw k6 JSON output and generates:

- **JUnit XML**: For Jenkins test result integration
- **JSON Summary**: For programmatic analysis
- **HTML Reports**: For human-readable reports (optional)

### Jenkins Integration

Results are automatically:
- Published as test results in Jenkins
- Archived as build artifacts
- Used to determine build success/failure
- Included in notifications

### Interpreting Results

Key metrics to monitor:

- **Success Rate**: Percentage of successful requests
- **Response Times**: Average, P95, P99 response times
- **Error Rate**: Percentage of failed requests
- **Checks**: Pass/fail status of custom validation checks

## Troubleshooting

### Common Issues

1. **Application Not Running**
   ```
   Error: Application is not healthy. Status: 500
   ```
   - Ensure your application is running and accessible
   - Check the health endpoint: `/actuator/health`

2. **Docker Not Available**
   ```
   Error: docker command not found
   ```
   - Install Docker Desktop for Windows
   - Ensure Docker daemon is running

3. **PowerShell Execution Policy**
   ```
   Error: Execution policy restriction
   ```
   - Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

4. **High Error Rates**
   - Check application logs for errors
   - Verify database connectivity
   - Monitor system resources (CPU, memory)

### Performance Tuning Tips

1. **Database Optimization**
   - Monitor database query performance
   - Add appropriate indexes
   - Optimize slow queries

2. **JVM Tuning**
   - Adjust heap size: `-Xmx1024m`
   - Tune garbage collection
   - Monitor memory usage

3. **Application Configuration**
   - Optimize connection pools
   - Configure caching appropriately
   - Review timeout settings

## Best Practices

### Test Design
- Start with smoke tests, then gradually increase load
- Test realistic user scenarios
- Include both positive and negative test cases
- Monitor infrastructure during tests

### Thresholds
- Set realistic performance thresholds based on business requirements
- Use percentiles (P95, P99) rather than averages
- Consider different thresholds for different environments

### CI/CD Integration
- Run lightweight tests frequently (every commit)
- Run comprehensive tests on staging
- Use smoke tests for production verification
- Fail fast on performance regressions

### Monitoring
- Monitor both application and infrastructure metrics
- Set up alerts for performance degradation
- Track performance trends over time
- Correlate performance with business metrics

## Resources

- [k6 Documentation](https://k6.io/docs/)
- [Jenkins Performance Plugin](https://plugins.jenkins.io/performance/)
- [Grafana k6 Dashboard](https://grafana.com/grafana/dashboards/2587)
- [k6 Examples](https://github.com/grafana/k6/tree/master/examples)

## Support

For issues related to:
- **k6 Tests**: Check logs in Jenkins and k6 output
- **Jenkins Integration**: Review Jenkins console output
- **Application Performance**: Check application logs and metrics
- **Infrastructure**: Monitor system resources and network
