#################
### Dashboard ###
#################

# Dashboard
resource "newrelic_one_dashboard" "apps" {
  name = "OTel Playground"

  #################
  ### SIMULATOR ###
  #################
  page {
    name = "Simulator (Metrics)"

    # Simulator -> HTTP server
    widget_markdown {
      title  = "Simulator -> HTTP server"
      column = 1
      row    = 1
      width  = 3
      height = 3

      text = "## Simulator -> HTTP Server"
    }

    # Latency of calls to HTTP server (ms)
    widget_line {
      title  = "Latency of calls to HTTP server (ms)"
      column = 4
      row    = 1
      width  = 9
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(http.client.duration) AS `Latency` WHERE service.name = 'simulator-${var.LANGUAGE_IDENTIFIER}' TIMESERIES"
      }
    }

    # Throughput of calls to HTTP server (rpm)
    widget_line {
      title  = "Throughput of calls to HTTP server (rpm)"
      column = 1
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT rate(count(http.client.duration), 1 minute) AS `Throughput` WHERE service.name = 'simulator-${var.LANGUAGE_IDENTIFIER}' TIMESERIES"
      }
    }

    # Error rate of calls to HTTP server (%)
    widget_line {
      title  = "Error rate of calls to HTTP server (%)"
      column = 7
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT filter(count(http.client.duration), WHERE numeric(http.status_code) >= 500)/count(http.client.duration)*100 AS `Error rate` WHERE service.name = 'simulator-${var.LANGUAGE_IDENTIFIER}' TIMESERIES"
      }
    }
  }

  page {
    name = "Simulator (Spans)"

    # Simulator -> HTTP server
    widget_markdown {
      title  = "Simulator -> HTTP server"
      column = 1
      row    = 1
      width  = 3
      height = 3

      text = "## Simulator -> HTTP Server"
    }

    # Latency of calls to HTTP server (ms)
    widget_line {
      title  = "Latency of calls to HTTP server (ms)"
      column = 4
      row    = 1
      width  = 9
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Span SELECT average(duration.ms) WHERE service.name = 'simulator-${var.LANGUAGE_IDENTIFIER}' AND span.kind = 'client' AND net.peer.name = 'httpserver-${var.LANGUAGE_IDENTIFIER}.${var.LANGUAGE_IDENTIFIER}.svc.cluster.local' TIMESERIES"
      }
    }

    # Throughput of calls to HTTP server (rpm)
    widget_line {
      title  = "Throughput of calls to HTTP server (rpm)"
      column = 1
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Span SELECT rate(count(*), 1 minute) AS `Throughput` WHERE service.name = 'simulator-${var.LANGUAGE_IDENTIFIER}' AND span.kind = 'client' AND net.peer.name = 'httpserver-${var.LANGUAGE_IDENTIFIER}.${var.LANGUAGE_IDENTIFIER}.svc.cluster.local' TIMESERIES"
      }
    }

    # Error rate of calls to HTTP server (%)
    widget_line {
      title  = "Error rate of calls to HTTP server (%)"
      column = 7
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Span SELECT filter(count(*), WHERE otel.status_code = 'ERROR')/count(*)*100 AS `Error rate` WHERE service.name = 'simulator-${var.LANGUAGE_IDENTIFIER}' AND span.kind = 'client' AND net.peer.name = 'httpserver-${var.LANGUAGE_IDENTIFIER}.${var.LANGUAGE_IDENTIFIER}.svc.cluster.local' TIMESERIES"
      }
    }
  }

  ###################
  ### HTTP SERVER ###
  ###################
  page {
    name = "HTTP Server (Metrics)"

    # Overall HTTP server performance
    widget_markdown {
      title  = "Overall HTTP server performance"
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

  page {
    name = "HTTP Server (Spans)"

    # Overall HTTP server performance
    widget_markdown {
      title  = "Overall HTTP server performance"
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
        query      = "FROM Span SELECT average(duration.ms) AS `Response time` WHERE service.name = 'httpserver-${var.LANGUAGE_IDENTIFIER}' AND span.kind = 'server' TIMESERIES"
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
        query      = "FROM Span SELECT rate(count(*), 1 minute) AS `Throughput` WHERE service.name = 'httpserver-${var.LANGUAGE_IDENTIFIER}' AND span.kind = 'server' TIMESERIES"
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
        query      = "FROM Span SELECT filter(count(*), WHERE otel.status_code = 'ERROR')/count(*)*100 AS `Error rate` WHERE service.name = 'httpserver-${var.LANGUAGE_IDENTIFIER}' AND span.kind = 'server' TIMESERIES"
      }
    }
  }
}
