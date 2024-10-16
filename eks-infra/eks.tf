# aws_caller_identity 데이터 소스를 선언합니다
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "something" {
  name = "something"

  # 신뢰 정책: EKS 서비스가 이 역할을 가정할 수 있도록 허용
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "my-cluster"
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    aws-ebs-csi-driver     = {}
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI                    = "true"
          ENABLE_PREFIX_DELEGATION          = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
        nodeAgent = {
          enablePolicyEventLogs = "true"
        }
        enableNetworkPolicy = "true"
      })
    }
  }


  # VPC 모듈에서 생성된 서브넷 ID를 참조합니다
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets # 워커 노드를 위한 프라이빗 서브넷
  control_plane_subnet_ids = module.vpc.public_subnets  # 컨트롤 플레인을 위한 퍼블릭 서브넷

  # EKS 관리형 노드 그룹 설정
  eks_managed_node_group_defaults = {
    instance_types = "t3.medium"
  }

  eks_managed_node_groups = {
    example = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]

      min_size     = 3
      max_size     = 10
      desired_size = 3
    }
  }

  # 클러스터 액세스 엔트리
  # 현재 호출자 아이덴티티를 관리자 권한으로 추가
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    example = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/something"
      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            namespaces = ["default"]
            type       = "namespace"
          }
        }
      }
    }
  }

  # tags = {
  #   Environment = "dev"
  #   Terraform   = "true"
  # }
}

resource "null_resource" "update_kubeconfig" {
  # EKS 모듈이 완료될 때까지 기다립니다
  depends_on = [module.eks]

  triggers = {
    cluster_name = module.eks.cluster_name
  }

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"

  }
}
