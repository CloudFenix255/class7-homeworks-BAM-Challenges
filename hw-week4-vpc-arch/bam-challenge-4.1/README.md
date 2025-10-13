# HW – BE A MAN (BAM) Challenge 4.1 – Extra Credit (10 pts)

**Goal:** In **sa-east-1**, create a VPC with **3 AZs**. Launch **one Windows bastion host** in a **public subnet** and **one Linux web server per AZ** in **3 separate private subnets**. Each Linux server must show **different text and pictures**. Provide screenshots:
1. Running **Windows bastion** (desktop visible)
2. The **three Linux servers' web pages**, each highlighting **different AZs** and **unique content**
3. **Successful SSH** from the bastion to **each Linux server**

This folder contains **Terraform** and a checklist to complete the challenge.

## Architecture (High Level)
- VPC CIDR: `10.50.0.0/16`
- Public Subnet (bastion): `10.50.0.0/24` (AZ-a)
- Private Subnets (web):
  - `10.50.10.0/24` (AZ-a) → web-a
  - `10.50.11.0/24` (AZ-b) → web-b
  - `10.50.12.0/24` (AZ-c) → web-c
- Internet Gateway attached (bastion has public IP)
- No NAT (keeps cost down) — Linux instances don't need internet to serve static pages
- Security Groups:
  - **bastion_sg:** allow RDP (3389) from your IP; allow SSH/HTTP egress to web_sg
  - **web_sg:** allow SSH (22) from bastion_sg; allow HTTP (80) from bastion_sg

## What You'll Need
- An **existing EC2 key pair** in `sa-east-1` (for both Windows password decrypt and Linux SSH). Set `var.ssh_key_name` to its name.
- Your public IP/CIDR (e.g., `x.x.x.x/32`) for RDP ingress. Set `var.allowed_cidr`.

## Deploy (Terraform)
```bash
cd terraform
terraform init
terraform apply -var 'aws_region=sa-east-1' -var 'ssh_key_name=<your-key-pair-name>' -var 'allowed_cidr=<your.ip.addr/32>'
```

## Connect
1. In AWS Console, get the **Windows bastion public IP** → RDP on port **3389**.
2. On the bastion, open **PowerShell**:
   - Import your **PEM** key (copy via RDP) and ensure permissions are correct.
   - SSH to each host (use private IPs from Terraform outputs):
     ```powershell
     ssh ec2-user@10.50.10.10
     ssh ec2-user@10.50.11.10
     ssh ec2-user@10.50.12.10
     ```
3. From the bastion, verify the web pages:
   ```powershell
   # From bastion to each Linux server (private IP)
   curl http://10.50.10.10
   curl http://10.50.11.10
   curl http://10.50.12.10
   ```

## Screenshots to include
- Put images in `images/`, then embed in `SCREENSHOTS.md`:
  - `bastion_desktop.png` (Windows Server desktop visible)
  - `web_a.png`, `web_b.png`, `web_c.png` (browser or curl output showing each AZ's unique page)
  - `ssh_a.png`, `ssh_b.png`, `ssh_c.png` (PowerShell showing SSH connected to each server)

## Teardown
```bash
cd terraform
terraform destroy -var 'aws_region=sa-east-1' -var 'ssh_key_name=<your-key-pair-name>' -var 'allowed_cidr=<your.ip.addr/32>'
```
