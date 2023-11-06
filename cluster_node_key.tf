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
