terraform {

  ###### PRORIEDADES PARA REALIZAR DEPLOY VIA ESTEIRA USANDO HCP

  backend "remote" {
    organization = "emock"
    workspaces {
      name = "terraform-github-actions"
    }
  }


  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc-emock-backend" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-emock-backend"
  }
}

resource "aws_subnet" "public-subnet-emock-backend" {
  vpc_id            = aws_vpc.vpc-emock-backend.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet-emock-backend"
  }
}

resource "aws_subnet" "private-subnet-emock-backend" {
  vpc_id            = aws_vpc.vpc-emock-backend.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"


  tags = {
    Name = "private-subnet-emock-backend"
  }
}

resource "aws_internet_gateway" "igw-emock-backend" {
  vpc_id = aws_vpc.vpc-emock-backend.id

  tags = {
    Name = "igw-emock-backend"
  }
}

resource "aws_eip" "nat-eip-emock-backend" {
  tags = {
    Name = "nat-eip-emock-backend"
  }
}

resource "aws_nat_gateway" "nat-gw-emock-backend" {
  allocation_id = aws_eip.nat-eip-emock-backend.id
  subnet_id     = aws_subnet.public-subnet-emock-backend.id

  tags = {
    Name = "nat-gw-emock-backend"
  }
}

resource "aws_route_table" "public-rt-emock-backend" {
  vpc_id = aws_vpc.vpc-emock-backend.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-emock-backend.id
  }
  tags = {
    Name = "public-rt-emock-backend"
  }
}

resource "aws_route_table_association" "public-ta-emock-backend" {
  subnet_id      = aws_subnet.public-subnet-emock-backend.id
  route_table_id = aws_route_table.public-rt-emock-backend.id
}

resource "aws_route_table" "private-rt-emock-backend" {
  vpc_id = aws_vpc.vpc-emock-backend.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw-emock-backend.id
  }
  tags = {
    Name = "private-rt-emock-backend"
  }
}

resource "aws_route_table_association" "private-ta-emock-backend" {
  subnet_id      = aws_subnet.private-subnet-emock-backend.id
  route_table_id = aws_route_table.private-rt-emock-backend.id
}


resource "aws_security_group" "security-group-emock-backend" {
  description = "Security group emock backend"
  vpc_id      = aws_vpc.vpc-emock-backend.id


  ingress = [
    {
      #SSH
      description = "Regra conexao SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      # Ajusta para bloco de IP do GitHub Actions - Avaliar se é possível fazer a integração sem passar pela internet
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },

    {
      # HTTP
      description = "Regra para requisicoes http"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      # Ajusta para bloco de IP do GitHub Actions - Avaliar se é possível fazer a integração sem passar pela internet
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
  ]

  egress = [
    {
      description      = "Regra de saida."
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false

    }
  ]

  tags = {
    Name = "security-group-emock-backend"
  }
}

resource "aws_ecr_repository" "repository-emock-backend" {
  name                 = "repository-emock-backend"
  image_tag_mutability = "MUTABLE"

  tags = {
    name = "repository-emock-backend"
  }

}

resource "aws_ecs_cluster" "ecs-cluster-emock-backend" {
  name = "emock-backend-cluster"

  tags = {
    Name = "ecs-cluster-emock-backend"
  }
}

resource "aws_key_pair" "key-pair-emock-backend" {
  key_name   = "deployer-key"
  # public_key = file("/Users/developer/.ssh/emock-backend-key.pub")
    public_key = var.ssh_public_key

  tags = {
    Name = "key-pair-emock-backend"
  }
}

resource "aws_instance" "api-emock-backend" {
  ami = "ami-020cba7c55df1f615"
  # instance_type = "t3.small" # 2Vcpu 2GB
  instance_type               = "t2.micro" # 1Vcpu 1GB
  subnet_id                   = aws_subnet.public-subnet-emock-backend.id
  vpc_security_group_ids      = [aws_security_group.security-group-emock-backend.id]
  key_name                    = aws_key_pair.key-pair-emock-backend.key_name
  associate_public_ip_address = true

  # provisioner "local-exec" {
  #   command = "curl -fsSl https://get.docker.com | sh"
  #   # Cria um arquivo na máquina local
  # }
  user_data = <<-EOF
              #!/bin/bash
              curl -fsSl https://get.docker.com | sh
              sudo usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "api-emock-backend"
  }
}


# resource "aws_instance" "recurso-subnet-privada" {
#   ami           = "ami-020cba7c55df1f615"
#   # instance_type = "t3.small" # 2Vcpu 2GB
#   instance_type = "t2.micro" # 1Vcpu 1GB
#   subnet_id = aws_subnet.private-subnet-emock-backend.id
#   vpc_security_group_ids = [ aws_security_group.security-group-emock-backend.id ]
#   key_name = aws_key_pair.key-pair-emock-backend.key_name

#   tags = {
#     Name = "recurso-subnet-privada"
#   }
# }
