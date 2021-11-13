variable "vpc_id" {
  description = "The ID of the VPC where the Lambda function will be provisioned"  
  type = string
}

variable "vpc_subnets" {
  description = "A list of subnets IDs within a VPC where the Lambda function will be provisioned"
  type = list(string)
}

variable "es_domain_arn" {
  description = "The ARN of the OpenSearch domain to backup"
  type        = string
}

variable "es_domain_host" {
  description = "The hostname of the OpenSearch domain to backup"
  type        = string
}

variable "lambda_cron_schedule" {
  description = "The schedule for performing the periodic backup, default to 1 day"
  type = string
  default = "rate(1 day)"
}

variable "snapshot_role" {
  description = "The name of the IAM role with permissions for taking OpenSearch backups"
  type        = string
  default     = "OpenSearchBackupRole"
}

variable "username" {
  description = "The name of the IAM user which performs the snapshots"
  type        = string
  default     = "myusername"
}

variable "region" {
  description = "The region where the Lambda function is provisioned. Should be the same as the OpenSearch domain"
  type = string
  default = "us-east-1"
}

variable "profile" {
  description = "The AWS CLI profile to use"
  type = string
  default = "default"
}


provider "aws" {
  region  = var.region
  profile = var.profile
}