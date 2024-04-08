Terraform Module to provision an EC2 instance that runs perfectly

Not intended for Production Use. 

terraform {


}

provider "aws" {
   #profile = "default" 
   region = "us-west-2"
}


module "apache" {
   source = ".//terraform-aws-apache-example"
   vpc_id = "my vpc-id"
   my_ip_with_cidr = "90.196.111.10/32"
   public_key = "ssh-rsa xxx"
   instance_type = "t2.micro"
   server_name  = "Apache Example Server"

}


output "public_ip"{
  value = module.apache.public_ip
  
}






 
