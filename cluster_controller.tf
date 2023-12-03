resource "aws_instance" "controller" {
  ami                  = local.amazon_linux_2023_x86_id
  instance_type        = "t3.small"
  iam_instance_profile = aws_iam_instance_profile.controller.name
  key_name             = aws_key_pair.cluster_key.key_name
  subnet_id            = lookup(module.network.subnet_ids, "private-a")
  vpc_security_group_ids = [
    lookup(module.security_groups.security_group_ids, "ec2-k8s-controller")
  ]
  user_data = templatefile(
    "userdata/cluster_controller.sh.tftpl",
    {
      ARCH                               = "amd64"
      OS                                 = "linux"
      CONTAINERD_VERSION                 = "1.7.9"
      CRICTL_VERSION                     = "1.28.0"
      RUNC_VERSION                       = "1.1.10"
      ENI_PLUGINS_VERSION                = "1.3.0"
      KUBERNETES_RELEASE                 = "1.28.4"
      KUBERNETES_PKG_RELEASE             = "0.4.0"
      SYSTEMD_CONTAINERD_SERVICE         = replace(file("${path.root}/configurations/containerd/containerd.service"), "$", "\\$")
      ENI_PLUGINS_BASIC_CONFIG           = replace(file("${path.root}/configurations/eni/10-containerd-net.conflist"), "$", "\\$")
      CONTAINERD_CONFIG                  = replace(file("${path.root}/configurations/containerd/config.toml"), "$", "\\$")
      SYSTEMD_KUBELET_SERVICE            = replace(file("${path.root}/configurations/kubelet/kubelet.service"), "$", "\\$")
      SYSTEMD_KUBELET_DROPIN_FOR_KUBEADM = replace(file("${path.root}/configurations/kubelet/10-kubeadm.conf"), "$", "\\$")
      CLUSTER_JOIN_KEY_PARAM             = "/k8s/cluster-join-key"
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
    Name = "${var.name_prefix}-controller-ec2"
  }
}

resource "aws_iam_role" "controller" {
  name_prefix        = "${var.name_prefix}-controller"
  assume_role_policy = local.assume_role_policy_for_ec2_json
}

resource "aws_iam_instance_profile" "controller" {
  name = "${var.name_prefix}-controller"
  role = aws_iam_role.controller.name
}

resource "aws_iam_role_policy_attachment" "controller" {
  role       = aws_iam_role.controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "controller_get_cluster_join_key" {
  name = "get-cluster-join-key"
  role = aws_iam_role.controller.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:PutParameter",
        ]
        Resource = aws_ssm_parameter.kubeadm_join_key.arn
      },
    ]
  })
}