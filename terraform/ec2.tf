# Variable for SSH key pair
variable "key_pair" {
  description = "The name of the SSH key pair"
  type        = string
}

output "instance_id" {
  description = "The ID of the instance"
  value       = aws_instance.training_instance.id
}

# EC2 Security Group allowing SSH (22) and HTTPS (443) from all IPs
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2-security-group"
  description = "Allow SSH and HTTPS from everywhere"

  ingress {
    from_port   = 22
    to_port     = 22
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

  tags = {
    Name = "ec2-security-group"
  }
}

# EC2 Instance
resource "aws_instance" "training_instance" {
  ami           = "ami-08d4ac5b634553e16" # Ubuntu 20.04 LTS AMI (adjust for your region)
  instance_type = "c5.2xlarge"

  # 45GB OS disk volume
  root_block_device {
    volume_size = 45
    volume_type = "gp2"
  }

  # Attach ephemeral drive (if applicable for instance type)
  ebs_block_device {
    device_name           = "/dev/sdb"
    volume_size           = 100 # Example size, adjust as needed
    volume_type           = "gp2"
    delete_on_termination = true
  }

  security_groups = [aws_security_group.ec2_security_group.name]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  key_name = var.key_pair # Make sure to pass the SSH key pair to log in

  tags = {
    Name = "CPUTrainingInstance"
  }
}
