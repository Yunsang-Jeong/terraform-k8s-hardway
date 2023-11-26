resource "aws_instance" "controller" {
  count = 1

  ami                  = local.amazon_linux_2023_x86_id
  instance_type        = "t3.small"
  iam_instance_profile = aws_iam_instance_profile.controller.name
  key_name             = aws_key_pair.cluster_key.key_name
  subnet_id = count.index % 2 == 0 ? (
    lookup(module.network.subnet_ids, "private-a")
    ) : (
    lookup(module.network.subnet_ids, "private-c")
  )
  vpc_security_group_ids = [
    lookup(module.security_groups.security_group_ids, "ec2-k8s-controller")
  ]
  user_data = templatefile(
    "userdata/cluster_node.yaml.tftpl",
    {
      ARCH                       = "amd64"
      OS                         = "linux"
      CONTAINERD_VERSION         = "1.7.9"
      RUNC_VERSION               = "1.1.10"
      ENI_PLUGINS_VERSION        = "1.3.0"
      KUBERNETES_RELEASE         = "1.28.4"
      KUBERNETES_PKG_RELEASE     = "0.4.0"
      SYSTEMD_CONTAINERD_SERVICE = indent(4, file("configurations/containerd.service"))
      SYSTEMD_KUBELET_SERVICE    = indent(4, file("configurations/kubelet.service"))
      SYSTEMD_KUBEADM_CONFIG     = indent(4, file("configurations/10-kubeadm.conf"))
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
    instance_metadata_tags ="enabled"
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
