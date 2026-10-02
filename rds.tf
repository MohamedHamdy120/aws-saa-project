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

resource "aws_ssm_parameter" "db_url" {
  name  = "/guestbook/db_url"
  type  = "SecureString"
  value = "mysql+pymysql://${var.db_username}:${var.db_password}@${aws_db_instance.app.endpoint}/appdb"
}
