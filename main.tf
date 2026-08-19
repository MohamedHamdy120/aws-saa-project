data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux2" {

  most_recent = true
  owners      = ["amazon"]

  filter {

    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
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

    from_port       = 80
    to_port         = 80
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

resource "aws_iam_instance_profile" "ec2_ssm" {

  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name
}

resource "aws_launch_template" "app" {

  name_prefix   = "app-lt"
  image_id      = data.aws_ami.amazon_linux2.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.ec2.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm.name
  }

  tags = { Name = "ec2-launch-template" }
}

resource "aws_lb_target_group" "app" {

  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    path                = "/"
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

  vpc_endpoint_type      = "Interface"
  service_name           = "com.amazonaws.eu-north-1.ssm"
  vpc_id                 = aws_vpc.main.id
  subnet_ids             = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.endpoint.id]
  private_dns_enabled    = true

  tags ={ Name = "ssm-endpoint" }
}

resource "aws_vpc_endpoint" "ec2messages" {

  vpc_endpoint_type      = "Interface"
  service_name           = "com.amazonaws.eu-north-1.ec2messages"
  vpc_id                 = aws_vpc.main.id
  subnet_ids             = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.endpoint.id]
  private_dns_enabled    = true

  tags= { Name = "ec2messages-endpoint" }
}

resource "aws_vpc_endpoint" "ssmmessages" {

  vpc_endpoint_type      = "Interface"
  service_name           = "com.amazonaws.eu-north-1.ssmmessages"
  vpc_id                 = aws_vpc.main.id
  subnet_ids             = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.endpoint.id]
  private_dns_enabled    = true

  tags ={ Name = "ssmmessages-endpoint" }
}