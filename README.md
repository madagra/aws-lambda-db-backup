# Daily backup of OpenSearch domains with AWS Lambda

This repo contains a simple Terraform program for provisioning a Lambda function
which takes daily snapshots of a previously created managed OpenSearch database on AWS.

In order to use this code, you need to created a `terraform.tfvars` file containing the following
mandatory variables:

```
# The ID of the VPC where the Lambda function will be provisioned
vpc_id = "<my_vpc_id>

# A list of subnets IDs within a VPC where the Lambda function will be provisioned
vpc_subnets = <my_vpc_subnets>

# The ARN of the OpenSearch domain to backup
es_domain_arn = <my_domain_arn>

# The hostname of the OpenSearch domain to backup (without neither the https:// in from nor the trailing /)
es_domain_host = <my_domain_host_url>
```

After that, you can provision using the standard Terraform workflow:

```shell
terraform init
terraform apply -auto-approve
```

More information can be found in [this](fdsfds) blogpost.