# -------- xdefi/variables.tf --------

variable "region" {
  type        = string
  description = "Default region used on Terranova"
  default     = "eu-west-1"
}

variable "profile" {
  type        = string
  description = "Default profile to use"
  default     = "default"
}

variable "root_ebs_size" {
  type        = number
  description = "size of root ebs volume"
  default     = 50
}

variable "data_ebs_size" {
  type        = number
  description = "size of data ebs volume"
  default     = 100
}
variable "vpc_id" {
  type        = string
  description = "vpc"
  default     = "XXXXXXXXXXX"
}

variable "ec2_ami" {
  type        = string
  description = "AWS ami to use: the default is an ubuntu"
  default     = "ami-0c4f7023847b90238"
}


variable "ingress_ports" {
  type    = list(any)
  default = [26656, 1317, 26660, 26657, 22, 8681, 7080, 8343, 8621, 7980]
}
variable "instance_type" {
  type        = string
  description = "Instance"
  default     = "t2.medium"
}


variable "lb_subnets" {
  type = list(any)
}

variable "delete_on_termination" {
  type    = string
  default = true
}

variable "tags" {
  type        = map(any)
  description = "standards tags used on xdefi resources"

  default = {
    Environment = "test"
    Application = "XDeFi"
    Contact     = "XXXXXXXXXXXX@gmail.com"
    Terraform   = "True"
  }
}

variable "name" {
  type        = map(any)
  description = "Default custom variables used on the DGP"

  default = {
    Environment = "test"
    Application = "xdefi"
  }
}

variable "bucket" {
  type = string
}