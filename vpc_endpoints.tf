resource "aws_vpc_endpoint" "sqs" {
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.eu-north-1.sqs"
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true
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

resource "aws_vpc_endpoint" "ECR-DKR" {
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.eu-north-1.ecr.dkr"
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true

  tags = { Name = "ECR-DKR-endpoint" }
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

resource "aws_vpc_endpoint" "ECS-Telemetry" {
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.eu-north-1.ecs-telemetry"
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true

  tags = { Name = "ECS-Telemetry-endpoint" }
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
