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
httpserver["name"]="httpserver-golang"
httpserver["imageName"]="${repoName}:${httpserver[name]}-${platform}"
httpserver["namespace"]="golang"
httpserver["replicas"]=1
httpserver["port"]=8080

# kafkaconsumer
declare -A kafkaconsumer
kafkaconsumer["name"]="kafkaconsumer-golang"
kafkaconsumer["imageName"]="${repoName}:${kafkaconsumer[name]}-${platform}"
kafkaconsumer["namespace"]="golang"
kafkaconsumer["replicas"]=1

# simulator
declare -A simulator
simulator["name"]="simulator-golang"
simulator["imageName"]="${repoName}:${simulator[name]}-${platform}"
simulator["namespace"]="golang"
simulator["replicas"]=1
simulator["port"]=8080
simulator["httpInterval"]=2000
simulator["kafkaInterval"]=1000

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

  # kafkaconsumer
  docker build \
    --platform "linux/${platform}" \
    --tag "${DOCKERHUB_NAME}/${kafkaconsumer[imageName]}" \
    "../../apps/kafkaconsumer/."
  docker push "${DOCKERHUB_NAME}/${kafkaconsumer[imageName]}"

  # simulator
  docker build \
    --platform "linux/${platform}" \
    --tag "${DOCKERHUB_NAME}/${simulator[imageName]}" \
    "../../apps/simulator/."
  docker push "${DOCKERHUB_NAME}/${simulator[imageName]}"
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

# kafka
helm upgrade ${kafka[name]} \
  --install \
  --wait \
  --debug \
  --create-namespace \
  --namespace=${kafka[namespace]} \
  "bitnami/kafka"

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

# otelcollector
helm upgrade ${otelcollector[name]} \
  --install \
  --wait \
  --debug \
  --create-namespace \
  --namespace ${otelcollector[namespace]} \
  --set mode=${otelcollector[mode]} \
  --set config.receivers.jaeger=null \
  --set config.receivers.prometheus=null \
  --set config.receivers.zipkin=null \
  --set config.processors.cumulativetodelta.include.match_type="strict" \
  --set config.processors.cumulativetodelta.include.metrics[0]="http.server.duration" \
  --set config.processors.cumulativetodelta.include.metrics[1]="http.client.duration" \
  --set config.exporters.logging=null \
  --set config.exporters.otlp.endpoint="otlp.eu01.nr-data.net:4317" \
  --set config.exporters.otlp.tls.insecure=false \
  --set config.exporters.otlp.headers.api-key=$NEWRELIC_LICENSE_KEY \
  --set config.service.pipelines.traces.receivers[0]="otlp" \
  --set config.service.pipelines.traces.processors[0]="batch" \
  --set config.service.pipelines.traces.processors[1]="memory_limiter" \
  --set config.service.pipelines.traces.exporters[0]="otlp" \
  --set config.service.pipelines.metrics.receivers[0]="otlp" \
  --set config.service.pipelines.metrics.processors[0]="batch" \
  --set config.service.pipelines.metrics.processors[1]="memory_limiter" \
  --set config.service.pipelines.metrics.processors[2]="cumulativetodelta" \
  --set config.service.pipelines.metrics.exporters[0]="otlp" \
  --set config.service.pipelines.logs=null \
  "open-telemetry/opentelemetry-collector"

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
  --set otel.exporter="otlp" \
  --set otlp.endpoint="http://${otelcollector[name]}-opentelemetry-collector.${otelcollector[namespace]}.svc.cluster.local:4317" \
  "../helm/httpserver"

# kafkaconsumer
helm upgrade ${kafkaconsumer[name]} \
  --install \
  --wait \
  --debug \
  --create-namespace \
  --namespace=${kafkaconsumer[namespace]} \
  --set dockerhubName=$DOCKERHUB_NAME \
  --set imageName=${kafkaconsumer[imageName]} \
  --set imagePullPolicy="Always" \
  --set name=${kafkaconsumer[name]} \
  --set replicas=${kafkaconsumer[replicas]} \
  --set kafka.address="${kafka[name]}.${kafka[namespace]}.svc.cluster.local:9092" \
  --set kafka.topic=${kafka[topic]} \
  --set kafka.groupId=${kafkaconsumer[name]} \
  --set mysql.server="${mysql[name]}.${mysql[namespace]}.svc.cluster.local" \
  --set mysql.username=${mysql[username]} \
  --set mysql.password=${mysql[password]} \
  --set mysql.port=${mysql[port]} \
  --set mysql.database=${mysql[database]} \
  --set mysql.table=${mysql[table]} \
  --set otel.exporter="otlp" \
  --set otlp.endpoint="http://${otelcollector[name]}-opentelemetry-collector.${otelcollector[namespace]}.svc.cluster.local:4317" \
  "../helm/kafkaconsumer"

# simulator
helm upgrade ${simulator[name]} \
  --install \
  --wait \
  --debug \
  --create-namespace \
  --namespace=${simulator[namespace]} \
  --set dockerhubName=$DOCKERHUB_NAME \
  --set imageName=${simulator[imageName]} \
  --set imagePullPolicy="Always" \
  --set name=${simulator[name]} \
  --set replicas=${simulator[replicas]} \
  --set port=${simulator[port]} \
  --set httpserver.requestInterval=${simulator[httpInterval]} \
  --set httpserver.endpoint="${httpserver[name]}.${httpserver[namespace]}.svc.cluster.local" \
  --set httpserver.port="${httpserver[port]}" \
  --set kafka.address="${kafka[name]}-0.${kafka[name]}-headless.${kafka[namespace]}.svc.cluster.local:9092" \
  --set kafka.topic=${kafka[topic]} \
  --set kafka.requestInterval=${simulator[kafkaInterval]} \
  --set otel.exporter="otlp" \
  --set otlp.endpoint="http://${otelcollector[name]}-opentelemetry-collector.${otelcollector[namespace]}.svc.cluster.local:4317" \
  "../helm/simulator"
