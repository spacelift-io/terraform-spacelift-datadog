resource "spacelift_named_webhook" "datadog-metrics" {
  name     = "Datadog metrics (${var.dd_site})"
  space_id = var.space_id

  endpoint = "https://api.${var.dd_site}/api/v2/series"
  enabled  = true

  labels = flatten(
    ["datadog", "ddmetrics"],
    [for k, v in var.extra_tags : "${k}:${v}"],
  )
}

resource "spacelift_named_webhook_secret_header" "datadog-api-key" {
  webhook_id = spacelift_named_webhook.datadog-metrics.id
  key        = "DD-API-KEY"
  value      = var.dd_api_key
}
