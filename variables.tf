variable "name" {
  description = "Name used for the Transit Gateway, RAM share, and related resources."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "The name must not be empty."
  }
}

variable "description" {
  description = "Description for the Transit Gateway."
  type        = string
  default     = null
}

variable "amazon_side_asn" {
  description = "Private Autonomous System Number (ASN) for the Transit Gateway."
  type        = number
  default     = 64512

  validation {
    condition = (
      var.amazon_side_asn == floor(var.amazon_side_asn) && (
        (var.amazon_side_asn >= 64512 && var.amazon_side_asn <= 65534) ||
        (var.amazon_side_asn >= 4200000000 && var.amazon_side_asn <= 4294967294)
      )
    )
    error_message = "amazon_side_asn must be in the private ASN range 64512-65534 or 4200000000-4294967294."
  }
}

variable "enable_default_route_table_association" {
  description = "Enable automatic association of attachments with the default Transit Gateway route table."
  type        = bool
  default     = false
}

variable "enable_default_route_table_propagation" {
  description = "Enable automatic propagation of attachment routes to the default Transit Gateway route table."
  type        = bool
  default     = false
}

variable "enable_auto_accept_shared_attachments" {
  description = "Whether resource attachment requests are automatically accepted."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Whether DNS support is enabled."
  type        = bool
  default     = true
}

variable "enable_vpn_ecmp_support" {
  description = "Whether VPN ECMP support is enabled."
  type        = bool
  default     = true
}

variable "flow_logs_s3_bucket_arn" {
  description = "ARN of the S3 bucket that receives Transit Gateway Flow Logs."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:s3:::[^/]+$", var.flow_logs_s3_bucket_arn))
    error_message = "flow_logs_s3_bucket_arn must be an S3 bucket ARN without an object key or prefix."
  }
}

variable "ssm_parameter_name" {
  description = "Name of the SSM String parameter in which to store the Transit Gateway ID."
  type        = string
  default     = "/network/transit-gateway/id"

  validation {
    condition     = length(trimspace(var.ssm_parameter_name)) > 0
    error_message = "The SSM parameter name must not be empty."
  }
}

variable "ram_principals" {
  description = "AWS Organizations Organizational Unit ARNs to associate with the RAM share."
  type        = list(string)

  # validation {
  #   condition = length(var.ram_principals) > 0 && alltrue([
  #     for principal in var.ram_principals :
  #     can(regex("^arn:[^:]+:organizations::[0-9]{12}:ou/o-[^/]+/ou-[^/]+$", principal))
  #   ])
  #   error_message = "ram_principals must contain one or more AWS Organizations OU ARNs."
  # }
}

variable "tags" {
  description = "Tags applied to the Transit Gateway, Flow Log, SSM parameter, and RAM share."
  type        = map(string)
  default     = {}
}
