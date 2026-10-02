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
