# Opentelemetry Playground

This repository is dedicated to showcase monitoring of various real life scenarios by Open Telemetry instrumentation. Currently available languages:

- [Golang](./golang/README.md)

## Prerequisites

- docker (required)
- helm (required)
- kubectl (optional)
- terraform (optional)

## Architecture

![asd](./docs/otel-playground.png)

## Monitoring

If you would like to have an instant observability, you can create pre-built dashboards by running a [`Terraform`](./monitoring/README.md) deployment.
