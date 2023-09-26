variable "aws_access_key" {
    type = string
    description = "Enter aws access key"
    sensitive = true  
}
variable "aws_secret_key" {
  type = string
  description = "Enter aws secret key"
  sensitive = true
}
variable "aws_region" {
  type = string
  description = "AWS region"
  sensitive = false
  default = "us-east-1"
}
variable "vpc_cidr_block" {
    type = string
    description = "VPC CIDR Block"
    default = "10.0.0.0/16"
  
}
variable "vpc_subnets_cide_blocks" {
    type = list(string)
    description = "subnet_cidr_blocks"
    default = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24","10.0.4.0/24","10.0.5.0/24","10.0.6.0/24"]  
}
