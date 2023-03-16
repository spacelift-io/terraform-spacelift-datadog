variable "dd_api_key" {
    type        = string
    description = "Datadog API key to use for sending metrics."
    sensitive   = true
}

variable "dd_site" {
  type        = string
  description = "Datadog site (hostname) to send metrics to."
  default     = "datadoghq.com"

  validation {
    condition = contains(
      [
        "datadoghq.com",
        "datadoghq.eu",
        "us3.datadoghq.com",
        "us5.datadoghq.com",
      ],
      var.dd_site,
    )

    error_message = "Invalid Datadog site. Valid values are datadoghq.com, datadoghq.eu, us3.datadoghq.com, us5.datadoghq.com."
  }
}

variable "integration_name" {
  type = string
  description = "Name of the integration to create."
  default = "Datadog metrics"
}

variable "space_id" {
  type        = string
  description = "ID of the Spacelift space to create notitications for."
  default     = "root"
}

variable "extra_tags" {
  type = map(string)
  description = "Extra tags to add to the Datadog metrics, must be in key:value format"
  default = {}
}
