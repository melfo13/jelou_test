variable "aws_region" {
  description = "AWS region donde desplegar los recursos"
  type        = string
  default     = "us-west-2"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID para las instancias EC2 (Amazon Linux 2)"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Amazon Linux 2 en us-west-2
}

variable "app_port" {
  description = "Puerto de la aplicación"
  type        = number
  default     = 3000
}

variable "use_elastic_ip" {
  description = "Usar Elastic IP para la instancia"
  type        = bool
  default     = true
}

variable "db_password" {
  description = "Password para la base de datos"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "La contraseña debe tener al menos 8 caracteres."
  }
}

variable "public_key" {
  description = "Clave pública SSH para acceso a las instancias"
  type        = string

  validation {
    condition     = can(regex("^ssh-", var.public_key))
    error_message = "La clave pública debe comenzar con ssh-rsa, ssh-ed25519, etc."
  }
}

variable "allowed_cidr_blocks" {
  description = "Bloques CIDR permitidos para acceso SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
