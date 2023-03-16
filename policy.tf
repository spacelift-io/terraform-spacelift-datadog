resource "spacelift_policy" "datadog-metrics" {
  name     = "Datadog metrics (${var.dd_site})"
  type     = "NOTIFICATION"
  space_id = var.space_id

  body   = file("${path.module}/assets/policy.rego")
  labels = ["ddmetrics"]
}
