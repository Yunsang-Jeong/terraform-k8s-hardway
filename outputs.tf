output "aws_cli_to_connect_bastion" {
  value = "aws ssm start-session --target ${aws_instance.bastion.id}"
}