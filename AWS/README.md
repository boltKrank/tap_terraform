# TAP on AWS

[https://github.com/ndwinton/tap-setup-scripts]

## Pre-lim

export AWS_ACCESS_KEY_ID= xxx
export AWS_SECRET_ACCESS_KEY = xxx
AWS_SESSION_TOKEN= xxx=

## Architecture

1. VPC
2. Subnets (public + private)
3. Route table
4. Route table associations (public + private)
5. Internet gateway (add to VPC)
6. Add route (route table + gateway)
7. Security group (ingress and egress)
8. NIC (for VM)
9. Public IP for NIC
10. VM (using NIC and/or security group)
