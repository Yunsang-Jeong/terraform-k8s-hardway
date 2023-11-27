module "network" {
  source = "github.com/Yunsang-Jeong/terraform-aws-network"

  name_prefix    = var.name_prefix
  vpc_cidr_block = "10.0.0.0/16"
  create_igw     = true
  subnets = [
    {
      identifier            = "public-a"
      availability_zone     = "ap-northeast-2a"
      cidr_block            = "10.0.0.0/18"
      enable_route_with_igw = true
      create_nat            = true
    },
    {
      identifier            = "public-c"
      availability_zone     = "ap-northeast-2c"
      cidr_block            = "10.0.64.0/18"
      enable_route_with_igw = true
    },
    {
      identifier            = "private-a"
      availability_zone     = "ap-northeast-2a"
      cidr_block            = "10.0.128.0/18"
      enable_route_with_nat = true
      additional_tag        = {}
    },
    {
      identifier            = "private-c"
      availability_zone     = "ap-northeast-2c"
      cidr_block            = "10.0.192.0/18"
      enable_route_with_nat = true
      additional_tag        = {}
    },
  ]
}

resource "aws_vpc_endpoint" "s3_gw" {
  vpc_id          = module.network.vpc_id
  service_name    = "com.amazonaws.ap-northeast-2.s3"
  route_table_ids = values(module.network.route_table_ids)
}

module "security_groups" {
  source = "github.com/Yunsang-Jeong/terraform-aws-securitygroup"

  vpc_id = module.network.vpc_id
  security_groups = [
    {
      identifier  = "ec2-bastion"
      description = "the security group for bastion host"
      ingresses   = []
    },
    {
      #
      # https://kubernetes.io/docs/reference/networking/ports-and-protocols/#control-plane
      #
      identifier  = "ec2-k8s-controller"
      description = "the security group for k8s control-plain"
      ingresses = [
        {
          identifier  = "ssh-from-bastion",
          description = "allow bastion to connect ssh-connection",
          from_port   = "22", to_port = "22", protocol = "tcp", source_security_group_identifier = "ec2-bastion",
        },
        {
          identifier  = "api-service-from-worker-node",
          description = "allow worker-node to connect api-service",
          from_port   = "6443", to_port = "6443", protocol = "tcp", source_security_group_identifier = "ec2-k8s-worker",
        },
        {
          identifier  = "api-service-from-control-plane",
          description = "allow control-plane to connect api-service",
          from_port   = "6443", to_port = "6443", protocol = "tcp", self = true,
        },
        {
          identifier  = "etcd-server",
          description = "allow etcd to connect control-plane",
          from_port   = "2378", to_port = "2380", protocol = "tcp", self = true,
        },
        {
          identifier  = "kubelet-api"
          description = "allow kubelet to connect control-plane",
          from_port   = "10250", to_port = "10250", protocol = "tcp", self = true,
        },
        {
          identifier  = "kube-scheduler",
          description = "allow kube-scheduler to connect control-plane",
          from_port   = "10251", to_port = "10251", protocol = "tcp", self = true,
        },
        {
          identifier  = "kube-controller-manager"
          description = "allow kube-controller-manager to connect control-plane",
          from_port   = "10252", to_port = "10252", protocol = "tcp", self = true,
        },
      ]
    },
    {
      # 
      # https://kubernetes.io/docs/reference/networking/ports-and-protocols/#node
      # 
      identifier  = "ec2-k8s-worker"
      description = "the security group for k8s worker node"
      ingresses = [
        {
          identifier  = "ssh-from-bastion",
          description = "allow bastion to connect ssh-connection",
          from_port   = "22", to_port = "22", protocol = "tcp", source_security_group_identifier = "ec2-bastion",
        },
        {
          identifier  = "kubelet-api-from-worker-node",
          description = "allow control-plane to connect kubelet",
          from_port   = "10250", to_port = "10250", protocol = "tcp", source_security_group_identifier = "ec2-k8s-controller",
        },
        # {
        #   identifier = "node-port-service",
        #   description = "service",
        #   from_port  = "30000", to_port = "32767", protocol = "tcp", cidr_blocks = ["10.0.0.0/16"],
        # },
      ]
    },
  ]
}
