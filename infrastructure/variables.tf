variable "aws_region" {
  description = "The region we are going to operate in"
  default     = "us-east-1"
}

variable "availability-zone-1a" {
  default = "us-east-1a"
}

variable "availability-zone-1b" {
  default = "us-east-1b"
}

variable "instance_type" {
  default = "t3.micro"
}