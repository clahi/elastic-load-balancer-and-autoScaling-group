resource "aws_key_pair" "demo-key" {
  key_name   = "demo-key"
  public_key = file("${path.module}/demo-key.pub")
}

resource "aws_security_group" "allow-http" {
  name        = "allow-http"
  description = "Allow http from the internet"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "allow-http"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow-http" {
  security_group_id = aws_security_group.allow-http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow-http" {
  security_group_id = aws_security_group.allow-http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}


resource "aws_vpc_security_group_ingress_rule" "allow-ssh" {
  security_group_id = aws_security_group.allow-http.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

data "aws_ami" "amazon-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}


resource "aws_launch_template" "ec2_launch_template" {
  name = "ec2_launch_template"
  image_id = data.aws_ami.amazon-linux.id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.allow-http.id]

  key_name = aws_key_pair.demo-key.key_name
  user_data = filebase64("scripts/user_data.sh")
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name = "autoscaling_group"
  desired_capacity = 2
  max_size = 2
  min_size = 2

  launch_template {
    id = aws_launch_template.ec2_launch_template.id
    version = "$Latest"
  }
}