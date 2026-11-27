# Dernière AMI Ubuntu 24.04 LTS officielle (compte Canonical)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project}-tf"
  public_key = file(pathexpand(var.public_key_path))
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  key_name                    = aws_key_pair.main.key_name
  associate_public_ip_address = true

  metadata_options {
    http_tokens = "required" # IMDSv2 obligatoire (protection contre le vol d'identifiants)
  }

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = "${var.project}-app" }
}

# IP fixe : elle survit aux arrêts/redémarrages de l'instance
resource "aws_eip" "app" {
  domain     = "vpc"
  instance   = aws_instance.app.id
  depends_on = [aws_internet_gateway.main]
  tags       = { Name = "${var.project}-eip" }
}
