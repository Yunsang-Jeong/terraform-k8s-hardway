resource "tls_private_key" "cluster_key" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "cluster_key" {
  key_name   = "${var.name_prefix}-cluster-key"
  public_key = tls_private_key.cluster_key.public_key_openssh
}

resource "aws_ssm_parameter" "cluster_key" {
  name  = "/k8s/cluster-key"
  type  = "SecureString"
  value = trim(tls_private_key.cluster_key.private_key_openssh, "\n")
}

resource "aws_ssm_parameter" "kubeadm_join_key" {
  name  = "/k8s/cluster-join-key"
  type  = "SecureString"
  value = "init,init,init"

  lifecycle {
    ignore_changes = [value, insecure_value]
    replace_triggered_by = [aws_instance.controller.private_ip]
  }
}
