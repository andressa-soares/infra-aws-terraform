# infra-aws-terraform

Pipeline GitHub Actions + Terraform que cria uma EC2 na **us-east-1**, com uma
tag de controle que decide entre criar e destruir.

```
.github/workflows/terraform.yml   # plan em PR, apply/destroy via "Run workflow"
terraform/                        # AMI Amazon Linux 2023 + aws_instance
docs/iam-policy.json              # permissoes minimas do usuario do pipeline
```

## A tag de controle

```hcl
count = var.action == "create" ? 1 : 0
```

| `action` | Resultado do `apply`   |
|----------|------------------------|
| `create` | Cria (ou mantém) a EC2 |
| `delete` | Destrói a EC2          |

O valor também vai para a tag `Action` da instância, ao lado da tag `Name`.

## Usando

- **Criar:** *Actions* → *Terraform AWS EC2* → *Run workflow* → `action = create`.
- **Destruir:** o mesmo, com `action = delete`.
- **Pull request** que toque em `terraform/**`: roda só o `plan`.

O plan e os outputs (`instance_id`, `instance_public_ip`) saem no *Summary* da
execução.

## Configuração (já feita)

Bucket S3 `andressa-tfstate-infra-aws` para o state — o Terraform não cria esse
bucket, e sem ele o `delete` não sabe o que destruir.

Em `Settings → Secrets and variables → Actions`:

| Nome | Tipo | Valor |
|------|------|-------|
| `TF_STATE_BUCKET` | variable | `andressa-tfstate-infra-aws` |
| `TF_STATE_KEY` | variable | opcional; padrão `infra-aws-terraform/ec2/terraform.tfstate` |
| `AWS_ACCESS_KEY_ID` | secret | chave do usuário IAM do pipeline |
| `AWS_SECRET_ACCESS_KEY` | secret | idem |

As permissões desse usuário estão em `docs/iam-policy.json`.

## Localmente

```bash
cd terraform
terraform init \
  -backend-config="bucket=andressa-tfstate-infra-aws" \
  -backend-config="key=infra-aws-terraform/ec2/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"

terraform apply -var action=create
terraform apply -var action=delete
```

> A instância fica ligada (e faturando) até você rodar o `delete`.
