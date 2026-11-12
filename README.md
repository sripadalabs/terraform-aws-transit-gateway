# terraform-aws-transit-gateway

Creates an AWS Transit Gateway, exports its ID to Systems Manager Parameter Store, enables S3 Flow Logs, and shares the gateway with AWS Organizations organizational units through AWS RAM. The provider infers the Transit Gateway Flow Log resource type from `transit_gateway_id`. This module does not create VPC attachments or configure Transit Gateway route tables.

## Requirements

| Name | Version |
| --- | --- |
| Terraform | `>= 1.3.0` |
| AWS provider | `>= 5.0, < 7.0` |

## Usage

```hcl
module "transit_gateway" {
  source = "git::https://github.com/sripadalabs/terraform-aws-transit-gateway.git"

  name                    = "shared-network"
  description             = "Shared network Transit Gateway"
  flow_logs_s3_bucket_arn = "arn:aws:s3:::central-network-flow-logs"
  ram_principals = [
    "arn:aws:organizations::123456789012:ou/o-exampleorgid/ou-abcd-12345678",
  ]

  ssm_parameter_name = "/network/shared/transit-gateway/id"
  amazon_side_asn    = 64520

  tags = {
    Environment = "shared"
    ManagedBy   = "Terraform"
  }
}
```

Default Transit Gateway route table association and propagation are disabled. Set `enable_default_route_table_association` or `enable_default_route_table_propagation` to `true` to enable either behavior. Those settings only control the gateway's automatic defaults; this module does not create or manage route tables or attachments.

## Inputs

| Name | Description | Type | Default | Required |
| --- | --- | --- | --- | --- |
| `name` | Name for the Transit Gateway and related resources | `string` | n/a | yes |
| `ram_principals` | One or more AWS Organizations OU ARNs to receive the share | `list(string)` | n/a | yes |
| `flow_logs_s3_bucket_arn` | Destination S3 bucket ARN, without a prefix | `string` | n/a | yes |
| `description` | Transit Gateway description | `string` | `null` | no |
| `amazon_side_asn` | Private ASN for the Transit Gateway | `number` | `64512` | no |
| `enable_default_route_table_association` | Enable automatic default route table association | `bool` | `false` | no |
| `enable_default_route_table_propagation` | Enable automatic default route table propagation | `bool` | `false` | no |
| `ssm_parameter_name` | SSM parameter name for the Transit Gateway ID | `string` | `"/network/transit-gateway/id"` | no |
| `tags` | Tags applied to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| --- | --- |
| `transit_gateway_id` | Transit Gateway ID |
| `transit_gateway_arn` | Transit Gateway ARN |
| `ssm_parameter_name` | Name of the SSM parameter containing the ID |
| `ssm_parameter_arn` | ARN of the SSM parameter containing the ID |
| `ram_resource_share_arn` | RAM resource share ARN |
| `flow_log_id` | Transit Gateway Flow Log ID |

## AWS prerequisites and permissions

- The AWS provider must be configured for the account and Region where the Transit Gateway will be created. The caller needs permissions for EC2 Transit Gateway and Flow Logs, SSM parameter management, and AWS RAM share/resource/principal associations.
- `ram_principals` accepts OU ARNs in the form `arn:<partition>:organizations::<management-account-id>:ou/o-<organization-id>/ou-<organizational-unit-id>`. AWS RAM sharing with AWS Organizations must already be enabled from the AWS Organizations management account (trusted access / organization sharing). The module does not enable organization sharing or create OUs.
- The supplied S3 bucket must exist in the Transit Gateway's Region and allow the Flow Logs delivery service to check its ACL and write objects. For a bucket owned by the Transit Gateway account, a bucket policy can grant delivery as follows; replace the placeholders:

  ```json
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AWSLogDeliveryWrite",
        "Effect": "Allow",
        "Principal": {
          "Service": "delivery.logs.amazonaws.com"
        },
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::<bucket-name>/AWSLogs/<transit-gateway-owner-account-id>/*",
        "Condition": {
          "StringEquals": {
            "s3:x-amz-acl": "bucket-owner-full-control",
            "aws:SourceAccount": "<transit-gateway-owner-account-id>"
          },
          "ArnLike": {
            "aws:SourceArn": "arn:aws:logs:<region>:<transit-gateway-owner-account-id>:*"
          }
        }
      },
      {
        "Sid": "AWSLogDeliveryAclCheck",
        "Effect": "Allow",
        "Principal": {
          "Service": "delivery.logs.amazonaws.com"
        },
        "Action": "s3:GetBucketAcl",
        "Resource": "arn:aws:s3:::<bucket-name>",
        "Condition": {
          "StringEquals": {
            "aws:SourceAccount": "<transit-gateway-owner-account-id>"
          },
          "ArnLike": {
            "aws:SourceArn": "arn:aws:logs:<region>:<transit-gateway-owner-account-id>:*"
          }
        }
      }
    ]
  }
  ```

- The SSM parameter is created in the Transit Gateway account and is not shared to other accounts by this module. Consumers in other accounts need their own permitted way to retrieve the ID (for example, passing the output or publishing it through an approved cross-account mechanism).

VPC attachments and their route-table associations/propagations belong in a separate module.
