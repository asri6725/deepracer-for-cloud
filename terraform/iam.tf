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
          "s3:Put*",
          "s3:Get*",
          "s3:List*"
        ]
        Resource = [
            "${aws_s3_bucket.racer_bucket.arn}/*",
            "${aws_s3_bucket.racer_bucket.arn}",
        ]
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