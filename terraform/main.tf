# -------- xdefi/main.tf --------

############################################
# Terraform configuration
############################################

provider "aws" {
  region = var.region

  profile = var.profile
}

terraform {
  backend "s3" {
    bucket  = "XXXXXXXXXXXXXX"
    key     = "infrastructure/terraform"
    region  = "us-east-1"
    profile = "default"
    encrypt = true
  }
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
}

############################################
# Terranode Instance 
############################################

resource "aws_key_pair" "ssh_key" {
  key_name   = "${var.name["Application"]}-${var.name["Environment"]}-key"
  public_key = tls_private_key.key.public_key_openssh
}

resource "aws_secretsmanager_secret" "xdefi_ssm_secret" {
  name                    = "${var.name["Application"]}-${var.name["Environment"]}-srt"
  recovery_window_in_days = 0
  description             = "SSH root key for xdefi amadeus instance"
  tags                    = merge(var.tags, tomap({ "Name" : "${var.name["Application"]}-${var.name["Environment"]}-srt" }))
}

resource "aws_secretsmanager_secret_version" "xdefi_keypair" {
  secret_id     = aws_secretsmanager_secret.xdefi_ssm_secret.id
  secret_string = jsonencode(merge(tomap({ "keypair" : tls_private_key.key.private_key_pem })))
}

resource "aws_security_group" "xdefi_security_group" {
  name        = "${var.name["Application"]}-${var.name["Environment"]}-inst-sgr"
  description = "Used for access to the instance"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    iterator = port
    for_each = var.ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8", "172.0.0.0/8"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, tomap({ "Name" : "${var.name["Application"]}-${var.name["Environment"]}-inst-sgr" }))
}

resource "aws_instance" "xdefi" {
  count         = 2
  ami           = var.ec2_ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.ssh_key.key_name
  user_data = templatefile("${path.module}/resources/init.sh", {
    name        = "${var.name["Application"]}-${var.name["Environment"]}"
    environment = var.name["Environment"]
    application = var.tags["Application"]
    contact     = var.tags["Contact"]
    }
  )
  iam_instance_profile = aws_iam_instance_profile.xdefi.name

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_ebs_size
    delete_on_termination = var.delete_on_termination
  }

  ebs_block_device {
    device_name           = "/dev/sdb"
    volume_type           = "gp2"
    volume_size           = var.data_ebs_size
    delete_on_termination = false
    tags                  = merge(var.tags, tomap({ "Name" : "${var.name["Application"]}-${var.name["Environment"]}-data-ebs-vol" }))
  }
}

/*resource "null_resource" "ansible_execute" {
  depends_on = [aws_instance.xdefi]
  count      = 2
  connection {
    host        = aws_instance.xdefi[count.index].private_ip
    type        = "ssh"
    private_key = tls_private_key.key.public_key_openssh
  }
  provisioner "local-exec" {
    command = "echo \" I'm running some ansible playbook\""
  }
}*/

############################################
# Monitoring
############################################

resource "aws_ssm_parameter" "cloudwatch" {
  name  = "${var.name["Application"]}-${var.name["Environment"]}-pst"
  type  = "String"
  value = templatefile("${path.module}/resources/parameter_store.json", {})
}

resource "aws_ssm_document" "cloudwatch" {
  name            = "${var.name["Application"]}-${var.name["Environment"]}-ssm-doc"
  document_type   = "Automation"
  document_format = "YAML"
  content = templatefile(
    "${path.module}/resources/ssm_document_cloudwatch.yml",
    { instance_id_0        = aws_instance.xdefi[0].id
      instance_id_1        = aws_instance.xdefi[1].id
      parameter_store_name = "${var.name["Application"]}-${var.name["Environment"]}-pst"
  })
}

############################################
# Backup
############################################

resource "aws_backup_vault" "xdefi" {
  name = "${var.name["Application"]}-${var.name["Environment"]}-bva"
}

resource "aws_backup_plan" "xdefi" {
  name = "${var.name["Application"]}-${var.name["Environment"]}-bck"
  rule {
    rule_name         = "${var.name["Application"]}-${var.name["Environment"]}-rul"
    target_vault_name = aws_backup_vault.xdefi.name
    schedule          = "cron(0 0 * * ? *)"
    lifecycle {
      delete_after = 7
    }
  }
  tags = merge(var.tags, tomap({ "Name" : "${var.name["Application"]}-${var.name["Environment"]}-bck" }))
}

resource "aws_backup_selection" "xdefi" {
  iam_role_arn = aws_iam_role.awsbackup-xdefi.arn
  name         = "${var.name["Application"]}-${var.name["Environment"]}-stl"
  plan_id      = aws_backup_plan.xdefi.id
  resources = [
    aws_instance.xdefi[0].arn,
    aws_instance.xdefi[1].arn
  ]
}

############################################
# Load Balancing
############################################

resource "aws_security_group" "xdefi_lb_security_group" {
  name        = "${var.name["Application"]}-${var.name["Environment"]}-lb-sgr"
  description = "Used for access to the instance"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    iterator = port
    for_each = var.ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8", "172.0.0.0/8"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, tomap({ "Name" : "${var.name["Application"]}-${var.name["Environment"]}-lb-sgr" }))
}


resource "aws_lb" "xdefi_alb" {
  name               = "${var.name["Application"]}-${var.name["Environment"]}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.xdefi_lb_security_group.id]
  subnets            = var.lb_subnets

  enable_deletion_protection = true

  access_logs {
    bucket  = var.bucket
    prefix  = "data"
    enabled = true
  }
}

resource "aws_lb_target_group" "xdefi_alb_trg" {
  name     = "${var.name["Application"]}-${var.name["Environment"]}-alb-trg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}


resource "aws_lb_target_group_attachment" "xdefi_alb_trg_att" {
  count            = 2
  target_group_arn = aws_lb_target_group.xdefi_alb_trg.arn
  target_id        = aws_instance.xdefi[count.index].id
  port             = 80
}

resource "aws_lb_listener" "xdefi_lb_listener" {
  load_balancer_arn = aws_lb.xdefi_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.xdefi_alb_trg.arn
  }
}
