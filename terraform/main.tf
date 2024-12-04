# S3 bucket for storing athena query results
resource "aws_s3_bucket" "athena-s3-data-madmax" {
  bucket = "athena-s3-data-madmax"    
}

resource "aws_s3_bucket_object" "source-data-object" {
  key    = "netflix_titles.csv"
  bucket = aws_s3_bucket.athena-s3-data-madmax.id
  source = "../netflix_titles.csv"
}

# S3 bucket for storing athena query results
resource "aws_s3_bucket" "athena-results-madmax" {
  bucket = "athena-results-madmax"
}

# Athena Database
resource "aws_athena_database" "athena-results-madmax" {
  name   = "database_name"
  bucket = aws_s3_bucket.athena-results-madmax.id
}

# Glue catalog database
resource "aws_glue_catalog_database" "netflix" {
  name = "netflix"
}

# Glue table
resource "aws_glue_catalog_table" "shows" {
  name          = "shows"
  database_name = aws_glue_catalog_database.netflix.name
}

# IAM Role for Glue
# Lambda Function Role
resource "aws_iam_role" "athena-glue-role" {
  name               = "athena-glue-role"
  assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "sts:AssumeRole",
                "Principal": {
                  "Service": "glue.amazonaws.com"
                },
                "Effect": "Allow",
                "Sid": ""
            }
        ]
    }
    EOF
}

# Glue S3 Policy
resource "aws_iam_policy" "glue-s3-policy" {
  name        = "glue-s3-policy"
  description = "AWS IAM Policy for accessing s3 bucket"
  policy      = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject",
                    "s3:PutObject"
                ],
                "Resource": [
                    "arn:aws:s3:::athena-data-madmax/netflix_titles.csv*"
                ]
            }
        ]
    }
    EOF
}

resource "aws_iam_role_policy_attachment" "glue-service-role" {
  role       = aws_iam_role.athena-glue-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonGlueServiceRole"
}

# Glue S3 Role-Policy Attachment
resource "aws_iam_role_policy_attachment" "glue-s3-policy-attachment" {
  role       = aws_iam_role.athena-glue-role.name
  policy_arn = aws_iam_policy.glue-s3-policy.arn
}

# Glue crawler
resource "aws_glue_crawler" "netflix_crawler" {
  database_name = aws_glue_catalog_database.netflix.name
  name          = "netflix_crawler"
  role          = aws_iam_role.athena-glue-role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.athena-s3-data-madmax.bucket}"
  }
}