resource "aws_instance" "bastion" {
  ami                  = local.amazon_linux_2023_arm64_id
  instance_type        = "t4g.small" # Free-tier until 2023-12-31
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name
  subnet_id            = lookup(module.network.subnet_ids, "public-a")
  vpc_security_group_ids = [
    lookup(module.security_groups.security_group_ids, "ec2-bastion"),
  ]
  associate_public_ip_address = true
  user_data = templatefile(
    "userdata/bastion.sh.tftpl",
    {
      PRIVATE_KEY_OPENSSH = aws_ssm_parameter.cluster_key.name
    }
  )

  root_block_device {
    volume_type           = "gp3"
    volume_size           = "30"
    iops                  = 3000
    throughput            = 125
    delete_on_termination = true
  }

  metadata_options {
    instance_metadata_tags = "enabled"
  }

  tags = {
    Name = "${var.name_prefix}-bastion-ec2"
  }
}

resource "aws_iam_role" "bastion" {
  name_prefix        = "${var.name_prefix}-bastion"
  assume_role_policy = local.assume_role_policy_for_ec2_json
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.name_prefix}-bastion"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_role_policy_attachment" "bastion" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "basation_get_cluster_key" {
  name = "get-cluster-key"
  role = aws_iam_role.bastion.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
        ]
        Resource = aws_ssm_parameter.cluster_key.arn
      },
    ]
  })
}