terraform {
  required_providers {
    spacelift = {
      source = "spacelift-io/spacelift"
    }
  }
}


provider "spacelift" {}

variable "spacelift_run_id" {}

module "datadog-metrics" {
  source = "../../"

  dd_api_key       = "fake-key"
  integration_name = "Datadog metrics, run ${var.spacelift_run_id}"
  space_id         = "public-modules-01GVNH2CJKSKHRSMDPBMQ3WZT9"

  # Static tags (added via webhook labels)
  extra_tags = { "env" : "test" }

  # Dynamic tags (Rego expressions referencing Spacelift data)
  extra_dynamic_tags = {
    "commit_hash" = "[input.run_updated.run.commit.hash]"
  }

  exclude_tags = ["run_note", "run_url"]
}
