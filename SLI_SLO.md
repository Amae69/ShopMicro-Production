# Service Level Indicators (SLIs) and Objectives (SLOs)

This document defines the key performance indicators and targets for the ShopMicro platform.

## 1. Service Level Indicators (SLIs)

### SLI 1: Request Latency
- **Definition**: The time it takes to process a successful request to the `backend` or `ml-service`.
- **Measurement**: Percentage of HTTP requests to `/products` (backend) or `/recommendations` (ml-service) that are completed in less than 200ms.
- **PromQL Template**:
  ```promql
  sum(rate(http_request_duration_seconds_bucket{le="0.2", job=~"backend|ml-service"}[5m])) 
  / 
  sum(rate(http_request_duration_seconds_count{job=~"backend|ml-service"}[5m]))
  ```

### SLI 2: Availability (Success Rate)
- **Definition**: The proportion of successful requests to the total number of valid requests.
- **Measurement**: Total number of HTTP 2xx/3xx responses divided by the total number of HTTP requests.
- **PromQL Template**:
  ```promql
  sum(rate(http_requests_total{status=~"2..|3..", job=~"backend|ml-service"}[5m])) 
  / 
  sum(rate(http_requests_total{job=~"backend|ml-service"}[5m]))
  ```

### SLI 3: Error Rate
- **Definition**: The proportion of internal server errors (5xx) relative to the total number of requests.
- **Measurement**: Total number of HTTP 5xx responses divided by the total number of HTTP requests.
- **PromQL Template**:
  ```promql
  sum(rate(http_requests_total{status=~"5.."}[5m])) 
  / 
  sum(rate(http_requests_total{}[5m]))
  ```

---

## 2. Service Level Objectives (SLOs)

### SLO 1: Availability
- **Target**: 99.5% of requests over a rolling 30-day window should be successful (non-5xx).
- **Rationale**: As an e-commerce platform, availability is critical for user trust and revenue. A 99.5% target allows for approximately 3.6 hours of downtime per month, which balances the need for reliability with the agility of a small team performing frequent deployments.

### SLO 2: Latency
- **Target**: 90% of requests to the backend and ML service should be completed in less than 200ms.
- **Rationale**: Page load speed directly impacts conversion rates. The 200ms threshold ensures a snappy user experience, while the 90th percentile target accounts for occasional cold starts or complex ML recommendation computations without failing the entire objective.
