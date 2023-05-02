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
        query      = "FROM Metric SELECT average(http.client.duration) AS `Latency` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' TIMESERIES"
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
        query      = "FROM Metric SELECT rate(count(http.client.duration), 1 minute) AS `Throughput` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' TIMESERIES"
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
        query      = "FROM Metric SELECT filter(count(http.client.duration), WHERE numeric(http.status_code) >= 500)/count(http.client.duration)*100 AS `Error rate` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' TIMESERIES"
      }
    }

    # Recent CPU utilization for the process
    widget_line {
      title  = "Recent CPU utilization for the process"
      column = 1
      row    = 7
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(process.runtime.jvm.cpu.utilization) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' TIMESERIES"
      }
    }

    # Recent CPU utilization for the whole system
    widget_line {
      title  = "Recent CPU utilization for the whole system"
      column = 7
      row    = 7
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(process.runtime.jvm.system.cpu.utilization) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' TIMESERIES"
      }
    }

    # Measure of memory usage by type (bytes)
    widget_area {
      title  = "Measure of memory usage by type (bytes)"
      column = 1
      row    = 10
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(process.runtime.jvm.memory.usage) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET type TIMESERIES"
      }
    }

    # Measure of memory usage by pool (bytes)
    widget_area {
      title  = "Measure of memory usage by pool (bytes)"
      column = 7
      row    = 10
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(process.runtime.jvm.memory.usage) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET pool TIMESERIES"
      }
    }

    # Measure of initial memory requested by type (bytes)
    widget_area {
      title  = "Measure of initial memory requested by type (bytes)"
      column = 1
      row    = 13
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(process.runtime.jvm.memory.init) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET type TIMESERIES"
      }
    }

    # Measure of initial memory requested by pool (bytes)
    widget_area {
      title  = "Measure of initial memory requested by pool (bytes)"
      column = 7
      row    = 13
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(process.runtime.jvm.memory.init) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET pool TIMESERIES"
      }
    }

    # Measure of memory committed by type (bytes)
    widget_area {
      title  = "Measure of memory committed by type (bytes)"
      column = 1
      row    = 16
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(process.runtime.jvm.memory.committed) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET type TIMESERIES"
      }
    }

    # Measure of memory committed by pool (bytes)
    widget_area {
      title  = "Measure of memory committed by pool (bytes)"
      column = 7
      row    = 16
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(process.runtime.jvm.memory.committed) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET pool TIMESERIES"
      }
    }

    # Measure of max obtainable memory by type (bytes)
    widget_area {
      title  = "Measure of max obtainable memory by type (bytes)"
      column = 1
      row    = 19
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.jvm.memory.limit`) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET pool TIMESERIES"
      }
    }

    # Measure of max obtainable memory by pool (bytes)
    widget_area {
      title  = "Measure of max obtainable memory by pool (bytes)"
      column = 7
      row    = 19
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.jvm.memory.limit`) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET pool TIMESERIES"
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
        query      = "FROM Span SELECT average(duration.ms) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND span.kind = 'client' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' TIMESERIES"
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
        query      = "FROM Span SELECT rate(count(*), 1 minute) AS `Throughput` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND span.kind = 'client' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' TIMESERIES"
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
        query      = "FROM Span SELECT filter(count(*), WHERE instrumentation.provider = 'opentelemetry' AND otel.status_code = 'ERROR')/count(*)*100 AS `Error rate` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND span.kind = 'client' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' TIMESERIES"
      }
    }
  }

  ###################
  ### HTTP SERVER ###
  ###################
  page {
    name = "HTTP Server (Metrics)"

    # Overall server performance
    widget_markdown {
      title  = "Overall server performance"
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
        query      = "FROM Metric SELECT average(http.server.duration) AS `Response time` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' TIMESERIES"
      }
    }

    # Web throughput (rpm)
    widget_line {
      title  = "Web throughput (rpm)"
      column = 1
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT rate(count(http.server.duration), 1 minute) AS `Throughput` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' TIMESERIES"
      }
    }

    # Error rate (%)
    widget_line {
      title  = "Error rate (%)"
      column = 7
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT filter(count(http.server.duration), WHERE instrumentation.provider = 'opentelemetry' AND numeric(http.status_code) >= 500)/count(http.server.duration)*100 AS `Error rate` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' TIMESERIES"
      }
    }

    # Recent CPU utilization for the process
    widget_line {
      title  = "Recent CPU utilization for the process"
      column = 1
      row    = 7
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(process.runtime.jvm.cpu.utilization) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' TIMESERIES"
      }
    }

    # Recent CPU utilization for the whole system
    widget_line {
      title  = "Recent CPU utilization for the whole system"
      column = 7
      row    = 7
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(process.runtime.jvm.system.cpu.utilization) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' TIMESERIES"
      }
    }

    # Measure of memory usage by type (bytes)
    widget_area {
      title  = "Measure of memory usage by type (bytes)"
      column = 1
      row    = 10
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(process.runtime.jvm.memory.usage) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET type TIMESERIES"
      }
    }

    # Measure of memory usage by pool (bytes)
    widget_area {
      title  = "Measure of memory usage by pool (bytes)"
      column = 7
      row    = 10
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(process.runtime.jvm.memory.usage) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET pool TIMESERIES"
      }
    }

    # Measure of initial memory requested by type (bytes)
    widget_area {
      title  = "Measure of initial memory requested by type (bytes)"
      column = 1
      row    = 13
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(process.runtime.jvm.memory.init) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET type TIMESERIES"
      }
    }

    # Measure of initial memory requested by pool (bytes)
    widget_area {
      title  = "Measure of initial memory requested by pool (bytes)"
      column = 7
      row    = 13
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(process.runtime.jvm.memory.init) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET pool TIMESERIES"
      }
    }

    # Measure of memory committed by type (bytes)
    widget_area {
      title  = "Measure of memory committed by type (bytes)"
      column = 1
      row    = 16
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(process.runtime.jvm.memory.committed) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET type TIMESERIES"
      }
    }

    # Measure of memory committed by pool (bytes)
    widget_area {
      title  = "Measure of memory committed by pool (bytes)"
      column = 7
      row    = 16
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(process.runtime.jvm.memory.committed) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET pool TIMESERIES"
      }
    }

    # Measure of max obtainable memory by type (bytes)
    widget_area {
      title  = "Measure of max obtainable memory by type (bytes)"
      column = 1
      row    = 19
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.jvm.memory.limit`) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET pool TIMESERIES"
      }
    }

    # Measure of max obtainable memory by pool (bytes)
    widget_area {
      title  = "Measure of max obtainable memory by pool (bytes)"
      column = 7
      row    = 19
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.jvm.memory.limit`) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET pool TIMESERIES"
      }
    }
  }

  page {
    name = "HTTP Server (Spans)"

    # Overall server performance
    widget_markdown {
      title  = "Overall server performance"
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
        query      = "FROM Span SELECT average(duration.ms) AS `Response time` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' AND span.kind = 'server' TIMESERIES"
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
        query      = "FROM Span SELECT rate(count(*), 1 minute) AS `Throughput` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' AND span.kind = 'server' TIMESERIES"
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
        query      = "FROM Span SELECT filter(count(*), WHERE instrumentation.provider = 'opentelemetry' AND otel.status_code = 'ERROR')/count(*)*100 AS `Error rate` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' AND span.kind = 'server' TIMESERIES"
      }
    }

    # Database performace
    widget_markdown {
      title  = "Database performace"
      column = 1
      row    = 7
      width  = 3
      height = 3

      text = "## Database"
    }

    # Average database time (ms)
    widget_line {
      title  = "Average database time (ms)"
      column = 4
      row    = 7
      width  = 9
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Span SELECT average(duration.ms) AS `DB time` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' AND span.kind = 'client' AND net.peer.name = 'mysql.otel.svc.cluster.local' TIMESERIES"
      }
    }

    # Database throughput (rpm)
    widget_line {
      title  = "Database throughput (rpm)"
      column = 1
      row    = 10
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Span SELECT rate(count(*), 1 minute) AS `Throughput` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' AND span.kind = 'client' AND net.peer.name = 'mysql.otel.svc.cluster.local' TIMESERIES"
      }
    }

    # Database error rate (%)
    widget_line {
      title  = "Database error rate (%)"
      column = 7
      row    = 10
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Span SELECT filter(count(*), WHERE instrumentation.provider = 'opentelemetry' AND otel.status_code = 'ERROR')/count(*)*100 AS `Error rate` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' AND span.kind = 'client' AND net.peer.name = 'mysql.otel.svc.cluster.local' TIMESERIES"
      }
    }

    # Max database operation latency (ms)
    widget_bar {
      title  = "Max database operation latency (ms)"
      column = 1
      row    = 13
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Span SELECT max(duration.ms) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' AND span.kind = 'client' AND net.peer.name = 'mysql.otel.svc.cluster.local' FACET db.name, db.sql.table, db.operation TIMESERIES"
      }
    }

    # Database operation throughput (rpm)
    widget_bar {
      title  = "Max database operation throughput (rpm)"
      column = 5
      row    = 13
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Span SELECT rate(count(*), 1 minute) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' AND span.kind = 'client' AND net.peer.name = 'mysql.otel.svc.cluster.local' FACET db.name, db.sql.table, db.operation TIMESERIES"
      }
    }

    # Database operation error rate (%)
    widget_bar {
      title  = "Average database error rate (%)"
      column = 9
      row    = 13
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Span SELECT filter(count(*), WHERE instrumentation.provider = 'opentelemetry' AND otel.status_code = 'ERROR')/count(*)*100 WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' AND span.kind = 'client' AND net.peer.name = 'mysql.otel.svc.cluster.local' FACET db.name, db.sql.table, db.operation TIMESERIES"
      }
    }
  }
}
