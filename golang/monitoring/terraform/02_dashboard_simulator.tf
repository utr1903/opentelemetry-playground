#################
### Dashboard ###
#################

# Dashboard
resource "newrelic_one_dashboard" "simulator" {
  name = "OTel Playground - Golang - Simulator"

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

    # Average recent CPU utilization for the process across all instances
    widget_billboard {
      title  = "Average recent CPU utilization for the process across all instances"
      column = 5
      row    = 1
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.jvm.cpu.utilization`) AS `Process` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java'"
      }
    }

    # Average recent CPU utilization for the whole system across all instances
    widget_billboard {
      title  = "Average recent CPU utilization for the whole system across all instances"
      column = 9
      row    = 1
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.jvm.system.cpu.utilization`) AS `System` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java'"
      }
    }

    # Average recent CPU utilization for the process across all instances
    widget_line {
      title  = "Average recent CPU utilization for the process across all instances"
      column = 1
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.jvm.cpu.utilization`) AS `Process` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' TIMESERIES"
      }
    }

    # Average recent CPU utilization for the whole system across all instances
    widget_line {
      title  = "Average recent CPU utilization for the whole system across all instances"
      column = 7
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.jvm.system.cpu.utilization`) AS `System` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' TIMESERIES"
      }
    }

    # Recent CPU utilization for the whole system by instance
    widget_line {
      title  = "Recent CPU utilization for the whole system by instance"
      column = 1
      row    = 7
      width  = 12
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.jvm.system.cpu.utilization`) AS `System` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' FACET k8s.pod.name TIMESERIES"
      }
    }

    # Memory Usage & Limits
    widget_markdown {
      title  = ""
      column = 1
      row    = 10
      width  = 4
      height = 3

      text = "## Memory Usage & Limits\n\nMemory usage & limits can be tracked with 4 metrics:\n\n- Measure of initial memory requested\n   - `process.runtime.jvm.memory.init`\n- Measure of memory committed\n   - `process.runtime.jvm.memory.committed`\n- Measure of memory used\n   - `process.runtime.jvm.memory.usage`\n- Measure of max obtainable memory\n   - `process.runtime.jvm.memory.limit`"
    }

    # Average measure of initial memory requested across all instances (bytes)
    widget_billboard {
      title  = "Average measure of initial memory requested across all instances (bytes)"
      column = 5
      row    = 10
      width  = 2
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.init`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' FACET type, pool LIMIT MAX) SELECT sum(`sum`)"
      }
    }

    # Average measure of memory committed across all instances (bytes)
    widget_billboard {
      title  = "Average measure of memory committed across all instances (bytes)"
      column = 7
      row    = 10
      width  = 2
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.committed`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' FACET type, pool LIMIT MAX) SELECT sum(`sum`)"
      }
    }

    # Average measure of memory usage across all instances (bytes)
    widget_billboard {
      title  = "Measure of memory usage across all instances (bytes)"
      column = 9
      row    = 10
      width  = 2
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.usage`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' FACET type, pool LIMIT MAX) SELECT sum(`sum`)"
      }
    }

    # Average measure of max obtainable memory across all instances (bytes)
    widget_billboard {
      title  = "Average measure of max obtainable memory across all instances (bytes)"
      column = 11
      row    = 10
      width  = 2
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.limit`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' FACET type, pool LIMIT MAX) SELECT sum(`sum`)"
      }
    }

    # Aeasure of initial memory requested
    widget_markdown {
      title  = ""
      column = 1
      row    = 13
      width  = 2
      height = 3

      text = "## Measure of initial memory requested"
    }

    # Average measure of initial memory requested by type across all instances (bytes)
    widget_area {
      title  = "Average measure of initial memory requested by type across all instances (bytes)"
      column = 3
      row    = 13
      width  = 5
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.init`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET type TIMESERIES"
      }
    }

    # Average measure of initial memory requested by pool across all instances (bytes)
    widget_area {
      title  = "Average measure of initial memory requested by pool across all instances (bytes)"
      column = 8
      row    = 13
      width  = 5
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.init`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET pool TIMESERIES"
      }
    }

    # Average measure of initial memory requested by instance (bytes)
    widget_line {
      title  = "Average measure of initial memory requested by instance (bytes)"
      column = 8
      row    = 16
      width  = 12
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.init`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' FACET type, pool, k8s.pod.name TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET k8s.pod.name TIMESERIES"
      }
    }

    # Measure of memory committed
    widget_markdown {
      title  = ""
      column = 1
      row    = 19
      width  = 2
      height = 3

      text = "## Measure of memory committed"
    }

    # Average measure of memory committed by type across all instances (bytes)
    widget_area {
      title  = "Average measure of memory committed by type across all instances (bytes)"
      column = 3
      row    = 19
      width  = 5
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.committed`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET type TIMESERIES"
      }
    }

    # Average measure of memory committed by pool across all instances  (bytes)
    widget_area {
      title  = "Average measure of memory committed by pool across all instances (bytes)"
      column = 8
      row    = 19
      width  = 5
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.committed`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET pool TIMESERIES"
      }
    }

    # Average measure of memory committed by instance (bytes)
    widget_line {
      title  = "Average measure of memory committed by instance (bytes)"
      column = 1
      row    = 22
      width  = 12
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.committed`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' FACET type, pool, k8s.pod.name TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET k8s.pod.name TIMESERIES"
      }
    }

    # Measure of memory usage
    widget_markdown {
      title  = ""
      column = 1
      row    = 25
      width  = 2
      height = 3

      text = "## Measure of memory usage"
    }

    # Measure of memory usage by type
    widget_area {
      title  = "Measure of memory usage by type"
      column = 3
      row    = 25
      width  = 5
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.usage`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET type TIMESERIES"
      }
    }

    # Average measure of memory usage by pool across all instances (bytes)
    widget_area {
      title  = "Average measure of memory usage by pool across all instances (bytes)"
      column = 8
      row    = 25
      width  = 5
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.usage`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET pool TIMESERIES"
      }
    }

    # Average measure of memory usage by instance (bytes)
    widget_line {
      title  = "Average measure of memory usage by instance (bytes)"
      column = 1
      row    = 28
      width  = 12
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.usage`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' FACET type, pool, k8s.pod.name TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET k8s.pod.name TIMESERIES"
      }
    }

    # Measure of max obtainable memory
    widget_markdown {
      title  = ""
      column = 1
      row    = 31
      width  = 2
      height = 3

      text = "## Measure of max obtainable memory"
    }

    # Average measure of max obtainable memory by type across all instances (bytes)
    widget_area {
      title  = "Average measure of max obtainable memory by type across all instances (bytes)"
      column = 3
      row    = 31
      width  = 5
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.limit`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET type TIMESERIES"
      }
    }

    # Average measure of max obtainable memory by pool across all instances (bytes)
    widget_area {
      title  = "Average measure of max obtainable memory by pool across all instances (bytes)"
      column = 8
      row    = 31
      width  = 5
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.limit`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' FACET type, pool TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET pool TIMESERIES"
      }
    }

    # Average measure of max obtainable memory by instance (bytes)
    widget_line {
      title  = "Average measure of max obtainable memory by instance (bytes)"
      column = 1
      row    = 34
      width  = 12
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM (FROM Metric SELECT average(`process.runtime.jvm.memory.limit`) AS `sum` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'simulator-java' FACET type, pool, k8s.pod.name TIMESERIES LIMIT MAX) SELECT sum(`sum`) FACET k8s.pod.name TIMESERIES"
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

    # Average latency across all instances (ms)
    widget_billboard {
      title  = "Average latency across all instances (ms)"
      column = 4
      row    = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(http.client.duration) AS `Latency` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local'"
      }
    }

    # Total throughput across all instances  (rpm)
    widget_billboard {
      title  = "Total throughput across all instances (rpm)"
      column = 7
      row    = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT rate(count(http.client.duration), 1 minute) AS `Throughput` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local'"
      }
    }

    # Average error rate across all instances (%)
    widget_billboard {
      title  = "Average error rate across all instances (%)"
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

    # Average latency per HTTP status code across all instances (ms)
    widget_pie {
      title  = "Average latency per HTTP status code across all instances (ms)"
      column = 4
      row    = 4
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`http.client.duration`) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' FACET `http.status_code`"
      }
    }

    # Average latency per HTTP method & URL across all instances (ms)
    widget_bar {
      title  = "Average latency per HTTP method & URL across all instances (ms)"
      column = 7
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`http.client.duration`) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' AND `http.method` IS NOT NULL AND `http.url` IS NOT NULL FACET `http.method`, `http.url`"
      }
    }

    # Average latency across all instances (ms)
    widget_line {
      title  = "Average latency across all instances (ms)"
      column = 1
      row    = 7
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`http.client.duration`) AS `Overall Latency` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' TIMESERIES"
      }
    }

    # Average latency per instance (ms)
    widget_line {
      title  = "Average latency per instance (ms)"
      column = 7
      row    = 7
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`http.client.duration`) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' FACET k8s.pod.name TIMESERIES"
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

    # Total throughput per HTTP status code across all instances (rpm)
    widget_pie {
      title  = "Total throughput per HTTP status code across all instances (rpm)"
      column = 4
      row    = 10
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT rate(count(`http.client.duration`), 1 minute) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' FACET `http.status_code`"
      }
    }

    # Total throughput per HTTP method & URL across all instances (rpm)
    widget_bar {
      title  = "Total throughput per HTTP method & URL across all instances (rpm)"
      column = 7
      row    = 10
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT rate(count(`http.client.duration`), 1 minute) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' AND `http.method` IS NOT NULL AND `http.url` IS NOT NULL FACET `http.method`, `http.url`"
      }
    }

    # Total throughput across all instances (rpm)
    widget_line {
      title  = "Total throughput across all instances (rpm)"
      column = 1
      row    = 13
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT rate(count(`http.client.duration`), 1 minute) AS `Overall Throughput` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' TIMESERIES"
      }
    }

    # Average throughput per instance (rpm)
    widget_line {
      title  = "Average throughput per instance (rpm)"
      column = 7
      row    = 13
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT rate(count(`http.client.duration`), 1 minute) WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' FACET k8s.pod.name TIMESERIES"
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

    # Average error rate per HTTP status code across all instances (%)
    widget_pie {
      title  = "Average error rate per HTTP status code across all instances (%)"
      column = 4
      row    = 16
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT filter(count(`http.client.duration`), WHERE instrumentation.provider = 'opentelemetry' AND numeric(`http.status_code`) >= 500)/count(`http.server.duration`)*100 WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' FACET `http.status_code`"
      }
    }

    # Average error rate per HTTP method & URL across all instances (%)
    widget_bar {
      title  = "Error rate per HTTP method & URL across all instances (%)"
      column = 7
      row    = 16
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT filter(count(`http.client.duration`), WHERE instrumentation.provider = 'opentelemetry' AND numeric(`http.status_code`) >= 500)/count(`http.server.duration`)*100 WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' AND `http.method` IS NOT NULL AND `http.url` IS NOT NULL FACET `http.method`, `http.url`"
      }
    }

    # Average error rate across all instances (%)
    widget_line {
      title  = "Average error rate across all instances (%)"
      column = 1
      row    = 19
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT filter(count(`http.client.duration`), WHERE instrumentation.provider = 'opentelemetry' AND numeric(`http.status_code`) >= 500)/count(`http.server.duration`)*100 AS `Overall Error Rate` WHERE instrumentation.provider = 'opentelemetry' AND service.name = 'simulator-java' AND net.peer.name = 'httpserver-java.otel.svc.cluster.local' TIMESERIES"
      }
    }

    # Average error rate per instance (%)
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
