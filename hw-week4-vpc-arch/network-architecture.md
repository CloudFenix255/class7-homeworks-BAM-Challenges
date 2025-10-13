# Network Architecture – AWS VPC (Week 4 Deliverable)

**Designed Region:** sa-east-1 (São Paulo)  
**VPC CIDR:** 10.42.0.0/16 (/16)

## Availability Zones
- sa-east-1a
- sa-east-1b
- sa-east-1c

## Subnet Plan (CIDRs & Masks)
| Tier        | AZ         | Subnet Name     | CIDR          | Mask | Usable IPs |
|-------------|------------|-----------------|---------------|------|------------|
| Public      | sa-east-1a | public-a        | 10.42.0.0/24  | /24  | 251        |
| Public      | sa-east-1b | public-b        | 10.42.1.0/24  | /24  | 251        |
| Public      | sa-east-1c | public-c        | 10.42.2.0/24  | /24  | 251        |
| Private App | sa-east-1a | private-app-a   | 10.42.10.0/24 | /24  | 251        |
| Private App | sa-east-1b | private-app-b   | 10.42.11.0/24 | /24  | 251        |
| Private App | sa-east-1c | private-app-c   | 10.42.12.0/24 | /24  | 251        |
| Private DB  | sa-east-1a | private-db-a    | 10.42.20.0/24 | /24  | 251        |
| Private DB  | sa-east-1b | private-db-b    | 10.42.21.0/24 | /24  | 251        |
| Private DB  | sa-east-1c | private-db-c    | 10.42.22.0/24 | /24  | 251        |

> AWS reserves 5 IPs per subnet; usable count = 256 - 5 = 251.

## Routing & Internet/NAT
- **Internet Gateway (IGW):** Attached to VPC; used by public subnets.
- **NAT Gateways:** 3 total (one per public subnet) for HA egress from private subnets.
- **Route Tables:**
  - **Public RT:** `0.0.0.0/0 → IGW`; associated with all 3 public subnets.
  - **Private RT-A:** `0.0.0.0/0 → NAT-A`; associated with `private-app-a` & `private-db-a`.
  - **Private RT-B:** `0.0.0.0/0 → NAT-B`; associated with `private-app-b` & `private-db-b`.
  - **Private RT-C:** `0.0.0.0/0 → NAT-C`; associated with `private-app-c` & `private-db-c`.

## Build Checklist (Console)
1. Create VPC `10.42.0.0/16`.
2. Create and attach IGW.
3. Create subnets exactly as listed (enable Auto-assign public IP on public subnets).
4. Allocate 3 Elastic IPs; create 3 NAT Gateways in public-a/b/c.
5. Create 1 public route table + default route to IGW; associate public subnets.
6. Create 3 private route tables + default route to each AZ’s NAT; associate appropriate app/db subnets.
7. (Optional) Configure NACLs and Security Groups.
8. Save screenshots of subnets and route tables for your repo.

## ASCII Diagram (High Level)

VPC 10.42.0.0/16 (sa-east-1)
```
                +--------------------- Internet ---------------------+
                                |               |               |
                             +--v--+         +--v--+         +--v--+
                             | IGW |         | NAT |         | NAT |
                             +--+--+         +--+--+         +--+--+
                                |               |               |
     AZ a (sa-east-1a)          |     AZ b (sa-east-1b)        |      AZ c (sa-east-1c)
+-----------------------+   +---+--------------------------+   +------------------------+
| public-a 10.42.0.0/24 |   | public-b 10.42.1.0/24       |   | public-c 10.42.2.0/24  |
|  RT → IGW             |   |  RT → IGW                   |   |  RT → IGW              |
+-----------+-----------+   +------------+----------------+   +------------+-----------+
            |                            |                                 |
   +--------v--------+          +--------v--------+               +--------v--------+
   | private-app-a   |          | private-app-b   |               | private-app-c   |
   | 10.42.10.0/24   |          | 10.42.11.0/24   |               | 10.42.12.0/24   |
   | RT → NAT-a      |          | RT → NAT-b      |               | RT → NAT-c      |
   +--------+--------+          +--------+--------+               +--------+--------+
            |                            |                                 |
   +--------v--------+          +--------v--------+               +--------v--------+
   | private-db-a    |          | private-db-b    |               | private-db-c    |
   | 10.42.20.0/24   |          | 10.42.21.0/24   |               | 10.42.22.0/24   |
   | RT → NAT-a      |          | RT → NAT-b      |               | RT → NAT-c      |
   +-----------------+          +-----------------+               +-----------------+
```

## Notes
- This design meets the requirement of **at least 3 public** and **6 private** subnets.
- It is **AZ-balanced** and ready for ALB/ASG (public) + EC2/ECS (private-app) + RDS (private-db).

