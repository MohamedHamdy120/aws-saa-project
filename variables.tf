variable "vpc_cidr" {

  description = "This is the cidr range for the vpc"
  type        = string
  default     = "10.0.0.0/16"

}
variable "db_username" {

  description = "username for master database"
  type        = string
  sensitive   = true
}

variable "db_password" {

  description = "password for master database"
  type        = string
  sensitive   = true
}