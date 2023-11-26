resource "aws_instance" "worker" {
  count = 0

  ami                  = local.amazon_linux_2023_x86_id
  instance_type        = "t3.small"
  iam_instance_profile = aws_iam_instance_profile.worker.name
  key_name             = aws_key_pair.cluster_key.key_name
  subnet_id = count.index % 2 == 0 ? (
    lookup(module.network.subnet_ids, "private-a")
    ) : (
    lookup(module.network.subnet_ids, "private-c")
  )
  vpc_security_group_ids = [
    lookup(module.security_groups.security_group_ids, "ec2-k8s-worker")
  ]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = "30"
    iops                  = 3000
    throughput            = 125
    delete_on_termination = true
  }

  tags = {
    Name = "${var.name_prefix}-worker-ec2"
  }
}

resource "aws_iam_role" "worker" {
  name_prefix        = "${var.name_prefix}-worker"
  assume_role_policy = local.assume_role_policy_for_ec2_json
}

resource "aws_iam_instance_profile" "worker" {
  name = "${var.name_prefix}-worker"
  role = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "worker" {
  role       = aws_iam_role.worker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
