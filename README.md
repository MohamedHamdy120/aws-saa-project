# AWS SAA + DevOps comprehnsive project
> A comprehensive hands-on project that integrates AWS cloud services introduced in the SAA course with DevOps tools across multiple phases into one complete project.

## The purpose of building the project
This project is built as part of my AWS Solutions Architect Associate (SAA) certification journey combined with a DevOps learning path.

The goal is to integrate AWS cloud services (VPC, ALB, ASG, RDS, SSM, ECR, EKS, etc.) with modern DevOps tools (Terraform, Docker, GitHub Actions, Kubernetes) across multiple phases into a single, production-like project.

## By the end of this project, I will have:

- **A secure, scalable 3-tier architecture** on AWS (VPC, ALB, ECS, RDS) with strict network isolation and IAM least privilege.
- **Infrastructure as Code** using Terraform — VPC, subnets, ALB, ASG/ECS, RDS, SSM, VPC endpoints, SQS, SNS, Lambda, and CloudWatch.
- **Containerized applications** with Docker, ECR, and ECS on EC2 capacity, fronted by S3 + CloudFront.
- **CI/CD pipelines** with GitHub Actions, including SAST (CodeQL), dependency and image scanning (Trivy), automated ECR push, and ECS deployments with post-deploy health validation.
- **Event-driven architecture** using SQS, SNS, and Lambda for asynchronous background processing and operational alerting.
- **Monitoring, logging, and secrets management** via CloudWatch, SSM Parameter Store, and KMS.
- **Kubernetes orchestration** on AWS (EKS) with Helm for container deployment and scaling.
- **Advanced observability** with Prometheus and Grafana for metrics, dashboards, and alerting.
- **Remote Terraform state** managed via S3 backend with DynamoDB locking.
- **Production-grade documentation** with architecture diagrams and a detailed README.


## Phases

- **Phase 1:** Manual 3-Tier Architecture (VPC, ALB, EC2 ASG, RDS, IAM) — ✅ Complete
- **Phase 2:** Infrastructure as Code (Terraform: VPC, subnets, ALB, ASG, RDS, SSM, VPC endpoints) — ✅ Complete
- **Phase 3:** Containerization & CDN (Docker, ECR, ECS on EC2, S3 + CloudFront, ALB origin) — ✅ Complete
- **Phase 4:** CI/CD & Event-Driven Architecture (GitHub Actions, CodeQL, Trivy, SQS, SNS, Lambda, CloudWatch) — 🚧 In Progress
- **Phase 5:** Monitoring, Security & Secrets (CloudWatch, KMS, IAM hardening) — ⏳ Planned
- **Phase 6:** Terraform State Management (Remote Backend: S3 + DynamoDB lock) — ⏳ Planned
- **Phase 7:** Documentation & Exam Prep (README, architecture diagrams) — ⏳ Planned
- **Phase 8:** Kubernetes (EKS, kubectl, Helm) — ⏳ Planned
- **Phase 9:** Advanced Observability (Prometheus, Grafana) — ⏳ Planned

## Architecture Overview

This project provisions a secure, scalable, decoupled 3-tier architecture on AWS.

### Presentation Tier
- **CloudFront** (HTTPS) serves the static frontend from a private **S3 bucket** via Origin Access Identity (OAI).
- A second CloudFront origin routes `/messages` to the **Application Load Balancer**, unifying frontend and API under one domain and eliminating CORS and mixed-content issues.
- The **ALB** sits in public subnets and forwards traffic to the application tier.

### Application Tier
- A **Flask API** runs as a containerized workload on **ECS (EC2 capacity)** in private subnets.
- The ECS cluster is fronted by the ALB with dynamic port mapping and target group health checks.
- **Auto Scaling** is managed at the ECS service level.

### Data Tier
- **RDS (MySQL)** resides in private subnets with no public access, accessible only from the ECS tasks.

### Security
- **Network isolation:** strict Security Group chaining (CloudFront → ALB → ECS → RDS); compute and database have no direct internet exposure.
- **IAM least privilege:** ECS task roles scoped to the minimum required actions; no long-lived credentials on instances.
- **Secrets management:** RDS credentials stored in **SSM Parameter Store** and injected at runtime.
- **Private connectivity:** **VPC Endpoints** for SSM, ECR, S3, ECS, and CloudWatch Logs keep traffic off the public internet — no NAT Gateway required.
- **Delivery:** all infrastructure is defined as code using **Terraform**.

## Prerequisites

### Core (required from Phase 1)
- **Terraform** (≥ v1.0) — infrastructure provisioning.
- **AWS CLI** installed and configured with an IAM user that has sufficient permissions.
- **AWS region** set (e.g., `eu-north-1`).

### Phase 3 (Containers & CDN)
- **Docker** — building the Flask application image locally.
- **Amazon ECR** — container registry (created via Terraform).
- **AWS account access** to S3, CloudFront, and ECS.

### Phase 4 (CI/CD & Event-Driven)
- **GitHub repository** with Actions enabled.
- **GitHub Secrets** configured:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION`
  - `ECR_REPOSITORY`
  - `ECS_CLUSTER`, `ECS_SERVICE`, `ECS_TASK_DEFINITION`, `CONTAINER_NAME`
- **Trivy** and **CodeQL** run inside the pipeline — no local install required.

### Phase 5+ (Planned)
- **Kubernetes tooling:** `kubectl`, `helm` (Phase 8).
- **Observability stack:** Prometheus, Grafana (Phase 9).


## Sections to be added

This README is a living document and will continue to be expanded as the project progresses.

### In Progress
- **Architecture diagram** (draw.io or Lucidchart) — reflecting CloudFront, ECS, and RDS tiers.
- **Phase-specific outputs and screenshots** — deployment evidence, pipeline runs, and CloudWatch dashboards.

### Planned
- **Detailed setup steps** — per-phase runbooks for reproduction from scratch.
- **Verification and troubleshooting guide** — common failure modes and fixes (e.g., ECS agent registration, VPC endpoint issues, Trivy gating).
- **Disaster Recovery strategy** — RDS snapshots, Terraform state recovery, and multi-AZ considerations.

### Already added
- ✅ Project overview and phased roadmap.
- ✅ Architecture overview (3-tier with CloudFront, ECS, RDS).
- ✅ Security posture (implemented vs. planned).
- ✅ Prerequisites grouped by phase.
- ✅ Phases with concrete AWS services and tools.
