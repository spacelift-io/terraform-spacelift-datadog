# Spacelift-Datadog metrics integration

Terraform module providing a notification-based integration between Spacelift and Datadog. This particular integration sends metrics to Datadog whenever a run reaches a terminal state.

## Usage

```hcl
module "spacelift_datadog" {
  source = "spacelift-io/datadog/spacelift"

  dd_api_key = var.dd_api_key
  dd_site = "datadoghq.com"
  space_id = "root"
  extra_tags = {"env":"prod"}
  exclude_tags = ["run_note", "run_url"]
}
```

This data allows you to generate dashboards like this one:

![Example dashboard screenshot](https://docs.spacelift.io/assets/screenshots/datadog-screenshot.png)

## Metrics

The following metrics are sent:

- `spacelift.integration.run.count` (counter) - a simple count of runs;
- `spacelift.integration.run.timing` (counter, nanoseconds) - the duration of different run states. In addition to [common tags](#common-tags), this metric is also tagged with the state name, eg. `state:planning`, `state:applying`, etc.;
- `spacelift.integration.run.resources` (counter) - the resources affected by a run. In addition to [common tags](#common-tags), this metric is also tagged with the change type, eg. `change_type:added`, `change_type:changed`, etc.;
- `spacelift.integration.run.policies` (counter) - policy evaluations for the run. In addition to [common tags](#common-tags), this metric is also tagged with the policy type (eg. `policy_type:plan`), policy name (eg. `policy_name:AWS IAM compliance`) and policy outcome (eg. `policy_outcome:allow`). If the policy sets any [flags](https://docs.spacelift.io/concepts/policy/#policy-flags), these are also added to the metric as tags. Note that we do not include notification policies in this metric, to avoid a circular dependency.

## Common tags

Common tags for all metrics are the following:

- `account` (string) : name of the Spacelift account generating the metric;
- `branch` (string): name of the Git branch the run was triggered from;
- `drift_detection` (boolean): whether the run was triggered by drift detection;
- `run_type` (string): type of a run, eg. "tracked", "proposed", etc.;
- `run_url` (string): link to the run that generated the metric;
- `final_state` (string): the terminal state of the run, eg. "finished", "failed", etc.;
- `space` (string): name of the Spacelift space the run belongs to;
- `stack` (string): name of the Spacelift stack the run belongs to;
- `worker_pool` (string): name of the Spacelift worker pool the run was executed on - for the public worker pool this value is always `public`;

You can exclude tags using the `exclude_tags` variable, which allows a user to reduce the number of tags added to the metrics.

## Release

You need to bump the version in `.spacelift/config.yml` file. 
```yaml
module_version: 0.2.3
```

Then, the module will be published in `spacelift.io/spacelift-io/datadog/spacelift`.

You need to create the new tag to bump the version on the Terraform registry side.
```
git tag -a -m 'Description...' v0.2.3
git push --tag
```