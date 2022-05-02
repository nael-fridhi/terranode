############## terraform.tfvars ##############

region                = "us-east-1"
lb_subnets            = ["XXXXXXXXXXXX", "XXXXXXXXXXXX"]
bucket                = "XXXXXXXXXXXX"
profile               = "default"
root_ebs_size         = 50
data_ebs_size         = 100
vpc_id                = "XXXXXXXXXXXX"
ec2_ami               = "ami-0c4f7023847b90238"
ingress_ports         = [26656, 1317, 26660, 26657, 22, 8681, 7080, 8343, 8621, 7980]
instance_type         = "t2.medium"
delete_on_termination = true

tags = {
  Environment = "test"
  Application = "XDeFi"
  Contact     = "XXXXXXXXXXXX@gmail.com"
  Terraform   = "True"
}

name = {
  Environment = "test"
  Application = "xdefi"
}


