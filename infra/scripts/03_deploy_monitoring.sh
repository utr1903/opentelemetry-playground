#!/bin/bash

# Get commandline arguments
while (( "$#" )); do
  case "$1" in
    --language)
      language="$2"
      shift
      ;;
    --destroy)
      flagDestroy="true"
      shift
      ;;
    --dry-run)
      flagDryRun="true"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

### Check input
if [[ $language != "golang" && $language != "java" ]]; then
  echo -e "The flag [--language] is invalid. The supported languages are: golang, java."
  exit 1
fi

clusterName="opentelemetry-playground"

### Set variables

if [[ $flagDestroy != "true" ]]; then

  # Initialize Terraform
  terraform -chdir=../../${language}/monitoring/terraform init

  # Plan Terraform
  terraform -chdir=../../${language}/monitoring/terraform plan \
    -var NEW_RELIC_ACCOUNT_ID=$NEWRELIC_ACCOUNT_ID \
    -var NEW_RELIC_API_KEY=$NEWRELIC_API_KEY \
    -var NEW_RELIC_REGION=$NEWRELIC_REGION \
    -var cluster_name=$clusterName \
    -out "./tfplan"

  # Apply Terraform
  if [[ $flagDryRun != "true" ]]; then
    terraform -chdir=../../${language}/monitoring/terraform apply tfplan
  fi
else

  # Destroy Terraform
  terraform -chdir=../../${language}/monitoring/terraform destroy \
  -var NEW_RELIC_ACCOUNT_ID=$NEWRELIC_ACCOUNT_ID \
  -var NEW_RELIC_API_KEY=$NEWRELIC_API_KEY \
  -var NEW_RELIC_REGION=$NEWRELIC_REGION \
  -var cluster_name=$clusterName
fi
