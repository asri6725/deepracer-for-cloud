provider "aws" {
  region = "ap-southeast-2"
}

# S3 Bucket
resource "aws_s3_bucket" "racer_bucket" {
  bucket = "racer-bucket"

  # Block public access to the bucket
  block_public_acls   = true
  block_public_policy = true
  restrict_public_buckets = true

  versioning {
    enabled = true
  }

  tags = {
    Name = "racer-bucket"
  }
}

# S3 Bucket Policy to allow EC2 instance with specific role to put objects
resource "aws_s3_bucket_policy" "racer_bucket_policy" {
  bucket = aws_s3_bucket.racer_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "s3:PutObject"
        Effect = "Allow"
        Resource = "${aws_s3_bucket.racer_bucket.arn}/*"
        Principal = {
          AWS = "${aws_iam_role.ec2_instance_role.arn}"
        }
      }
    ]
  })
}

# IAM Role for EC2 Instance
resource "aws_iam_role" "ec2_instance_role" {
  name = "ec2-instance-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach S3 PutObject permission to the IAM role
resource "aws_iam_policy" "ec2_s3_policy" {
  name = "ec2-s3-put-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.racer_bucket.arn}/*"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "ec2_s3_attach" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
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

# Variable for SSH key pair
variable "key_pair" {
  description = "The name of the SSH key pair"
  type        = string
}

output "instance_id" {
  description = "The ID of the instance"
  value       = aws_instance.training_instance.id
}

output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.racer_bucket.id
}
