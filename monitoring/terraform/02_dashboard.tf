#################
### Dashboard ###
#################

# Dashboard
resource "newrelic_one_dashboard" "apps" {
  name = "OTel Playground"

  ###################
  ### HTTP SERVER ###
  ###################
  page {
    name = "HTTP Server"

    # Page description
    widget_markdown {
      title  = "Page description"
      column = 1
      row    = 1
      width  = 3
      height = 3

      text = "## HTTP Server"
    }

    # Average web response time (ms)
    widget_line {
      title  = "Average web response time (ms)"
      column = 4
      row    = 1
      width  = 9
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(http.server.duration) AS `Response time` WHERE service.name = 'httpserver-${var.LANGUAGE_IDENTIFIER}' TIMESERIES"
      }
    }

    # Average web throughput (rpm)
    widget_line {
      title  = "Average web throughput (rpm)"
      column = 1
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT rate(count(http.server.duration), 1 minute) AS `Throughput` WHERE service.name = 'httpserver-${var.LANGUAGE_IDENTIFIER}' TIMESERIES"
      }
    }

    # Average error rate (%)
    widget_line {
      title  = "Average error rate (%)"
      column = 7
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT filter(count(http.server.duration), WHERE numeric(http.status_code) >= 500)/count(http.server.duration)*100 AS `Error rate` WHERE service.name = 'httpserver-${var.LANGUAGE_IDENTIFIER}' TIMESERIES"
      }
    }
  }
}
