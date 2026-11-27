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

variable "github_repo" {
  type    = string
  default = "konezie127-arch/telemetryhub"
}

variable "github_oidc_sub_prefix" {
  description = "Prefixe du sub OIDC GitHub (identifiants immuables du proprietaire et du depot)"
  type        = string
  default     = "repo:konezie127-arch@262629818/telemetryhub@1473818248"
}