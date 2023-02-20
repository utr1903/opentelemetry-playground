#!/bin/bash

###################
### Parse input ###
###################

while (( "$#" )); do
  case "$1" in
    --platform)
      platform="$2"
      shift
      ;;
    --build)
      build="true"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Docker platform
if [[ $platform == "" ]]; then
  # Default is amd
  platform="amd64"
else
  if [[ $platform != "amd64" && $platform != "arm64" ]]; then
    echo "Platform can either be 'amd64' or 'arm64'."
    exit 1
  fi
fi

#####################
### Set variables ###
#####################

repoName="opentelemetry-playground"
clusterName="opentelemetry-playground"

# prometheus
declare -A prometheus
prometheus["name"]="prometheus"
prometheus["namespace"]="golang"

# kafka
declare -A kafka
kafka["name"]="kafka"
kafka["namespace"]="golang"
kafka["topic"]="otel"

# mysql
declare -A mysql
mysql["name"]="mysql"
mysql["namespace"]="golang"
mysql["username"]="root"
mysql["password"]="verysecretpassword"
mysql["port"]=3306
mysql["database"]="otel"
mysql["table"]="names"

# otelcollector
declare -A otelcollector
otelcollector["name"]="otel-collector"
otelcollector["namespace"]="golang"
otelcollector["mode"]="deployment"
otelcollector["prometheusPort"]=9464

# httpserver
declare -A httpserver
httpserver["name"]="httpserver"
httpserver["imageName"]="${repoName}:golang-${httpserver[name]}-${platform}"
httpserver["namespace"]="golang"
httpserver["replicas"]=1
httpserver["port"]=8080

####################
### Build & Push ###
####################

if [[ $build == "true" ]]; then
  # httpserver
  docker build \
    --platform "linux/${platform}" \
    --tag "${DOCKERHUB_NAME}/${httpserver[imageName]}" \
    "../../apps/httpserver/."
  docker push "${DOCKERHUB_NAME}/${httpserver[imageName]}"
fi

###################
### Deploy Helm ###
###################

# Add helm repos
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# # prometheus
# helm upgrade ${prometheus[name]} \
#   --install \
#   --wait \
#   --debug \
#   --create-namespace \
#   --namespace ${prometheus[namespace]} \
#   --set alertmanager.enabled=false \
#   --set prometheus-pushgateway.enabled=false \
#   --set kubeStateMetrics.enabled=true \
#   --set nodeExporter.enabled=true \
#   --set nodeExporter.tolerations[0].effect="NoSchedule" \
#   --set nodeExporter.tolerations[0].operator="Exists" \
#   --set server.remoteWrite[0].url="https://metric-api.eu.newrelic.com/prometheus/v1/write?prometheus_server=${clusterName}" \
#   --set server.remoteWrite[0].bearer_token=$NEWRELIC_LICENSE_KEY \
#   "prometheus-community/prometheus"

# # kafka
# helm upgrade ${kafka[name]} \
#   --install \
#   --wait \
#   --debug \
#   --create-namespace \
#   --namespace=${kafka[namespace]} \
#   "bitnami/kafka"

# mysql
helm upgrade ${mysql[name]} \
  --install \
  --wait \
  --debug \
  --create-namespace \
  --namespace=${mysql[namespace]} \
  --set auth.rootPassword=${mysql[password]} \
  --set auth.database=${mysql[database]} \
    "bitnami/mysql"

# # otelcollector
# helm upgrade ${otelcollector[name]} \
#   --install \
#   --wait \
#   --debug \
#   --create-namespace \
#   --namespace ${otelcollector[namespace]} \
#   --set name=${otelcollector[name]} \
#   --set mode=${otelcollector[mode]} \
#   --set prometheus.port=${otelcollector[prometheusPort]} \
#   --set newrelicOtlpEndpoint="otlp.eu01.nr-data.net:4317" \
#   --set newrelicLicenseKey=$NEWRELIC_LICENSE_KEY \
#   "../helm/otelcollector"

# httpserver
helm upgrade ${httpserver[name]} \
  --install \
  --wait \
  --debug \
  --create-namespace \
  --namespace=${httpserver[namespace]} \
  --set dockerhubName=$DOCKERHUB_NAME \
  --set imageName=${httpserver[imageName]} \
  --set imagePullPolicy="Always" \
  --set name=${httpserver[name]} \
  --set replicas=${httpserver[replicas]} \
  --set port=${httpserver[port]} \
  --set mysql.server="${mysql[name]}.${mysql[namespace]}.svc.cluster.local" \
  --set mysql.username=${mysql[username]} \
  --set mysql.password=${mysql[password]} \
  --set mysql.port=${mysql[port]} \
  --set mysql.database=${mysql[database]} \
  --set mysql.table=${mysql[table]} \
  --set otlp.endpoints="https://otlp.eu01.nr-data.net:4317" \
  --set otlp.headers="Api-Key=${NEWRELIC_LICENSE_KEY}" \
  "../helm/httpserver"
