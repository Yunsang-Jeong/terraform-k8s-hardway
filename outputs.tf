output "aws_cli_to_connect_bastion" {
  value = "aws ssm start-session --target ${aws_instance.bastion.id}"
}

output "cluster_controller_private_ip_map" {
  value = {
    for idx, node in aws_instance.controller :
    idx => node.private_ip
  }
}

output "cluster_worker_private_ip_map" {
  value = {
    for idx, node in aws_instance.worker :
    idx => node.private_ip
  }
}
