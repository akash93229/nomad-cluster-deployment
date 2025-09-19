provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "nomad_sg" {
  name        = "nomad-security-group"
  description = "Security group for Nomad cluster"

  ingress {
    from_port   = 4647   # Nomad RPC port
    to_port     = 4647
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4648   # Nomad HTTP API port
    to_port     = 4648
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80     # HTTP for Nomad UI and app access
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nomad_server" {
  ami              = var.ami  # Make sure this references the ami variable
  instance_type    = var.instance_type
  key_name         = var.key_name
  security_groups  = [aws_security_group.nomad_sg.name]
  tags = {
    Name = "Nomad Server"
  }

  # User data to install Nomad
  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y unzip
    wget https://releases.hashicorp.com/nomad/1.0.1/nomad_1.0.1_linux_amd64.zip
    unzip nomad_1.0.1_linux_amd64.zip
    sudo mv nomad /usr/local/bin/
  EOF
}

resource "aws_instance" "nomad_client" {
  count          = 3  # This will create 3 Nomad clients
  ami            = var.ami
  instance_type  = var.instance_type
  key_name       = var.key_name
  security_groups = [aws_security_group.nomad_sg.name]
  tags = {
    Name = "Nomad Client"
  }

  # User data to install Nomad
  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y unzip
    wget https://releases.hashicorp.com/nomad/1.0.1/nomad_1.0.1_linux_amd64.zip
    unzip nomad_1.0.1_linux_amd64.zip
    sudo mv nomad /usr/local/bin/
  EOF
}
