provider "aws" {
  region = "us-east-1"  # Adjust the region as needed
}

# Define the security group
resource "aws_security_group" "hw2_sshfromhome" {
  name        = "ssh_access_from_home-hw2"
  description = "EC2: ssh from home; http(s) from anywhere"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["194.62.137.21/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_instance" "ec2_t2micro" {
  ami           = "ami-03a4942b8fcc1f29d"
  instance_type = "t2.micro"

  key_name = "test-mykola1_pair"

  vpc_security_group_ids = [aws_security_group.hw2_sshfromhome.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
              curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              EOF

  tags = {
    Name = "terraform-ec2-instance"
  }
}

# Output the public IP of the EC2 instance
output "instance_ip" {
  value = aws_instance.ec2_t2micro.public_ip
}

resource "null_resource" "destroy_instance" {
  provisioner "local-exec" {
    command = "terraform destroy -auto-approve -lock=false"
  }

  depends_on = [aws_instance.ec2_t2micro]
}