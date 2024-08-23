package spacelift

# We will send a webhook to Datadog for each run that reaches a terminal state.
# This means that the data will only be generated for runs that have finished,
# and not for runs that are still in progress. Additionally, no data will be
# generated for runs that never saw any action, i.e. runs that were created and
# canceled, though approval policy failures will be reported.
terminal := {"FAILED", "FINISHED", "DISCARDED", "STOPPED"}

run_state := input.run_updated.run.state

# We need this because the Go JSON parser can't do a round trip with an int64.
timestamp := json.unmarshal(sprintf("%.0f", [input.run_updated.run.updated_at / 1e9]))

# https://docs.datadoghq.com/api/latest/metrics/#submit-metrics
webhook[{"endpoint_id": endpoint_id, "payload": payload}] {
	# Send the webhook to any endpoint labeled as "ddmetrics".
	endpoint := input.webhook_endpoints[_]
	endpoint.labels[_] == "ddmetrics"
	endpoint_id := endpoint.id

	# Only send the webhook if the run reached a terminal state.
	run_state == terminal[_]

	payload := {"series": array.concat(
		[
			run_count(endpoint.labels),
			resources("added", endpoint.labels),
			resources("changed", endpoint.labels),
			resources("deleted", endpoint.labels),
			resources("replaced", endpoint.labels),
		],
		array.concat(
			policies(endpoint.labels),
			state_timings(endpoint.labels),
		),
	)}
}

# Metric definition for spacelift.integration.run.count.
#
# This is a simple run count, broken down by the standard tags.
run_count(extra_tags) = {
	"metric": "spacelift.integration.run.count",
	"type": 1, # count
	"points": [{
		"timestamp": timestamp,
		"value": 1,
	}],
	"tags": tags(extra_tags),
	"unit": "job",
}

# Metric definition for spacelift.integration.run.resources.
#
# It represents a count of changes of a given type, broken down by the standard
# tags and the change type.
resources(type, extra_tags) = {
	"metric": "spacelift.integration.run.resources",
	"type": 1, # count
	"points": [{
		"timestamp": timestamp,
		"value": count([change |
    		change := input.run_updated.run.changes[_]
    		change.phase == "plan"
    		contains(change.action, type)
		]),
	}],
	"tags": array.concat(tags(extra_tags), [sprintf("change_type:%s", [type])]),
	"unit": "operation",
}

policies(extra_tags) = [metric |
	receipt := input.run_updated.policy_receipts[_]

	receipt_tags := array.concat(receipt.flags, [
		sprintf("policy_name:%s", [receipt.name]),
		sprintf("policy_outcome:%s", [receipt.outcome]),
		sprintf("policy_type:%s", [lower(receipt.type)]),
	])

	metric := {
		"metric": "spacelift.integration.run.policies",
		"type": 1, # count
		"points": [{
			"timestamp": timestamp,
			"value": 1,
		}],
		"tags": array.concat(tags(extra_tags), receipt_tags),
		"unit": "policy",
	}
]

# Metric definition for spacelift.integration.run.timing.
#
# It is the duration of each phase of the run, broken down by the standard tags
# and the phase name.
# 
# State timings reported by this webhook will be assigned to the time when the
# run is last updated (i.e. when it reaches the terminal state), not when each
# of the respective phases actually took place. In most cases this should be
# good enough but a more granular approach is possible if needed.
state_timings(extra_tags) = [metric |
	state_timing := input.run_updated.timing[_]
	metric := {
		"metric": "spacelift.integration.run.timing",
		"type": 1, # count
		"points": [{
			"timestamp": timestamp,
			"value": state_timing.duration,
		}],
		"tags": array.concat(tags(extra_tags), [sprintf("state:%s", [lower(state_timing.state)])]),
		"unit": "nanoseconds",
	}
] 

tags(extra_tags) = array.concat([tag | tag := extra_tags[_]; contains(tag, ":")], [
	sprintf("account:%s", [input.account.name]),
	sprintf("branch:%s", [input.run_updated.run.commit.branch]),
	sprintf("drift_detection:%s", [input.run_updated.run.drift_detection]),
	sprintf("run_note:%s", [input.run_updated.note]),
	sprintf("run_type:%s", [lower(input.run_updated.run.type)]),
	sprintf("final_state:%s", [lower(run_state)]),
	sprintf("space:%s", [lower(input.run_updated.stack.space.id)]),
	sprintf("stack:%s", [lower(input.run_updated.stack.id)]),
    sprintf("worker_pool:%s", [worker_pool]),
])

default worker_pool = "public"

worker_pool = name {
	name := input.run_updated.stack.worker_pool.name
}

# Only sample the webhook if the run reached a terminal state, and some metrics
# have been collected.
sample { run_state == terminal[_] }
