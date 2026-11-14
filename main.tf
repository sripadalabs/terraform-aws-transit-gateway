locals {
  flow_log_format = join(" ", [
    "$${version} $${resource-type} $${account-id} $${region} $${tgw-id} $${tgw-attachment-id} $${tgw-pair-attachment-id}",
    "$${tgw-src-vpc-account-id} $${tgw-src-vpc-id} $${tgw-src-subnet-id} $${tgw-src-eni} $${tgw-src-az-id} $${srcaddr} $${srcport} $${pkt-src-aws-service}",
    "$${tgw-dst-vpc-account-id} $${tgw-dst-vpc-id} $${tgw-dst-subnet-id} $${tgw-dst-eni} $${tgw-dst-az-id} $${dstaddr} $${dstport} $${pkt-dst-aws-service}",
    "$${protocol} $${type} $${flow-direction} $${tcp-flags}",
    "$${packets} $${bytes} $${packets-lost-no-route} $${packets-lost-blackhole} $${packets-lost-mtu-exceeded} $${packets-lost-ttl-expired}",
    "$${start} $${end} $${log-status}"
    ])
}

resource "aws_ec2_transit_gateway" "this" {
  description                     = var.description
  amazon_side_asn                 = var.amazon_side_asn
  default_route_table_association = var.enable_default_route_table_association ? "enable" : "disable"
  default_route_table_propagation = var.enable_default_route_table_propagation ? "enable" : "disable"
  auto_accept_shared_attachments  = var.enable_auto_accept_shared_attachments ? "enable" : "disable"
  dns_support                       = var.enable_dns_support ? "enable" : "disable"
  vpn_ecmp_support                  = var.enable_vpn_ecmp_support ? "enable" : "disable"

  tags = merge(var.tags, {
    Name = var.name
  })
}

# AWS’s Transit Gateway Flow Logs field list: 
# https://docs.aws.amazon.com/vpc/latest/tgw/tgw-flow-logs.html#flow-logs-fields.
resource "aws_flow_log" "this" {
  log_destination      = var.flow_logs_s3_bucket_arn
  log_destination_type = "s3"
  transit_gateway_id   = aws_ec2_transit_gateway.this.id
  log_format           = local.flow_log_format
  max_aggregation_interval = 60
  tags = merge(var.tags, {
    Name = "${var.name}-flow-logs"
  })
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-route-table"
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
