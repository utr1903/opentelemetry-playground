#################
### Dashboard ###
#################

# Dashboard
resource "newrelic_one_dashboard" "httpserver" {
  name = "OTel Playground - HTTP Server"

  ###########################
  ### Runtime Performance ###
  ###########################
  page {
    name = "Runtime Performance"

    # CPU Utilization
    widget_markdown {
      title  = ""
      column = 1
      row    = 1
      width  = 4
      height = 3

      text = "## CPU Utilization\n\nCPU utilization can be tracked with 2 metrics:\n\n- Recent CPU utilization for the process\n   - `process.runtime.jvm.cpu.utilization`\n- Recent CPU utilization for the whole system\n   - `process.runtime.jvm.system.cpu.utilization`"
    }

    # Recent CPU utilization for the process
    widget_billboard {
      title  = "Recent CPU utilization for the process"
      column = 5
      row    = 1
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.jvm.cpu.utilization`) AS `Process` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java'"
      }
    }

    # Recent CPU utilization for the whole system
    widget_billboard {
      title  = "Recent CPU utilization for the whole system"
      column = 9
      row    = 1
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.jvm.system.cpu.utilization`) AS `System` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java'"
      }
    }

    # Recent CPU utilization for the process
    widget_line {
      title  = "Recent CPU utilization for the process"
      column = 1
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.jvm.cpu.utilization`) AS `Process` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' TIMESERIES"
      }
    }

    # Recent CPU utilization for the whole system
    widget_line {
      title  = "Recent CPU utilization for the whole system"
      column = 7
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.jvm.system.cpu.utilization`) AS `System` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' TIMESERIES"
      }
    }

    # Memory Usage & Limits
    widget_markdown {
      title  = ""
      column = 1
      row    = 7
      width  = 4
      height = 3

      text = "## Memory Usage & Limits\n\nMemory usage & limits can be tracked with 4 metrics:\n\n- Measure of initial memory requested\n   - `process.runtime.jvm.memory.init`\n- Measure of memory committed\n   - `process.runtime.jvm.memory.committed`\n- Measure of memory used\n   - `process.runtime.jvm.memory.usage`\n- Measure of max obtainable memory\n   - `process.runtime.jvm.memory.limit`"
    }

    # Measure of initial memory requested (bytes)
    widget_billboard {
      title  = "Measure of initial memory requested (bytes)"
      column = 5
      row    = 7
      width  = 2
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.init`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET type, pool LIMIT MAX) SELECT sum(`sum`)"
      }
    }

    # Measure of memory committed (bytes)
    widget_billboard {
      title  = "Measure of memory committed (bytes)"
      column = 7
      row    = 7
      width  = 2
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.committed`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET type, pool LIMIT MAX) SELECT sum(`sum`)"
      }
    }

    # Measure of memory usage (bytes)
    widget_billboard {
      title  = "Measure of memory usage (bytes)"
      column = 9
      row    = 7
      width  = 2
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.usage`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET type, pool LIMIT MAX) SELECT sum(`sum`)"
      }
    }

    # Measure of max obtainable memory (bytes)
    widget_billboard {
      title  = "Measure of max obtainable memory (bytes)"
      column = 11
      row    = 7
      width  = 2
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.limit`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET type, pool LIMIT MAX) SELECT sum(`sum`)"
      }
    }

    # Measure of initial memory requested (bytes)
    widget_markdown {
      title  = ""
      column = 1
      row    = 10
      width  = 2
      height = 3

      text = "## Measure of initial memory requested"
    }

    # Measure of initial memory requested by type (bytes)
    widget_area {
      title  = "Measure of initial memory requested by type (bytes)"
      column = 3
      row    = 10
      width  = 5
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.init`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET type TIMESERIES"
      }
    }

    # Measure of initial memory requested by pool (bytes)
    widget_area {
      title  = "Measure of initial memory requested by pool (bytes)"
      column = 8
      row    = 10
      width  = 5
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.init`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET pool TIMESERIES"
      }
    }

    # Measure of memory committed by type
    widget_markdown {
      title  = ""
      column = 1
      row    = 13
      width  = 2
      height = 3

      text = "## Measure of memory committed by type"
    }

    # Measure of memory committed by type (bytes)
    widget_area {
      title  = "Measure of memory committed by type (bytes)"
      column = 3
      row    = 13
      width  = 5
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.committed`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET type TIMESERIES"
      }
    }

    # Measure of memory committed by pool (bytes)
    widget_area {
      title  = "Measure of memory committed by pool (bytes)"
      column = 8
      row    = 13
      width  = 5
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.committed`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET pool TIMESERIES"
      }
    }

    # Measure of memory usage by type
    widget_markdown {
      title  = ""
      column = 1
      row    = 16
      width  = 2
      height = 3

      text = "## Measure of memory usage by type"
    }

    # Measure of memory usage by type
    widget_area {
      title  = "Measure of memory usage by type"
      column = 3
      row    = 16
      width  = 5
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.usage`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET type TIMESERIES"
      }
    }

    # Measure of memory usage by pool (bytes)
    widget_area {
      title  = "Measure of memory usage by pool (bytes)"
      column = 8
      row    = 16
      width  = 5
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.usage`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET pool TIMESERIES"
      }
    }

    # Measure of max obtainable memory by type
    widget_markdown {
      title  = ""
      column = 1
      row    = 19
      width  = 2
      height = 3

      text = "## Measure of max obtainable memory by type"
    }

    # Measure of max obtainable memory by type
    widget_area {
      title  = "Measure of max obtainable memory by type"
      column = 3
      row    = 19
      width  = 5
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.limit`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET type TIMESERIES"
      }
    }

    # Measure of max obtainable memory by pool (bytes)
    widget_area {
      title  = "Measure of max obtainable memory by pool (bytes)"
      column = 8
      row    = 19
      width  = 5
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.limit`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET pool TIMESERIES"
      }
    }
  }

  #########################################
  ### Application Performance (Metrics) ###
  #########################################
  page {
    name = "Application Performance (Metrics)"

    # Golden Signals
    widget_markdown {
      title  = ""
      column = 1
      row    = 1
      width  = 3
      height = 3

      text = "## Application Performance\n\nThis page is dedicated for the application golden signals retrieved from the metrics.\n\n- Latency\n- Throughput\n- Error Rate"
    }

    # Latency (ms)
    widget_billboard {
      title  = "Latency (ms)"
      column = 4
      row    = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(http.server.duration) AS `Latency` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java'"
      }
    }

    # Throughput (rpm)
    widget_billboard {
      title  = "Throughput (rpm)"
      column = 7
      row    = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT rate(count(http.server.duration), 1 minute) AS `Throughput` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java'"
      }
    }

    # Error rate (%)
    widget_billboard {
      title  = "Error rate (%)"
      column = 10
      row    = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT filter(count(http.server.duration), WHERE instrumentation.provider = 'opentelemetry' AND numeric(http.status_code) >= 500)/count(http.server.duration)*100 AS `Error rate` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java'"
      }
    }

    # Latency
    widget_markdown {
      title  = ""
      column = 1
      row    = 4
      width  = 3
      height = 3

      text = "## Latency\n\nLatency is monitored per the metric `http.server.duration` which represents a histogram.\n\nIt corresponds to the aggregated response time of the HTTP server.\n\nMoreover, the detailed performance can be investigated according to the methods, response codes, instances, routes etc."
    }

    # Latency per HTTP status code (ms)
    widget_pie {
      title  = "Latency per HTTP status code (ms)"
      column = 4
      row    = 4
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`http.server.duration`) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET `http.status_code`"
      }
    }

    # Latency per HTTP method & route (ms)
    widget_bar {
      title  = "Latency per HTTP method & route (ms)"
      column = 7
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`http.server.duration`) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' AND `http.method` IS NOT NULL AND `http.route` IS NOT NULL FACET `http.method`, `http.route`"
      }
    }

    # Overall latency (ms)
    widget_line {
      title  = "Overall latency (ms)"
      column = 1
      row    = 7
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`http.server.duration`) AS `Overall Latency` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' TIMESERIES"
      }
    }

    # Latency per instance (ms)
    widget_line {
      title  = "Latency per instance (ms)"
      column = 7
      row    = 7
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`http.server.duration`) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' TIMESERIES"
      }
    }

    # Throughput
    widget_markdown {
      title  = ""
      column = 1
      row    = 10
      width  = 3
      height = 3

      text = "## Throughput\n\nThroughput is monitored per the rate of change in the metric `http.server.duration` in format of request per minute.\n\nIt corresponds to the aggregated amount of requests which are processed by the HTTP server in a minute.\n\nMoreover, the detailed performance can be investigated according to the methods, response codes, instances, routes etc."
    }

    # Throughput per HTTP status code (rpm)
    widget_pie {
      title  = "Throughput per HTTP status code (rpm)"
      column = 4
      row    = 10
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT rate(count(`http.server.duration`), 1 minute) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET `http.status_code`"
      }
    }

    # Throughput per HTTP method & route (rpm)
    widget_bar {
      title  = "Throughput per HTTP method & route (rpm)"
      column = 7
      row    = 10
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT rate(count(`http.server.duration`), 1 minute) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' AND `http.method` IS NOT NULL AND `http.route` IS NOT NULL FACET `http.method`, `http.route`"
      }
    }

    # Overall throughput (rpm)
    widget_line {
      title  = "Overall throughput (rpm)"
      column = 1
      row    = 13
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT rate(count(`http.server.duration`), 1 minute) AS `Overall Throughput` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' TIMESERIES"
      }
    }

    # Throughput per instance (rpm)
    widget_line {
      title  = "Throughput per instance (rpm)"
      column = 7
      row    = 13
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT rate(count(`http.server.duration`), 1 minute) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' TIMESERIES"
      }
    }

    # Error rate
    widget_markdown {
      title  = ""
      column = 1
      row    = 16
      width  = 3
      height = 3

      text = "## Error rate\n\nError rate is monitored per the metric `http.server.duration` which ended with an error.\n\nIt corresponds to the ratio of the aggregated amount of requests which have an HTTP status code of above 500 in compared to all requests.\n\nMoreover, the detailed performance can be investigated according to the methods, response codes, instances, routes etc."
    }

    # Error rate per HTTP status code (%)
    widget_pie {
      title  = "Error rate per HTTP status code (%)"
      column = 4
      row    = 16
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT filter(count(`http.server.duration`), WHERE instrumentation.provider = 'opentelemetry' AND numeric(`http.status_code`) >= 500)/count(`http.server.duration`)*100 WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' FACET `http.status_code`"
      }
    }

    # Error rate per HTTP method & route (%)
    widget_bar {
      title  = "Error rate per HTTP method & route (%)"
      column = 7
      row    = 16
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT filter(count(`http.server.duration`), WHERE instrumentation.provider = 'opentelemetry' AND numeric(`http.status_code`) >= 500)/count(`http.server.duration`)*100 WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' AND `http.method` IS NOT NULL AND `http.route` IS NOT NULL FACET `http.method`, `http.route`"
      }
    }

    # Overall error Rate (%)
    widget_line {
      title  = "Overall error rate (%)"
      column = 1
      row    = 19
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT filter(count(`http.server.duration`), WHERE instrumentation.provider = 'opentelemetry' AND numeric(`http.status_code`) >= 500)/count(`http.server.duration`)*100 AS `Overall Error Rate` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' TIMESERIES"
      }
    }

    # Error rate per instance (%)
    widget_line {
      title  = "Error rate per instance (%)"
      column = 7
      row    = 19
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT filter(count(`http.server.duration`), WHERE instrumentation.provider = 'opentelemetry' AND numeric(`http.status_code`) >= 500)/count(`http.server.duration`)*100 WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'httpserver-java' TIMESERIES"
      }
    }
  }

  #######################################
  ### Application Performance (Spans) ###
  #######################################
  page {
    name = "Application Performance (Spans)"

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
