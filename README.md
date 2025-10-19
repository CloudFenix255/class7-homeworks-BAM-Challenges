# Week 6 – Terraform Setup & Proof Checklist (AWS)

> **Deliverable format:** Put these files in your GitHub repo and share the repo link with your group leader.

This README gives **exact, step‑by‑step** instructions to set up Terraform on your computer, authenticate to AWS, run `terraform apply` in VS Code / Terminal / Git Bash / PowerShell, and capture the required screenshots. It also includes what tools to use (and avoid), what files to edit (and not edit), reference repos, and the precise commands.

---

## 1) What you will use (✅)

- **Terraform CLI** (v1.6+ recommended)
- **AWS CLI v2**
- **Visual Studio Code** (with HashiCorp Terraform extension) – or your terminal of choice
- **Git** (Git Bash on Windows or Terminal on macOS)
- **An AWS account/role** you can assume for testing (via **IAM user + access keys** or **AWS SSO**)

> Optional helpers:
> - **tfenv** (macOS/Linux) or **tfswitch** (Windows/macOS) to manage Terraform versions.
> - **AWS Vault** for safe credential handling (optional).

## 2) What you should NOT use (⛔️)

- Do **not** install Terraform via `pip` or Python tools (Terraform is a standalone binary).
- Do **not** edit Terraform’s generated files: `.terraform/` folder or `.terraform.lock.hcl`.
- Do **not** commit **state** or secrets: `*.tfstate`, `*.tfstate.backup`, `terraform.tfvars`, `.env`.
- Avoid very old Terraform versions (0.12/0.13). Use **1.6+**.

---

## 3) Install the tools

### macOS (Homebrew)
```bash
brew install terraform awscli git
# optional: brew install tfenv
```

### Windows (Winget or MSI)
- Install **Git**: https://git-scm.com/download/win
- Install **Terraform**: https://developer.hashicorp.com/terraform/install
- Install **AWS CLI v2**: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- (Optional) **tfswitch**: https://tfswitch.warrensbox.com/

### Verify installs
```bash
terraform -version
aws --version
git --version
```

---

## 4) Configure AWS credentials

Pick **one** method:

### A) IAM access keys
```bash
aws configure
# AWS Access Key ID: <your key>
# AWS Secret Access Key: <your secret>
# Default region name: us-east-1   # or your region
# Default output format: json
```

### B) AWS SSO (IAM Identity Center)
```bash
aws configure sso
aws sso login
```

### Confirm identity (required screenshot #2)
```bash
aws sts get-caller-identity
```
> Take a screenshot showing your terminal and the **Account**, **UserId**, and **Arn** output.

---

## 5) Clone or create your GitHub repo

```bash
# Example (replace with your repo URL)
git clone <YOUR_REPO_URL>.git
cd <YOUR_REPO_DIR>
```

Copy this starter pack into your repo root (or use it directly if you cloned here).

---

## 6) Project layout and files (what to edit vs. not edit)

```
.
├── README.md                 # You are reading this (edit with your notes if needed)
├── main.tf                   # Safe to edit (Terraform config)
├── variables.tf              # Safe to edit (input variables)
├── outputs.tf                # Safe to edit (output values)
├── .gitignore                # Keep as-is; do NOT remove Terraform ignores
├── share_log.txt             # Add at least one person who used these instructions
└── screenshots/              # Add your PNG/JPG screenshots here
    ├── terraform_apply.png
    ├── aws_sts_identity.png
    └── gitignore_view.png
```

**DO edit:** `main.tf`, `variables.tf`, `outputs.tf`, `README.md` (if you want to personalize).  
**DO NOT edit:** contents inside `.terraform/` folder or `.terraform.lock.hcl` once created.  
**DO NOT commit:** any `*.tfstate*` files, secrets, or `.env` files (already covered by `.gitignore`).

---

## 7) Minimal example (no-cost) to prove Terraform works

This config uses the AWS provider only to **read** your identity and writes it to a local file. No cloud resources are created or billed.

- `main.tf`:
```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "local_file" "whoami" {
  filename = "whoami.txt"
  content  = <<EOT
Account ID: ${data.aws_caller_identity.current.account_id}
ARN:        ${data.aws_caller_identity.current.arn}
UserId:     ${data.aws_caller_identity.current.user_id}
EOT
}
```

