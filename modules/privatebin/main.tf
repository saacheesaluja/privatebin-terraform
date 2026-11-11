# S3 bucket for PrivateBin notes
resource "aws_s3_bucket" "privatebin_notes" {
  #checkov:skip=CKV2_AWS_62:No S3 event notification workflow is required for PrivateBin notes.
  #checkov:skip=CKV_AWS_144:Cross-region replication is excluded to avoid additional infrastructure and storage costs.
  #checkov:skip=CKV_AWS_145:AES256 server-side encryption is enabled; customer-managed KMS encryption is not required.
  bucket = "privatebin-notes-904869824787"

  tags = {
    Name      = "PrivateBin Notes"
    Component = "Storage"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "notes" {
  bucket = aws_s3_bucket.privatebin_notes.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "notes" {
  bucket = aws_s3_bucket.privatebin_notes.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "notes" {
  bucket = aws_s3_bucket.privatebin_notes.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle management
resource "aws_s3_bucket_lifecycle_configuration" "notes" {
  bucket = aws_s3_bucket.privatebin_notes.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}


# EC2 trust policy
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# IAM role for PrivateBin EC2
resource "aws_iam_role" "privatebin_ec2" {
  name               = "privatebin-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name      = "PrivateBin EC2 Role"
    Component = "Security"
  }
}

# Least-privilege S3 policy
data "aws_iam_policy_document" "privatebin_s3" {
  statement {
    sid       = "ListNotesFolder"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.privatebin_notes.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["notes/", "notes/*"]
    }
  }

  statement {
    sid    = "ManageNotesObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.privatebin_notes.arn}/notes/*"
    ]
  }
}

resource "aws_iam_policy" "privatebin_s3" {
  name   = "privatebin-s3-notes-policy"
  policy = data.aws_iam_policy_document.privatebin_s3.json
}

resource "aws_iam_role_policy_attachment" "privatebin_s3" {
  role       = aws_iam_role.privatebin_ec2.name
  policy_arn = aws_iam_policy.privatebin_s3.arn
}

# EC2 instance profile
resource "aws_iam_instance_profile" "privatebin" {
  name = "privatebin-instance-profile"
  role = aws_iam_role.privatebin_ec2.name
}

# S3 bucket for access logs

resource "aws_s3_bucket" "access_logs" {
  #checkov:skip=CKV2_AWS_62:No S3 event notification workflow is required for access logs.
  #checkov:skip=CKV_AWS_144:Cross-region replication is excluded to avoid additional infrastructure and storage costs.
  #checkov:skip=CKV_AWS_145:AES256 server-side encryption is enabled; customer-managed KMS encryption is not required.
  bucket = "privatebin-access-logs-904869824787"

  tags = {
    Name      = "PrivateBin Access Logs"
    Component = "Logging"
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "logging.s3.amazonaws.com"
      }
      Action   = "s3:PutObject"
      Resource = "${aws_s3_bucket.access_logs.arn}/notes/*"
      Condition = {
        ArnLike = {
          "aws:SourceArn" = aws_s3_bucket.privatebin_notes.arn
        }
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }]
  })
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "expire-old-access-logs"
    status = "Enabled"

    filter {

    }

    expiration {
      days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_logging" "notes" {
  bucket        = aws_s3_bucket.privatebin_notes.id
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "notes/"
}

resource "aws_s3_bucket_ownership_controls" "access_logs" {
  #checkov:skip=CKV2_AWS_65:BucketOwnerPreferred ownership is retained for S3 server access logging compatibility.
  bucket = aws_s3_bucket.access_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.privatebin_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_security_group" "privatebin" {
  name        = "privatebin-sg"
  description = "Allow PrivateBin access only from my IP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "PrivateBin web access"
    from_port   = 3344
    to_port     = 3344
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  egress {
    description = "Allow HTTP outbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "privatebin-sg"
    Project = var.project_name
  }
}


data "aws_vpc" "default" {
  default = true
}

# Find default VPC subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# EC2 instance for PrivateBin

resource "aws_instance" "privatebin" {
  #checkov:skip=CKV_AWS_135:Explicit EBS optimization forces replacement of the existing t3.micro instance.
  #checkov:skip=CKV_AWS_88:Public IP retained for the current deployment; inbound access is restricted to the user's IP.
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.privatebin.id
  ]

  iam_instance_profile = aws_iam_instance_profile.privatebin.name

  user_data = replace(<<-EOF
    #!/bin/bash
    set -eux

    dnf update -y
    dnf install -y docker

    systemctl enable docker
    systemctl start docker

    mkdir -p /opt/privatebin

    echo "${base64encode(file("${path.module}/conf.php"))}" | base64 -d > /opt/privatebin/conf.php

    chmod 644 /opt/privatebin/conf.php

    docker pull privatebin/s3:2.1.1

    docker run -d \
      --name privatebin \
      --restart unless-stopped \
      -p 3344:8080 \
      -v /opt/privatebin/conf.php:/srv/cfg/conf.php:ro \
      privatebin/s3:2.1.1
  EOF
  , "\n", "\r\n")

  user_data_replace_on_change = false
  monitoring                  = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "privatebin-ec2"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
  lifecycle {
    ignore_changes = [
      tags["cg-mdatpkey"],
      tags["cg-mdatpstatus"],
      user_data
    ]
  }
}
