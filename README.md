# emock-back-terraforms

Projeto Terraform para provisionar a base de infraestrutura AWS do `emock-backend`.

Hoje essa stack faz o seguinte:

- Usa backend remoto do Terraform Cloud/HCP na organizacao `emock`, workspace `terraform-github-actions`.
- Provisiona uma `VPC` em `us-east-1` com bloco `10.0.0.0/16`.
- Cria uma subnet publica (`10.0.1.0/24`) e uma subnet privada (`10.0.2.0/24`), ambas em `us-east-1a`.
- Cria `Internet Gateway`, `Elastic IP` e `NAT Gateway` para permitir saida da subnet privada.
- Configura tabela de rotas publica e privada com suas respectivas associacoes.
- Cria um `Security Group` para o backend com entrada liberada para `SSH` na porta `22` e `HTTP` na porta `80`, alem de saida total.
- Cria um repositorio `ECR` chamado `repository-emock-backend` para armazenamento de imagens Docker.
- Cria um cluster `ECS` chamado `emock-backend-cluster`.

Recursos que existem apenas como rascunho no codigo e nao sao aplicados atualmente:

- `aws_key_pair`
- `aws_instance` publica para API
- `aws_instance` em subnet privada

## Estrutura principal

- [main.tf](/Users/developer/infra-aws/emock-back-terraforms/main.tf): definicao dos recursos AWS.
- [variables.tf](/Users/developer/infra-aws/emock-back-terraforms/variables.tf): variavel `ssh_public_key`, usada apenas pelos recursos comentados.
- [arquitetura-emock-backend.drawio](/Users/developer/infra-aws/emock-back-terraforms/arquitetura-aws/arquitetura-emock-backend.drawio): diagrama da arquitetura.

## Como validar

1. Execute `terraform init` para instalar providers e configurar o backend remoto.
2. Execute `terraform plan` para revisar o que sera criado ou alterado.
3. Execute `terraform apply` para provisionar a infraestrutura.

## Observacoes

- O provider AWS esta fixado em `~> 5.0`.
- A variavel `ssh_public_key` continua declarada, mas so sera necessaria se os recursos EC2 comentados forem reativados.
- O `Security Group` atual expoe `22` e `80` para `0.0.0.0/0`, o que pode exigir endurecimento antes de uso em producao.
