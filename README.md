# AWS SAA + DevOps comprehnsive project
> A comprehensive hands-on project that integrates AWS cloud services introduced in the SAA course with DevOps tools across multiple phases into one complete project.

## The purpose of building the project
This project is built as part of my AWS Solutions Architect Associate (SAA) certification journey combined with a DevOps learning path.

The goal is to integrate AWS cloud services (VPC, ALB, ASG, RDS, SSM, ECR, EKS, etc.) with modern DevOps tools (Terraform, Docker, GitHub Actions, Kubernetes) across multiple phases into a single, production-like project.

By the end of this project, I will have:

- A secure, scalable 3‑tier architecture on AWS.
- Infrastructure as Code (IaC) using Terraform.
- Containerized applications with Docker + ECR.
- CI/CD pipelines with GitHub Actions.
- Monitoring, logging, and secrets management.
- Kubernetes orchestration on AWS (EKS) for container deployment and scaling.


## Phases

- **Phase 1:** Foundation (AWS console) - Competed
- **Phase 2:** Infrastructure as Code (Terraform) – Complete
- **Phase 3:** Containerization (Docker + ECR)
- **Phase 4:** CI/CD (GitHub Actions)
- **Phase 5:** Kubernetes (EKS) – Orchestration layer
- **Phase 6:** Monitoring, Security, Secrets Management
- **Phase 7:** Disaster Recovery & Documentation

## Architecture Overview

This project provisions a secure, scalable 3‑tier architecture on AWS.

- **Presentation Tier:** An internet-facing Application Load Balancer (ALB) in public subnets handles incoming HTTP traffic (HTTPS redirect planned for a later phase)
- **Application Tier:** EC2 instances running in private subnets, managed by an Auto Scaling Group (ASG), process application logic.
- **Data Tier:** An RDS (MySQL) instance in private subnets stores persistent data.

Security is enforced at every layer with least‑privilege Security Groups (ALB → EC2 → RDS) and IAM roles for EC2 (SSM permissions). VPC Endpoints enable secure SSM access without a NAT Gateway. The entire infrastructure is defined as code using Terraform.

## Prerequisites

- Terraform (≥ v1.0) installed.
- AWS CLI installed and configured with an IAM user that has sufficient permissions.
- AWS region set (e.g., `eu-north-1`).

> **Note:** Additional prerequisites (Docker, ECR, GitHub Actions, Kubernetes, etc.) will be added as the project progresses through later phases.


## Sections to be added

This README is initial and will be expanded as the project progresses. The following sections will be added by the end of the project:

- Architecture diagram (draw.io or Lucidchart)
- Detailed setup steps for each phase
- Verification and troubleshooting guide
- Disaster Recovery strategy
- Phase-specific outputs and screenshots
