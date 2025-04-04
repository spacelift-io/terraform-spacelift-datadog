resource "spacelift_named_webhook" "datadog-metrics" {
  count    = var.send_metrics ? 1 : 0
  name     = "${var.integration_name} metrics (${var.dd_site})"
  space_id = var.space_id

  endpoint = "https://api.${var.dd_site}/api/v2/series"
  enabled  = true

  labels = flatten(concat(
    ["datadog", "ddmetrics"],
    [for k, v in var.extra_tags : "${k}:${v}"],
  ))
}

resource "spacelift_named_webhook_secret_header" "datadog-api-key" {
  count      = var.send_metrics ? 1 : 0
  webhook_id = spacelift_named_webhook.datadog-metrics[count.index].id
  key        = "DD-API-KEY"
  value      = var.dd_api_key
}

resource "spacelift_named_webhook" "datadog-logs" {
  count    = var.send_logs ? 1 : 0
  name     = "${var.integration_name} logs (${var.dd_site})"
  space_id = var.space_id

  endpoint = "https://http-intake.logs.${var.dd_site}/api/v2/logs"
  enabled  = true

  labels = flatten(concat(
    ["datadog", "ddlogs"],
    [for k, v in var.extra_tags : "${k}:${v}"],
  ))
}

resource "spacelift_named_webhook_secret_header" "datadog-logs-api-key" {
  count      = var.send_logs ? 1 : 0
  webhook_id = spacelift_named_webhook.datadog-logs[count.index].id
  key        = "DD-API-KEY"
  value      = var.dd_api_key
}