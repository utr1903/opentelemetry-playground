# Monitoring

## Running Terraform

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
