output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.racer_bucket.id
}

# S3 Bucket
resource "aws_s3_bucket" "racer_bucket" {
  bucket = "racer-bucket"

  tags = {
    Name = "racer-bucket"
  }
}


resource "aws_s3_bucket_public_access_block" "racer_public_access" {
  bucket = aws_s3_bucket.racer_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.racer_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.racer_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}