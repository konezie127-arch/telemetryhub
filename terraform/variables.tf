variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "project" {
  type    = string
  default = "telemetryhub"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ssh_allowed_cidr" {
  description = "Votre IP publique au format x.x.x.x/32 (seule autorisée en SSH)"
  type        = string
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/telemetryhub-tf.pub"
}
