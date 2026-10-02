resource "aws_ecr_repository" "repository" {
  name = "guestbook-app"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "app" {
  name = "guestbook-cluster"
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

      environment = [{
        name  = "SQS_QUEUE_URL"
        value = aws_sqs_queue.guestbook_events.url
      }]
    }
  ])
}

resource "aws_ecs_service" "service" {
  name                               = "guestbook-service"
  cluster                            = aws_ecs_cluster.app.id
  task_definition                    = aws_ecs_task_definition.definition.arn
  desired_count                      = 1
  launch_type                        = "EC2"
  force_new_deployment               = true
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 5000
  }

  depends_on = [aws_lb_listener.app]
}
