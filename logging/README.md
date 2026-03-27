# EFK Logging Stack (Elasticsearch, Fluent Bit, Kibana)

This directory contains the configurations for the EFK stack.

## Architecture

- **Fluent Bit:** A lightweight log shipper that runs as a DaemonSet to collect logs from Kubernetes nodes, parses them, and forwards them to Elasticsearch.
- **Elasticsearch:** A search engine and NoSQL datastore for your logs.
- **Kibana:** A dashboard and visualization UI for searching the logs stored in Elasticsearch.

## Local Development (Docker Compose)

To spin up the EFK stack without Kubernetes, use docker-compose:
```bash
docker-compose -f docker-compose.logging.yml up -d
```
Access Kibana at `http://localhost:5601`. No authentication is required for local dev.

## Kubernetes GitOps (ArgoCD)

The EFK stack is automatically synchronized via ArgoCD from `k8s/logging/`.

Access Kibana through the NodePort service at `http://localhost:30061`.

## Adding Structure to Logs

Applications log JSON so Fluent Bit can parse fields properly. A quick view of index.js shows a custom `logger` that wraps `console.log(JSON.stringify({...}))`. FluentBit consumes standard output logs, parses them natively due to `.conf` rules, and ships to ES.
