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
