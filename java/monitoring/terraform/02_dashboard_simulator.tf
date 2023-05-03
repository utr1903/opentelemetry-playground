#################
### Dashboard ###
#################

# Dashboard
resource "newrelic_one_dashboard" "simulator" {
  name = "OTel Playground - Simulator"

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
        query      = "FROM Metric SELECT average(`process.runtime.jvm.cpu.utilization`) AS `Process` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java'"
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
        query      = "FROM Metric SELECT average(`process.runtime.jvm.system.cpu.utilization`) AS `System` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java'"
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
        query      = "FROM Metric SELECT average(`process.runtime.jvm.cpu.utilization`) AS `Process` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' TIMESERIES"
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
        query      = "FROM Metric SELECT average(`process.runtime.jvm.system.cpu.utilization`) AS `System` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' TIMESERIES"
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
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.init`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET type, pool LIMIT MAX) SELECT sum(`sum`)"
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
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.committed`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET type, pool LIMIT MAX) SELECT sum(`sum`)"
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
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.usage`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET type, pool LIMIT MAX) SELECT sum(`sum`)"
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
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.limit`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET type, pool LIMIT MAX) SELECT sum(`sum`)"
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
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.init`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET type TIMESERIES"
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
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.init`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET pool TIMESERIES"
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
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.committed`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET type TIMESERIES"
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
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.committed`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET pool TIMESERIES"
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
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.usage`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET type TIMESERIES"
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
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.usage`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET pool TIMESERIES"
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
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.limit`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET type TIMESERIES"
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
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.limit`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET pool TIMESERIES"
      }
    }
  }

  #####################################################
  ### Application Performance HTTP Server (Metrics) ###
  #####################################################
  page {
    name = "Application Performance HTTP Server (Metrics)"

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
        query      = "FROM Metric SELECT average(http.client.duration) AS `Latency` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local'"
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
        query      = "FROM Metric SELECT rate(count(http.client.duration), 1 minute) AS `Throughput` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local'"
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
        query      = "FROM Metric SELECT filter(count(http.client.duration), WHERE instrumentation.provider = 'opentelemetry' AND numeric(http.status_code) >= 500)/count(http.client.duration)*100 AS `Error rate` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local'"
      }
    }

    # Latency
    widget_markdown {
      title  = ""
      column = 1
      row    = 4
      width  = 3
      height = 3

      text = "## Latency\n\nLatency is monitored per the metric `http.client.duration` which represents a histogram.\n\nIt corresponds to the aggregated client request duration to an external HTTP server.\n\nMoreover, the detailed performance can be investigated according to the methods, response codes, instances, URLs etc."
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
        query      = "FROM Metric SELECT average(`http.client.duration`) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' FACET `http.status_code`"
      }
    }

    # Latency per HTTP method & URL (ms)
    widget_bar {
      title  = "Latency per HTTP method & URL (ms)"
      column = 7
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`http.client.duration`) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' AND `http.method` IS NOT NULL AND `http.url` IS NOT NULL FACET `http.method`, `http.url`"
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
        query      = "FROM Metric SELECT average(`http.client.duration`) AS `Overall Latency` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' TIMESERIES"
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
        query      = "FROM Metric SELECT average(`http.client.duration`) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' TIMESERIES"
      }
    }

    # Throughput
    widget_markdown {
      title  = ""
      column = 1
      row    = 10
      width  = 3
      height = 3

      text = "## Throughput\n\nThroughput is monitored per the rate of change in the metric `http.client.duration` in format of request per minute.\n\nIt corresponds to the aggregated amount of requests which are performed against an external HTTP server in a minute.\n\nMoreover, the detailed performance can be investigated according to the methods, response codes, instances, URLs etc."
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
        query      = "FROM Metric SELECT rate(count(`http.client.duration`), 1 minute) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' FACET `http.status_code`"
      }
    }

    # Throughput per HTTP method & URL (rpm)
    widget_bar {
      title  = "Throughput per HTTP method & URL (rpm)"
      column = 7
      row    = 10
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT rate(count(`http.client.duration`), 1 minute) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' AND `http.method` IS NOT NULL AND `http.url` IS NOT NULL FACET `http.method`, `http.url`"
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
        query      = "FROM Metric SELECT rate(count(`http.client.duration`), 1 minute) AS `Overall Throughput` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' TIMESERIES"
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
        query      = "FROM Metric SELECT rate(count(`http.client.duration`), 1 minute) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' TIMESERIES"
      }
    }

    # Error rate
    widget_markdown {
      title  = ""
      column = 1
      row    = 16
      width  = 3
      height = 3

      text = "## Error rate\n\nError rate is monitored per the metric `http.client.duration` which ended with an error.\n\nIt corresponds to the ratio of the aggregated amount of requests which have an HTTP status code of above 500 in compared to all requests.\n\nMoreover, the detailed performance can be investigated according to the methods, response codes, instances, URLs etc."
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
        query      = "FROM Metric SELECT filter(count(`http.client.duration`), WHERE instrumentation.provider = 'opentelemetry' AND numeric(`http.status_code`) >= 500)/count(`http.server.duration`)*100 WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' FACET `http.status_code`"
      }
    }

    # Error rate per HTTP method & URL (%)
    widget_bar {
      title  = "Error rate per HTTP method & URL (%)"
      column = 7
      row    = 16
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT filter(count(`http.client.duration`), WHERE instrumentation.provider = 'opentelemetry' AND numeric(`http.status_code`) >= 500)/count(`http.server.duration`)*100 WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' AND `http.method` IS NOT NULL AND `http.url` IS NOT NULL FACET `http.method`, `http.url`"
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
        query      = "FROM Metric SELECT filter(count(`http.client.duration`), WHERE instrumentation.provider = 'opentelemetry' AND numeric(`http.status_code`) >= 500)/count(`http.server.duration`)*100 AS `Overall Error Rate` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' TIMESERIES"
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
        query      = "FROM Metric SELECT filter(count(`http.client.duration`), WHERE instrumentation.provider = 'opentelemetry' AND numeric(`http.status_code`) >= 500)/count(`http.server.duration`)*100 WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' TIMESERIES"
      }
    }
  }

  ###################################################
  ### Application Performance HTTP Server (Spans) ###
  ###################################################
  page {
    name = "Application Performance HTTP Server (Spans)"

    # Simulator -> HTTP server
    widget_markdown {
      title  = "Simulator -> HTTP server"
      column = 1
      row    = 1
      width  = 3
      height = 3

      text = "## Simulator -> HTTP Server"
    }

    # Latency (ms)
    widget_line {
      title  = "Latency (ms)"
      column = 4
      row    = 1
      width  = 9
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Span SELECT average(duration.ms) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND span.kind = 'client' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' TIMESERIES"
      }
    }

    # Throughput (rpm)
    widget_line {
      title  = "Throughput (rpm)"
      column = 1
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Span SELECT rate(count(*), 1 minute) AS `Throughput` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND span.kind = 'client' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' TIMESERIES"
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
        query      = "FROM Span SELECT filter(count(*), WHERE instrumentation.provider = 'opentelemetry' AND otel.status_code = 'ERROR')/count(*)*100 AS `Error rate` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND span.kind = 'client' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' TIMESERIES"
      }
    }
  }
}
