# Golang

## Create a K8s cluster

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

## Deploy applications

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
bash 02_deploy_apps.sh --build --platform arm64
```

For ARM64

```
bash 02_deploy_apps.sh --build --platform amd64
```

Once you have the images pushed to your registry, you no longer need the `--build` flag.

NOTE: If your New Relic account is in US, set the OTLP endpoint to `otlp.nr-data.net:4317` on line 183 as follows:

```
...
--set config.exporters.otlp.endpoint="otlp.nr-data.net:4317"
...
```
