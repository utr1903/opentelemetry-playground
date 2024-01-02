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
    --language)
      language="$2"
      shift
      ;;
    --otlp)
      otlpEndpoint="$2"
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

# Programming language
if [[ $language != "golang" && $language != "java" ]]; then
  echo "Currently supported languages are 'golang' or 'java'."
  exit 1
fi

# OTLP endpoint
if [[ $otlpEndpoint == "" ]]; then
  otlpEndpoint="http://nrotelk8s-dep-rec-collector-headless.monitoring.svc.cluster.local:4317"
fi

#####################
### Set variables ###
#####################

repoName="opentelemetry-playground"
clusterName="opentelemetry-playground"

# kafka
declare -A kafka
kafka["name"]="kafka"
kafka["namespace"]="${language}"
kafka["topic"]="${language}"

# mysql
declare -A mysql
mysql["name"]="mysql"
mysql["namespace"]="${language}"
mysql["username"]="root"
mysql["password"]="verysecretpassword"
mysql["port"]=3306
mysql["database"]="otel"
mysql["table"]="names"

# otelcollector
declare -A otelcollector
otelcollector["name"]="otel-collector"
otelcollector["namespace"]="${language}"
otelcollector["mode"]="deployment"
otelcollector["prometheusPort"]=9464

# httpserver
declare -A httpserver
httpserver["name"]="httpserver-${language}"
httpserver["imageName"]="${repoName}:${httpserver[name]}-${platform}"
httpserver["namespace"]="${language}"
httpserver["replicas"]=2
httpserver["port"]=8080

# kafkaconsumer
declare -A kafkaconsumer
kafkaconsumer["name"]="kafkaconsumer-${language}"
kafkaconsumer["imageName"]="${repoName}:${kafkaconsumer[name]}-${platform}"
kafkaconsumer["namespace"]="${language}"
kafkaconsumer["replicas"]=2

# simulator
declare -A simulator
simulator["name"]="simulator-${language}"
simulator["imageName"]="${repoName}:${simulator[name]}-${platform}"
simulator["namespace"]="${language}"
simulator["replicas"]=3
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
    "../../${language}/apps/httpserver/."
  docker push "${DOCKERHUB_NAME}/${httpserver[imageName]}"

  # kafkaconsumer
  docker build \
    --platform "linux/${platform}" \
    --tag "${DOCKERHUB_NAME}/${kafkaconsumer[imageName]}" \
    "../../${language}/apps/kafkaconsumer/."
  docker push "${DOCKERHUB_NAME}/${kafkaconsumer[imageName]}"

  # simulator
  docker build \
    --platform "linux/${platform}" \
    --tag "${DOCKERHUB_NAME}/${simulator[imageName]}" \
    "../../${language}/apps/simulator/."
  docker push "${DOCKERHUB_NAME}/${simulator[imageName]}"
fi

###################
### Deploy Helm ###
###################

# Add helm repos
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# kafka
helm upgrade ${kafka[name]} \
  --install \
  --wait \
  --debug \
  --create-namespace \
  --namespace=${kafka[namespace]} \
  --set listeners.client.protocol=PLAINTEXT \
  --version "26.6.2" \
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
  --version "9.15.0" \
  "bitnami/mysql"

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
  --set otlp.endpoint="${otlpEndpoint}" \
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
  --set otlp.endpoint="${otlpEndpoint}" \
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
  --set kafka.address="${kafka[name]}.${kafka[namespace]}.svc.cluster.local:9092" \
  --set kafka.topic=${kafka[topic]} \
  --set kafka.requestInterval=${simulator[kafkaInterval]} \
  --set otel.exporter="otlp" \
  --set otlp.endpoint="${otlpEndpoint}" \
  "../helm/simulator"
