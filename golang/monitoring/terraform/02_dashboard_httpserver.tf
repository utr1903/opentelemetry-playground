#################
### Dashboard ###
#################

# Dashboard
resource "newrelic_one_dashboard" "httpserver" {
  name = "OTel Playground - Golang - HTTP Server"

  ###########################
  ### Runtime Performance ###
  ###########################
  page {
    name = "Runtime Performance"

    # Go Routines
    widget_markdown {
      title  = "Go routines"
      column = 1
      row    = 1
      width  = 4
      height = 3

      text = "## Go routines\n\nThe following metric is considered:\n\n- Number of goroutines that currently exist\n   - `process.runtime.go.goroutines`"
    }

    # Average number of Go routines across all instances
    widget_billboard {
      title  = "Average number of Go routines across all instances"
      column = 5
      row    = 1
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.go.goroutines`) AS `Routines` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang'"
      }
    }

    # Average number of Go routines per instance
    widget_bar {
      title  = "Average number of Go routines per instance"
      column = 9
      row    = 1
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.go.goroutines`) WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' FACET service.instance.id"
      }
    }

    # Average number of Go routines across all instances
    widget_line {
      title  = "Average number of Go routines across all instances"
      column = 1
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.go.goroutines`) AS `Routines` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' TIMESERIES"
      }
    }

    # Average number of Go routines per instance
    widget_line {
      title  = "Average number of Go routines per instance"
      column = 7
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.go.goroutines`) WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' FACET service.instance.id TIMESERIES"
      }
    }

    # Garbage collection cycles
    widget_markdown {
      title  = "Garbage collection cycles"
      column = 1
      row    = 7
      width  = 4
      height = 3

      text = "## Garbage collection cycles\n\nThe following metric is considered:\n\n- Number of completed garbage collection cycles\n   - `process.runtime.go.gc.count`"
    }

    # Average number of garbage collection cycle across all instances
    widget_billboard {
      title  = "Average number of garbage collection cycle across all instances"
      column = 5
      row    = 7
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.go.gc.count`) AS `Routines` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang'"
      }
    }

    # Average number of garbage collection cycle per instance
    widget_bar {
      title  = "Average number of garbage collection cycle per instance"
      column = 9
      row    = 7
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.go.gc.count`) WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' FACET service.instance.id"
      }
    }

    # Average number of garbage collection cycle across all instances
    widget_line {
      title  = "Average number of garbage collection cycle across all instances"
      column = 1
      row    = 10
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.go.gc.count`) AS `Routines` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' TIMESERIES"
      }
    }

    # Average number of Go routines per instance
    widget_line {
      title  = "Average number of Go routines per instance"
      column = 7
      row    = 10
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.go.gc.count`) WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' FACET service.instance.id TIMESERIES"
      }
    }

    # Memory objects
    widget_markdown {
      title  = "Memory objects"
      column = 1
      row    = 13
      width  = 4
      height = 3

      text = "## Memory objects\n\nThe following metrics are considered:\n\n- Number of allocated heap objects\n   - `process.runtime.go.mem.heap_objects`\n- Number of live objects is the number of cumulative Mallocs - Frees\n   - `process.runtime.go.mem.live_objects`"
    }

    # Average number of memory objects across all instances
    widget_billboard {
      title  = "Average number of memory objects across all instances"
      column = 5
      row    = 13
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.go.mem.heap_objects`) AS `Heap`, average(`process.runtime.go.mem.live_objects`) AS `Live` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang'"
      }
    }

    # Average number of memory objects per instance
    widget_bar {
      title  = "Average number of memory objects per instance"
      column = 9
      row    = 13
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.go.mem.heap_objects`) AS `Heap`, average(`process.runtime.go.mem.live_objects`) AS `Live` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' FACET service.instance.id"
      }
    }

    # Average number of memory objects across all instances
    widget_area {
      title  = "Average number of memory objects across all instances"
      column = 1
      row    = 16
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.go.mem.heap_objects`) AS `Heap`, average(`process.runtime.go.mem.live_objects`) AS `Live` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' TIMESERIES"
      }
    }

    # Average number of memory objects per instance
    widget_line {
      title  = "Average number of memory objects per instance"
      column = 7
      row    = 16
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.go.mem.heap_objects`) AS `Heap`, average(`process.runtime.go.mem.live_objects`) AS `Live` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' FACET service.instance.id TIMESERIES"
      }
    }

    # Memory consumption (bytes)
    widget_markdown {
      title  = "Memory consumption (bytes)"
      column = 1
      row    = 19
      width  = 4
      height = 3

      text = "## Memory consumption\n\nThe following metrics are considered:\n\n- Bytes of allocated heap objects\n   - `process.runtime.go.mem.heap_alloc`\n- Bytes in idle (unused) spans\n   - `process.runtime.go.mem.heap_idle`\n- Bytes in in-use spans\n   - `process.runtime.go.mem.heap_inuse`\n- Bytes of idle spans whose physical memory has been returned to the OS\n   - `process.runtime.go.mem.heap_released`\n- Bytes of heap memory obtained from the OS\n   - `process.runtime.go.mem.heap_sys`"
    }

    # Average memory consumption across all instances (bytes)
    widget_billboard {
      title  = "Average memory consumption across all instances (bytes)"
      column = 5
      row    = 19
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.go.mem.heap_alloc`) AS `heap_alloc`, average(`process.runtime.go.mem.heap_idle`) AS `heap_idle`, average(`process.runtime.go.mem.heap_inuse`) AS `heap_inuse`, average(`process.runtime.go.mem.heap_released`) AS `heap_released`, average(`process.runtime.go.mem.heap_sys`) AS `heap_sys` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang'"
      }
    }

    # Average memory consumption per instance (bytes)
    widget_bar {
      title  = "Average memory consumption per instance (bytes)"
      column = 9
      row    = 19
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.go.mem.heap_alloc`) AS `heap_alloc`, average(`process.runtime.go.mem.heap_idle`) AS `heap_idle`, average(`process.runtime.go.mem.heap_inuse`) AS `heap_inuse`, average(`process.runtime.go.mem.heap_released`) AS `heap_released`, average(`process.runtime.go.mem.heap_sys`) AS `heap_sys` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' FACET service.instance.id"
      }
    }

    # Average memory consumption across all instances (bytes)
    widget_area {
      title  = "Average memory consumption across all instances (bytes)"
      column = 1
      row    = 22
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.go.mem.heap_alloc`) AS `heap_alloc`, average(`process.runtime.go.mem.heap_idle`) AS `heap_idle`, average(`process.runtime.go.mem.heap_inuse`) AS `heap_inuse`, average(`process.runtime.go.mem.heap_released`) AS `heap_released`, average(`process.runtime.go.mem.heap_sys`) AS `heap_sys` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' TIMESERIES"
      }
    }

    # Average memory consumption per instance (bytes)
    widget_line {
      title  = "Average memory consumption per instance (bytes)"
      column = 7
      row    = 22
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`process.runtime.go.mem.heap_alloc`) AS `heap_alloc`, average(`process.runtime.go.mem.heap_idle`) AS `heap_idle`, average(`process.runtime.go.mem.heap_inuse`) AS `heap_inuse`, average(`process.runtime.go.mem.heap_released`) AS `heap_released`, average(`process.runtime.go.mem.heap_sys`) AS `heap_sys` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' FACET service.instance.id TIMESERIES"
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

    # Average latency across all instances (ms)
    widget_billboard {
      title  = "Average latency across all instances (ms)"
      column = 4
      row    = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(http.server.duration) AS `Latency` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang'"
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
        query      = "FROM Metric SELECT rate(count(http.server.duration), 1 minute) AS `Throughput` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang'"
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
        query      = "FROM Metric SELECT filter(count(http.server.duration), WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND numeric(http.status_code) >= 500)/count(http.server.duration)*100 AS `Error rate` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang'"
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

    # Average latency per HTTP status code across all instances (ms)
    widget_billboard {
      title  = "Average latency per HTTP status code across all instances (ms)"
      column = 4
      row    = 4
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`http.server.duration`) AS `Latency` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' FACET `http.status_code`"
      }
    }

    # Average latency per HTTP method & route across all instances (ms)
    widget_bar {
      title  = "Average latency per HTTP method & route across all instances (ms)"
      column = 7
      row    = 4
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT average(`http.server.duration`) WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' AND `http.method` IS NOT NULL FACET `http.method`"
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
        query      = "FROM Metric SELECT average(`http.server.duration`) AS `Overall Latency` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' TIMESERIES"
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
        query      = "FROM Metric SELECT average(`http.server.duration`) WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' FACET k8s.pod.name TIMESERIES"
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

    # Total throughput per HTTP status code across all instances (rpm)
    widget_billboard {
      title  = "Total throughput per HTTP status code across all instances (rpm)"
      column = 4
      row    = 10
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT rate(count(`http.server.duration`), 1 minute) WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' FACET `http.status_code`"
      }
    }

    # Total throughput per HTTP method & route across all instances (rpm)
    widget_bar {
      title  = "Total throughput per HTTP method & route across all instances (rpm)"
      column = 7
      row    = 10
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT rate(count(`http.server.duration`), 1 minute) WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' AND `http.method` IS NOT NULL FACET `http.method`"
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
        query      = "FROM Metric SELECT rate(count(`http.server.duration`), 1 minute) AS `Overall Throughput` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' TIMESERIES"
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
        query      = "FROM Metric SELECT rate(count(`http.server.duration`), 1 minute) WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' FACET k8s.pod.name TIMESERIES"
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

    # Average error rate per HTTP status code across all instances (%)
    widget_billboard {
      title  = "Average error rate per HTTP status code across all instances (%)"
      column = 4
      row    = 16
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT filter(count(`http.server.duration`), WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND numeric(`http.status_code`) >= 500)/count(`http.server.duration`)*100 WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' FACET `http.status_code`"
      }
    }

    # Average error rate per HTTP method & route across all instances (%)
    widget_bar {
      title  = "Error rate per HTTP method & route across all instances (%)"
      column = 7
      row    = 16
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = "FROM Metric SELECT filter(count(`http.server.duration`), WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND numeric(`http.status_code`) >= 500)/count(`http.server.duration`)*100 WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' AND `http.method` IS NOT NULL FACET `http.method`"
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
        query      = "FROM Metric SELECT filter(count(`http.server.duration`), WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND numeric(`http.status_code`) >= 500)/count(`http.server.duration`)*100 AS `Overall Error Rate` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' TIMESERIES"
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
        query      = "FROM Metric SELECT filter(count(`http.server.duration`), WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND numeric(`http.status_code`) >= 500)/count(`http.server.duration`)*100 WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' FACET k8s.pod.name TIMESERIES"
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
        query      = "FROM Span SELECT average(duration.ms) AS `Response time` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' AND span.kind = 'server' TIMESERIES"
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
        query      = "FROM Span SELECT rate(count(*), 1 minute) AS `Throughput` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' AND span.kind = 'server' TIMESERIES"
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
        query      = "FROM Span SELECT filter(count(*), WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND otel.status_code = 'ERROR')/count(*)*100 AS `Error rate` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' AND span.kind = 'server' TIMESERIES"
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
        query      = "FROM Span SELECT average(duration.ms) AS `DB time` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' AND span.kind = 'client' AND net.peer.name = 'mysql.otel.svc.cluster.local' TIMESERIES"
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
        query      = "FROM Span SELECT rate(count(*), 1 minute) AS `Throughput` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' AND span.kind = 'client' AND net.peer.name = 'mysql.otel.svc.cluster.local' TIMESERIES"
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
        query      = "FROM Span SELECT filter(count(*), WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND otel.status_code = 'ERROR')/count(*)*100 AS `Error rate` WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' AND span.kind = 'client' AND net.peer.name = 'mysql.otel.svc.cluster.local' TIMESERIES"
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
        query      = "FROM Span SELECT max(duration.ms) WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' AND span.kind = 'client' AND net.peer.name = 'mysql.otel.svc.cluster.local' FACET db.name, db.sql.table, db.operation"
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
        query      = "FROM Span SELECT rate(count(*), 1 minute) WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' AND span.kind = 'client' AND net.peer.name = 'mysql.otel.svc.cluster.local' FACET db.name, db.sql.table, db.operation"
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
        query      = "FROM Span SELECT filter(count(*), WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND otel.status_code = 'ERROR')/count(*)*100 WHERE instrumentation.provider = 'opentelemetry' AND k8s.cluster.name = '${var.cluster_name}' AND service.name = 'httpserver-golang' AND span.kind = 'client' AND net.peer.name = 'mysql.otel.svc.cluster.local' FACET db.name, db.sql.table, db.operation"
      }
    }
  }
}
