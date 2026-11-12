resource "aws_ec2_transit_gateway" "this" {
  description                     = var.description
  amazon_side_asn                 = var.amazon_side_asn
  default_route_table_association = var.enable_default_route_table_association ? "enable" : "disable"
  default_route_table_propagation = var.enable_default_route_table_propagation ? "enable" : "disable"

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_flow_log" "this" {
  log_destination      = var.flow_logs_s3_bucket_arn
  log_destination_type = "s3"
  transit_gateway_id   = aws_ec2_transit_gateway.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-flow-logs"
  })
}

resource "aws_ssm_parameter" "transit_gateway_id" {
  name        = var.ssm_parameter_name
  description = "Transit Gateway ID for ${var.name}"
  type        = "String"
  value       = aws_ec2_transit_gateway.this.id

  tags = var.tags
}

resource "aws_ram_resource_share" "this" {
  name                      = "${var.name}-share"
  allow_external_principals = false

  tags = var.tags
}

resource "aws_ram_resource_association" "this" {
  resource_arn       = aws_ec2_transit_gateway.this.arn
  resource_share_arn = aws_ram_resource_share.this.arn
}

resource "aws_ram_principal_association" "organization_units" {
  for_each = toset(var.ram_principals)

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.this.arn
}