- `variables.tf`:
```hcl
variable "aws_region" {
  type        = string
  description = "Default AWS region"
  default     = "us-east-1"
}
```

- `outputs.tf`:
```hcl
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}
```

---

## 8) Initialize and apply (required screenshot #1)

From the project folder in **VS Code Terminal**, **Git Bash**, **Terminal**, or **PowerShell**:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform apply -auto-approve
```

Expected results:
- Terraform downloads providers and shows **Apply complete!**  
- A local file `whoami.txt` is created with your AWS account info.  
- Outputs display your `account_id` and `caller_arn`.

> Take a screenshot of the successful `terraform apply` in your terminal. Save as `screenshots/terraform_apply.png`.

---

## 9) Required screenshot #3 – .gitignore

Open `.gitignore` in VS Code and take a screenshot visibly showing the Terraform ignore rules.  
Save as `screenshots/gitignore_view.png`.

---

## 10) Commit & push to GitHub

```bash
git add .
git commit -m "Week 6: Terraform setup, screenshots, and proof"
git branch -M main
git remote add origin <YOUR_REPO_URL>  # if not added yet
git push -u origin main
```

Share the **repo link** with your group leader.

---

## 11) Reference repos & docs (optional, helpful)

- HashiCorp Learn Terraform: https://developer.hashicorp.com/terraform/tutorials
- AWS Provider Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

---

## 12) Troubleshooting tips

- If `aws sts get-caller-identity` fails, run `aws configure` or `aws sso login` again and confirm MFA/SSO.
- If Terraform can’t find credentials, set `AWS_PROFILE` (for named profiles) or export env vars:
  - macOS/Linux: `export AWS_PROFILE=<name>`
  - Windows PowerShell: `$env:AWS_PROFILE="<name>"`
- Delete `.terraform/` if provider download is corrupt, then re‑run `terraform init`.
- **Do not** manually edit `.terraform.lock.hcl`.

---

## 13) Submission checklist

- [ ] `README.md` (this file) in repo root
- [ ] `main.tf`, `variables.tf`, `outputs.tf` present
- [ ] `.gitignore` present in same folder as Terraform files
- [ ] Screenshot: `screenshots/terraform_apply.png`
- [ ] Screenshot: `screenshots/aws_sts_identity.png`
- [ ] Screenshot: `screenshots/gitignore_view.png`
- [ ] `share_log.txt` includes at least one person who used these instructions to deploy successfully
- [ ] Repo link shared with group leader

Good luck!

---

## 14) Reference repo mapping (as requested)

Use **https://github.com/chewbaccawaf/class7** as a *reference only* for structure and examples (don’t blindly `apply` it in a production account). Notable files in that repo:

- `0-Auth.tf` – authentication/provider/auth-related setup patterns  
- `1-VPC.tf`, `2-Subnets.tf`, `3-IGW.tf`, `4-NAT.tf`, `5-Route.tf` – core networking (VPC, subnets, internet/NAT gateways, routes)  
- `6-SG01-All.tf` – example security group(s)  
- `7-launchtemplate.tf`, `8-TargetGroup.tf`, `9-LoadBalancer.tf`, `10-AutoScalingGroup.tf` – compute + ALB/ASG patterns  
- `11-Key.tf` – key material patterns (SSH, etc.)  
- `12-Route53.tf` – Route 53 DNS patterns  
- `13-WAF.tf` – AWS WAF patterns  
- `A-backend.tf` – **Remote state backend** example; review/modify *only if* you are setting up remote state (S3/DynamoDB).  
- `azure-pipelines.yml` – example CI/CD pipeline config (Azure Pipelines).

**How to leverage it:**

1. Read the patterns above to understand how larger Terraform stacks are structured.  
2. For this Week 6 proof, stick to the minimal example in this repo (no-cost) to produce your screenshots.  
3. When you’re ready to expand, copy specific patterns from the reference repo into your own modules and adapt safely.

> Tip: If you adopt a remote backend, create the S3 bucket/DynamoDB table **before** enabling the backend and never commit state files to Git.
