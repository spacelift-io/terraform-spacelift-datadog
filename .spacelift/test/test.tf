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
  extra_tags       = { "env" : "test" }
  exclude_tags = [ "run_note", "run_url" ]
}
