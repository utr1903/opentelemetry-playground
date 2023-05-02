# Opentelemetry Playground

This repository is dedicated to showcase monitoring of various real life scenarios by Open Telemetry instrumentation. Currently available languages:

- [Golang](./golang/)
- [Java](./java/)

## Prerequisites

- docker (required)
- helm (required)
- kubectl (optional)
- terraform (optional)

## Architecture

![Architecture](./docs/otel-playground.png)

## Deployment

### Create a K8s cluster

Although this playground can run on any Kubernetes cluster, using a `kind` cluster is recommended for testing purposes.

In order to deploy one,

you can either run the following command:

```
kind create cluster --name otel
```

or you can run the script [`01_create_kind_cluster.sh`](./infra/scripts/01_create_kind_cluster.sh):

```
bash 01_create_kind_cluster.sh
```

### Deploy applications

The playground contains the following applications:

- Kafka
- MySQL
- OTel collector
- HTTP server
- Kafka consumer
- Simulator

For simplicity sake, the original Helm repositories are used for Kafka (bitnami), MySQL (bitnami) and OTel collector (opentelemetry). The necessary values are updated within the bash script [`02_deploy_apps.sh`](./infra/scripts/02_deploy_apps.sh) by ` helm ... --set`.

The following parameters must be set as environment variables or be overriden within the script:

- `DOCKERHUB_NAME`
- `NEWRELIC_LICENSE_KEY`

Currently, there is no default image set. Therefore, for the first run you have to build the images locally and push to your Dockerhub.

For AMD64

```
bash 02_deploy_apps.sh --build
```

or

```
bash 02_deploy_apps.sh --build --platform amd64
```

For ARM64

```
bash 02_deploy_apps.sh --build --platform arm64
```

Once you have the images pushed to your registry, you no longer need the `--build` flag.

NOTE: If your New Relic account is in US, set the OTLP endpoint to `otlp.nr-data.net:4317` on line 183 as follows:

```
...
--set config.exporters.otlp.endpoint="otlp.nr-data.net:4317"
...
```

## Monitoring

### Running Terraform

The [`deploy_monitoring.sh`](./scripts/deploy_monitoring.sh) script will create the monitoring dashboard for you.

You need to set the following parameters as environment variables:

- `NEWRELIC_ACCOUNT_ID`
  - The account which you want the dashboard created in
- `NEWRELIC_API_KEY`
  - The New Relic User API Key
- `NEWRELIC_REGION`
  - The region where your New Relic account is in (`us` or `eu`)

You need to define the programming language per the flag `--language` which you have deployed in your playground (currently only `golang`).

To run `terraform plan`, use the flag `--dry-run` and to run `terraform destroy`, use the flag `--destroy`.
