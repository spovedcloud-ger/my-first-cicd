# my-first-cicd Helm Chart

A Helm chart for deploying the my-first-cicd Node.js application to Kubernetes.

## TL;DR

```bash
helm repo add my-first-cicd https://spovedcloud-ger.github.io/my-first-cicd
helm install my-first-cicd my-first-cicd/my-first-cicd
```

## Introduction

This chart deploys a Node.js Express application with the following features:
- PostgreSQL database connection
- Redis caching
- Prometheus metrics
- Health check endpoints
- Horizontal pod autoscaling
- Network policies for security

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- Ingress controller (nginx-ingress) for ingress support
- cert-manager for TLS certificates

## Installing the Chart

To install the chart with the release name `my-first-cicd`:

```bash
helm install my-first-cicd ./k8s/helm/my-first-cicd
```

## Uninstalling the Chart

To uninstall the chart:

```bash
helm uninstall my-first-cicd
```

## Configuration

The following table lists the configurable parameters of the my-first-cicd chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `image.repository` | Image repository | `ghcr.io/spovedcloud-ger/my-first-cicd` |
| `image.tag` | Image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `Always` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container port | `3000` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class | `nginx` |
| `ingress.hosts` | Ingress hosts | `my-first-cicd.example.com` |
| `ingress.tls` | TLS configuration | `[]` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `256Mi` |
| `autoscaling.enabled` | Enable HPA | `true` |
| `autoscaling.minReplicas` | Min replicas | `2` |
| `autoscaling.maxReplicas` | Max replicas | `10` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU | `70` |
| `config.NODE_ENV` | Node environment | `production` |
| `config.PORT` | App port | `3000` |
| `config.DB_HOST` | Database host | `my-first-cicd-postgres` |
| `config.REDIS_HOST` | Redis host | `my-first-cicd-redis` |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example:

```bash
helm install my-first-cicd ./k8s/helm/my-first-cicd \
  --set replicaCount=3 \
  --set image.tag=v1.0.0
```

Alternatively, a YAML file that specifies the values for the parameters can be provided:

```bash
helm install my-first-cicd ./k8s/helm/my-first-cicd -f values.yaml
```

## Environment-Specific Values

The chart includes environment-specific values files:

- `values-dev.yaml` - Development environment
- `values-staging.yaml` - Staging environment
- `values-prod.yaml` - Production environment

To use environment-specific values:

```bash
helm install my-first-cicd ./k8s/helm/my-first-cicd -f values-prod.yaml
```

## Values Files Structure

### Development (values-dev.yaml)
- Single replica
- NodePort service for local access
- Ingress disabled
- Lower resource limits

### Staging (values-staging.yaml)
- 2 replicas
- ClusterIP service
- Ingress enabled with staging TLS
- Medium resource limits

### Production (values-prod.yaml)
- 3+ replicas
- LoadBalancer service
- Ingress enabled with production TLS
- Higher resource limits
- Autoscaling enabled
- Network policies enabled

## Exposed Endpoints

| Endpoint | Description |
|----------|-------------|
| `/api/health` | Health check endpoint |
| `/api/users` | User CRUD operations |
| `/metrics` | Prometheus metrics |

## Network Policies

The chart includes network policies that:
- Allow traffic from ingress controller
- Allow traffic from monitoring namespace
- Allow DNS resolution
- Allow traffic to PostgreSQL (port 5432)
- Allow traffic to Redis (port 6379)

## Security Considerations

- Container runs as non-root user (UID 1001)
- Read-only root filesystem
- No privilege escalation
- Security capabilities dropped
- Network policies restrict egress traffic

## Troubleshooting

### Check pod status
```bash
kubectl get pods -l app.kubernetes.io/name=my-first-cicd
```

### View logs
```bash
kubectl logs -f deployment/my-first-cicd
```

### Check service
```bash
kubectl get svc my-first-cicd
```

### Check ingress
```bash
kubectl get ingress my-first-cicd
```

### Port forward for local testing
```bash
kubectl port-forward svc/my-first-cicd 3000:80
```

## License

Copyright (c) 2024 spovedcloud-ger

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.