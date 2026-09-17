# infra-aws-terraform

Pipeline GitHub Actions + Terraform que cria uma **EC2 na us-east-1** e usa uma
**tag de controle** (`action = create | delete`) para criar ou destruir a instância.

```
.github/workflows/terraform.yml   # plan em PR, apply/destroy via "Run workflow"
terraform/
├── versions.tf                   # provider AWS + backend S3 (config parcial)
├── variables.tf                  # variáveis, incl. a tag de controle "action"
├── main.tf                       # AMI Amazon Linux 2023 + aws_instance
└── outputs.tf
```

## A tag de controle

`terraform/main.tf`:

```hcl
enabled = local.action == "create" ? 1 : 0   # count da instância
```

| `action` | count | Resultado do `apply`          |
|----------|-------|-------------------------------|
| `create` | 1     | Cria (ou mantém) a EC2        |
| `delete` | 0     | Destrói a EC2                 |

O valor também vai para a tag `Action` da instância, ao lado da tag `Name`.

## O que a EC2 tem

AMI Amazon Linux 2023 mais recente, `t3.micro`, VPC/security group **default**
da região. Sem key pair e sem regras de rede extras — o mínimo para subir.

## Pré-requisitos

### 1. Bucket S3 para o state

Obrigatório: sem state remoto o `delete` não sabe o que destruir.

```bash
aws s3api create-bucket --bucket SEU-BUCKET-TFSTATE --region us-east-1
aws s3api put-bucket-versioning --bucket SEU-BUCKET-TFSTATE \
  --versioning-configuration Status=Enabled
```

O lock usa o mecanismo nativo do S3 (`use_lockfile=true`, Terraform ≥ 1.10),
sem DynamoDB.

### 2. Autenticação — escolha uma

**OIDC (recomendado):** crie o provedor OIDC do GitHub e uma role com esta
trust policy (troque `<ACCOUNT_ID>` e `<OWNER>/<REPO>`), depois guarde o ARN na
variable `AWS_ROLE_ARN`:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com" },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
      "StringLike": { "token.actions.githubusercontent.com:sub": "repo:<OWNER>/<REPO>:*" }
    }
  }]
}
```

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

**Access keys:** não defina `AWS_ROLE_ARN` e crie os secrets
`AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY`. O workflow escolhe o método
conforme `AWS_ROLE_ARN` estiver preenchida ou não.

Permissões necessárias: `ec2:*` (ou o subconjunto de instância/AMI/VPC) e
`s3:GetObject/PutObject/DeleteObject/ListBucket` no bucket do state.

### 3. Configuração no GitHub

`Settings → Secrets and variables → Actions`:

| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `TF_STATE_BUCKET` | variable | sim | Bucket S3 do state |
| `TF_STATE_KEY` | variable | não | Padrão `infra-aws-terraform/ec2/terraform.tfstate` |
| `AWS_ROLE_ARN` | variable | OIDC | ARN da role assumida via OIDC |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | secrets | access keys | Credenciais estáticas |

## Usando

- **Criar:** *Actions* → *Terraform AWS EC2* → *Run workflow* → `action = create`.
- **Destruir:** o mesmo com `action = delete`.
- **Pull request** que toque em `terraform/**`: roda `validate` + `plan`, sem aplicar.

O plan e os outputs (`instance_id`, `instance_public_ip`) aparecem no *Summary*
da execução.

## Localmente

```bash
cd terraform
terraform init \
  -backend-config="bucket=SEU-BUCKET-TFSTATE" \
  -backend-config="key=infra-aws-terraform/ec2/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"

terraform apply -var action=create
terraform apply -var action=delete   # remove a EC2
```

> `t3.micro` não está no free tier em todas as contas — não deixe a instância
> ligada sem necessidade.
