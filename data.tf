locals {
  amazon_linux_2023_id            = data.aws_ami.amazon_linux_2023.id
  assume_role_policy_for_ec2_json = data.aws_iam_policy_document.assume_role_policy_for_ec2.json
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

data "aws_iam_policy_document" "assume_role_policy_for_ec2" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
