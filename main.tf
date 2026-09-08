data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ecs_optimized" {

  most_recent = true
  owners      = ["amazon"]

  filter {

    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {

    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "main" {

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {

    Name = "phase2_vpc"
  }

}

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.main.id

  tags = {

    Name = "phase2_igw"
  }

}


resource "aws_subnet" "public" {

  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {

    Name = "public-subnet-${count.index + 1}"
  }

}

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.main.id

  route {

    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {

    Name = "public_route_table"

  }

}

resource "aws_route_table_association" "public" {

  route_table_id = aws_route_table.public.id
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id

}

resource "aws_subnet" "private" {

  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 2)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {

    Name = "private-subnet-${count.index + 1}"
  }

}

resource "aws_route_table" "private" {

  vpc_id = aws_vpc.main.id

  tags = {

    Name = "private_route_table"

  }

}

resource "aws_route_table_association" "private" {

  route_table_id = aws_route_table.private.id
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id

}

resource "aws_security_group" "alb" {

  name        = "alb-sg"
  description = "allow http traffic from anywhere"
  vpc_id      = aws_vpc.main.id

  ingress {

    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "alb-sg" }
}


resource "aws_security_group" "ec2" {

  name        = "ec2-sg"
  description = "allow http traffic from only alb"
  vpc_id      = aws_vpc.main.id

  ingress {

    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ec2-sg" }
}


resource "aws_security_group" "rds" {

  name        = "rds-sg"
  description = "allow mysql traffic from only the ec2"
  vpc_id      = aws_vpc.main.id

  ingress {

    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "rds-sg" }
}

resource "aws_security_group" "endpoint" {

  vpc_id      = aws_vpc.main.id
  description = "A sg for https request from ec2 instance"
  name        = "endpoint-sg"
  ingress {

    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "endpoint-sg"
  }

}
resource "aws_db_subnet_group" "app" {

  name       = "app-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = { Name = "app-db-subnet-group" }
}


resource "aws_db_instance" "app" {

  identifier        = "app-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = "20"
  storage_type      = "gp2"

  db_name  = "appdb"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.app.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot = true
  publicly_accessible = false

  tags = { Name = "app-db" }
}

resource "aws_iam_role" "ec2_ssm" {

  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{

      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]

    }


  )

}

resource "aws_iam_role_policy_attachment" "ssm" {

  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecs" {

  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"

}
resource "aws_iam_instance_profile" "ec2_ssm" {

  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name
}

resource "aws_launch_template" "app" {

  name_prefix   = "app-lt"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.ec2.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm.name
  }

  user_data = base64encode(<<-EOF
  #!/bin/bash
  echo ECS_CLUSTER=${aws_ecs_cluster.app.name} >> /etc/ecs/ecs.config
  EOF
  )

  tags = { Name = "ec2-launch-template" }
}

resource "aws_lb_target_group" "app" {

  name     = "app-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    path                = "/health"
  }
  tags = { name = "app-tg" }

}

resource "aws_lb" "alb" {

  name               = "alb"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  load_balancer_type = "application"
  internal           = false

  tags = {
    name = "alb"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.alb.arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_autoscaling_group" "app" {

  name                = "app-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app.arn]

  tag {
    key                 = "Name"
    value               = "target"
    propagate_at_launch = true
  }
}

resource "aws_vpc_endpoint" "ssm" {

  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.eu-north-1.ssm"
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true

  tags = { Name = "ssm-endpoint" }
}

resource "aws_vpc_endpoint" "ec2messages" {

  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.eu-north-1.ec2messages"
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true

  tags = { Name = "ec2messages-endpoint" }
}

resource "aws_vpc_endpoint" "ssmmessages" {

  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.eu-north-1.ssmmessages"
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true

  tags = { Name = "ssmmessages-endpoint" }
}

resource "aws_vpc_endpoint" "ECR-API" {

  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.eu-north-1.ecr.api"
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true

  tags = { Name = "ECR-API-endpoint" }
}
resource "aws_vpc_endpoint" "ECS-Telemetry" {

  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.eu-north-1.ecs-telemetry"
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true

  tags = { Name = "ECS-Telemetry-endpoint" }
}
resource "aws_vpc_endpoint" "ECS-Agent" {

  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.eu-north-1.ecs"
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true

  tags = { Name = "ECS-Agent-endpoint" }
}

resource "aws_vpc_endpoint" "ECR-DKR" {

  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.eu-north-1.ecr.dkr"
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true

  tags = { Name = "ECR-DKR-endpoint" }
}

resource "aws_vpc_endpoint" "ACS" {

  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.eu-north-1.ecs-agent"
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true

  tags = { Name = "ACS-endpoint" }
}
resource "aws_vpc_endpoint" "s3" {
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.eu-north-1.s3"
  vpc_id            = aws_vpc.main.id
  route_table_ids   = [aws_route_table.private.id]


  tags = { Name = "s3-endpoint" }
}

resource "aws_ecr_repository" "repository" {
  name = "guestbook-app"
  image_scanning_configuration {
    scan_on_push = true
  }

}
resource "aws_ecs_cluster" "app" {

  name = "guestbook-cluster"
}

resource "aws_ssm_parameter" "db_url" {

  name  = "/guestbook/db_url"
  type  = "SecureString"
  value = "mysql+pymysql://${var.db_username}:${var.db_password}@${aws_db_instance.app.endpoint}/appdb"
}

resource "aws_iam_role" "task-ssm" {
  name = "task-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{

      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}


resource "aws_iam_role" "execution" {
  name = "excution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{

      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}


resource "aws_iam_role_policy_attachment" "execution_ecs" {

  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "execution_ssm" {

  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_ecs_task_definition" "definition" {

  family                   = "guestbook-task"
  network_mode             = "host"
  memory                   = 256
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task-ssm.arn

  container_definitions = jsonencode([
    {
      name  = "app"
      image = aws_ecr_repository.repository.repository_url

      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ]

      secrets = [{
        name      = "DATABASE_URL"
        valueFrom = aws_ssm_parameter.db_url.arn
      }]
    }
  ])

}

resource "aws_ecs_service" "service" {

  name                 = "guestbook-service"
  cluster              = aws_ecs_cluster.app.id
  task_definition      = aws_ecs_task_definition.definition.arn
  desired_count        = 1
  launch_type          = "EC2"
  force_new_deployment = true
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 5000
  }

  depends_on = [aws_lb_listener.app]

}

resource "aws_s3_bucket" "bucket" {
  bucket        = "guestbook-static-721937028581"
  force_destroy = true
  tags          = { Name = "guestbook-static" }
}
resource "aws_s3_bucket_public_access_block" "bucket_block_access" {

  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_identity" "OAI" {

  comment = "OAI for s3 static bucker"
}

resource "aws_cloudfront_distribution" "cloud-distribution" {
  enabled = true
  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.bucket.id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.OAI.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = aws_lb.alb.dns_name
    origin_id   = "ALB-origin"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  default_root_object = "index.html"

  ordered_cache_behavior {
    path_pattern     = "/messages"
    allowed_methods  = ["HEAD", "GET", "POST", "OPTIONS", "DELETE", "PUT", "PATCH"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = "ALB-origin"

    forwarded_values {
      headers      = ["Access-Control-Request-Method", "Access-Control-Request-Header", "Origin"]
      query_string = true

      cookies {
        forward = "all"
      }
    }
    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.bucket.id
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_s3_bucket_policy" "s3-policy" {

  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Principal = { "AWS" : "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.OAI.id}" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.bucket.arn}/*"
      Effect    = "Allow"
    }]
  })
}