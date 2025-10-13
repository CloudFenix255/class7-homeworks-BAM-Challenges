# Week 4 – VPC Network Architecture (Ready for Console or Terraform)

**Region:** sa-east-1 (São Paulo)  
**VPC CIDR:** 10.42.0.0/16  
**Subnets:** 3 public + 6 private (app/db across 3 AZs)

This repo contains:
- `network-architecture.md` — the full design with CIDR/masks, routing, and a build checklist you can follow **in the AWS Console**.
- `subnets.csv` — quick reference of subnets, masks, AZs, and usable IPs.
- `terraform/` — optional Terraform if you want to build it as code.
- `images/` — put your Udemy quiz screenshot here.
- `QUIZ_PROOF.md` — drop your screenshot and link here for grading.

## Quick Start (Console Build)
1. **Create VPC** → CIDR `10.42.0.0/16`.
2. **Create Internet Gateway** and **attach** to the VPC.
3. **Create 3 public subnets** using the CIDRs in `network-architecture.md`, one per AZ. Enable **Auto-assign public IPv4**.
4. **Create 6 private subnets** (3 app + 3 db) using the CIDRs listed.
5. **Create 1 public route table** with a **0.0.0.0/0** route to the **IGW**. Associate it to all 3 public subnets.
6. **Create 3 NAT Gateways** (one per public subnet) each with a new EIP.
7. **Create 3 private route tables** (one per AZ) each with **0.0.0.0/0 → its AZ’s NAT GW**. Associate them to the app+db subnets in the same AZ.
8. (Optional) **NACLs**: start with VPC defaults; harden later.
9. (Optional) **Security Groups**: create ALB/EC2/RDS groups per your app.
10. **Save a diagram/screenshot** of your subnets and route tables.

## Optional Terraform
```bash
cd terraform
terraform init
terraform plan -var 'aws_region=sa-east-1'
terraform apply -var 'aws_region=sa-east-1'
```
> Be sure your AWS credentials/profile are configured.
