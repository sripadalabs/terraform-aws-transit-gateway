output "transit_gateway_id" {
  description = "ID of the Transit Gateway."
  value       = aws_ec2_transit_gateway.this.id
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway."
  value       = aws_ec2_transit_gateway.this.arn
}

output "ssm_parameter_name" {
  description = "Name of the SSM parameter containing the Transit Gateway ID."
  value       = aws_ssm_parameter.transit_gateway_id.name
}

output "ssm_parameter_arn" {
  description = "ARN of the SSM parameter containing the Transit Gateway ID."
  value       = aws_ssm_parameter.transit_gateway_id.arn
}

output "ram_resource_share_arn" {
  description = "ARN of the AWS RAM resource share."
  value       = aws_ram_resource_share.this.arn
}

output "flow_log_id" {
  description = "ID of the Transit Gateway Flow Log."
  value       = aws_flow_log.this.id
}
