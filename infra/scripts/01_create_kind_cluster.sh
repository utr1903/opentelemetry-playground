#!/bin/bash

###################
### Infra Setup ###
###################

kind create cluster \
  --name otel \
  --config ./helpers/kind-config.yaml \
  --image=kindest/node:v1.26.0
