variable "region" {
  type    = string
  default = "us-east-1"
}
variable "access_key" {
  type    = string
  default = "<access_key>"
}
variable "secret_key" {
  type    = string
  default = "<secret_key>"
}
variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}
variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}
variable "ami" {
  type    = string
  default = "ami-0bef6cc322bfff646"
}
variable "instance_type" {
  type    = string
  default = "t2.micro"
}
variable "key_name" {
  type    = string
  default = "my-devops-evaluation-key"
}
