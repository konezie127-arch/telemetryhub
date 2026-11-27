resource "aws_security_group" "app" {
  name        = "${var.project}-sg"
  description = "TelemetryHub : SSH restreint, HTTP public"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project}-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.app.id
  description       = "SSH depuis IP administrateur uniquement"
  cidr_ipv4         = var.ssh_allowed_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP public"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.app.id
  description       = "Sortie libre pour pull images et mises a jour"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}