data "aws_vpc" "main" {
  #id = var.vpc_id
  id = var.vpc_id
}

data "template_file" "user_data" {
    template = file("${abspath(path.module)}/userdata.yaml")
}
#     private_key = "${file("~/.ssh/id_rsa")}"

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.public_key
  #public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDhXivvf6MRdr51xRnkYSgLKlAi0xvjlqbSGQkZGOlYkvLB1NgHxQr+ldvNOPH5utTE2bexuVXpqMtNHePYAtIkATAoOtP2lH0MwvkjoPiAaCZ4S9KZIgnk5U1j4OtN0Owi3gXuQEcJUlKgcxutQ85U6npmD/p9udswLg9a1jTibHOReCYknDngpF7+u6YGVHrZl0MS8pJOyEXtT0zDv+XaJudp94Aotva9WSeZwRdyPDLwPsU/v7N/Kjob3fC6uqmlrVEzwnzaB85io1e/B3HQUn9OMBKTwh10+z2Ex5RmoPDjMgneceWRBvIUnsS1w0RrFOXxRukrtOwER7dQZs4uhOmwYQD+4DStSf5Le1UA1yr9cEoikkedL75QXOTjEZEDcNz8cxQAwNJx2rThFmTwf/wsgR/qX3z+A6JwYmnElph7MyHAs2XIHuFAHYFaChhOd1AcIkGaGS6hw4fKvGooUy6JHds1ramo9OZTCxnFTk/PudQohEhJbE1yUtLhoGk= petero@LAD"
}

data "aws_ami" "amazon-linux-2" {
    #provider = aws.west
    most_recent = true
    #owners = ["amazon"]
  filter {
    name    = "owner-alias"
    values   = ["amazon"]
  }  

  filter {
    name    = "name"
    values   = ["amzn2-ami-hvm*"]
  }  
}

resource "aws_instance" "my_server" {
  ami            = "${data.aws_ami.amazon-linux-2.id}"
  #instance_type  = "t2.micro"
  instance_type  = var.instance_type
  key_name       = "${aws_key_pair.deployer.key_name}"
  vpc_security_group_ids = [ aws_security_group.sg_my_server.id ]
  user_data = data.template_file.user_data.rendered

      tags = {
    Name = var.server_name
  }
}

resource "terraform_data" "status" {
   provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.my_server.id}"
   }
   depends_on = [
    aws_instance.my_server
    ]
}

resource "aws_security_group" "sg_my_server" {
  name        = "sg_my_server"
  description = "Allow TLS inbound traffic on my Security Group"
  vpc_id      = data.aws_vpc.main.id
  #vpc_id      = data.aws_vpc.id

  }

resource "aws_vpc_security_group_ingress_rule" "allow_tls_http"  {
  security_group_id =  aws_security_group.sg_my_server.id 
  cidr_ipv4         = "0.0.0.0/0"
  #cidr_ipv6         = []
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  description       = "HTTP"
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ssh"  {
  security_group_id = aws_security_group.sg_my_server.id
  #vpc_security_group_ids = [ aws_security_group.sg_my_server.id ]
  cidr_ipv4         = var.my_ip_with_cidr
  #cidr_ipv4         = "90.196.111.10/32"
 # cidr_ipv6         = []
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  description       = "SSH"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.sg_my_server.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

