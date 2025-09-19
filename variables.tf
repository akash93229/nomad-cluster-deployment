variable "aws_region" {
  description = "The AWS region to create resources in"
  default     = "ap-south-1"  # Default value
}

variable "instance_type" {
  description = "EC2 instance type for Nomad server and client"
  default     = "t2.micro"
}

variable "ami" {
  description = "AMI for the EC2 instance"
  default     = "ami-0b898040803850657"  # Replace with your valid Ubuntu AMI ID for ap-south-1
}

variable "key_name" {
  description = "SSH key name for EC2 instance"
  default     = "terra-server-key"  # Replace with your actual SSH key pair name
}
