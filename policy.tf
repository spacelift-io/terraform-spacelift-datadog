locals {
  common_tags = {
    "account":           "[input.account.name]",
    "branch":            "[input.run_updated.run.commit.branch]",
    "drift_detection":   "[input.run_updated.run.drift_detection]",
    "run_note":          "[input.run_updated.note]",
    "run_type":          "[lower(input.run_updated.run.type)]",
    "run_url":           "[input.run_updated.urls.run]",
    "final_state":       "[lower(run_state)]",
    "space":             "[lower(input.run_updated.stack.space.id)]",
    "stack":             "[lower(input.run_updated.stack.id)]",
    "terraform_version": "[input.run_updated.stack.terraform_version]",
    "triggered_by":      "[input.run_updated.run.triggered_by]",
    "worker_pool":       "[worker_pool]",
  }

  all_tags = merge(local.common_tags, var.extra_dynamic_tags)
}

resource "spacelift_policy" "datadog-metrics" {
  name     = "${var.integration_name} (${var.dd_site})"
  type     = "NOTIFICATION"
  space_id = var.space_id

  body = templatefile("${path.module}/assets/policy.rego.tpl", {
    common_tags = {for k, v in local.common_tags : k => v if !contains(var.exclude_tags, k)},
  })
  labels = ["ddmetrics"]
}
