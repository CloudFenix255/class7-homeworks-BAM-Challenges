variable "aws_region" {
  description = "AWS region with at least 3 AZs (e.g., sa-east-1)"
  type        = string
  default     = "sa-east-1"
}

variable "ssh_key_name" {
  description = "Existing EC2 key pair name in this region"
  type        = string
}

variable "allowed_cidr" {
  description = "Your public IP/CIDR for RDP access to the bastion (e.g., 1.2.3.4/32)"
  type        = string
}
