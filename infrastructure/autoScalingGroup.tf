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

resource "aws_lb" "webServer-alb" {
  name               = "webServer-alb"
  security_groups    = [aws_security_group.allow-http.id]
  subnets            = [aws_subnet.public_subnet_1a.id, aws_subnet.public_subnet_1b.id]
  load_balancer_type = "application"
}

resource "aws_lb_target_group" "webServer-tg" {
  name     = "webServer-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "webServer-listener" {
  load_balancer_arn = aws_lb.webServer-alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webServer-tg.arn
  }
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

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  # Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_policy" {
  name        = "ec2_policy"
  description = "Policy to allow ec2 servers to read objects in s3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policy_attachmet" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_launch_template" "ec2_launch_template" {
  name          = "ec2_launch_template"
  image_id      = data.aws_ami.amazon-linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.allow-http.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  key_name  = aws_key_pair.demo-key.key_name
  user_data = filebase64("scripts/user_data.sh")
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name                = "autoscaling_group"
  vpc_zone_identifier = [aws_subnet.public_subnet_1a.id, aws_subnet.public_subnet_1b.id]

  desired_capacity = 2
  max_size         = 2
  min_size         = 2

  target_group_arns = [aws_lb_target_group.webServer-tg.arn]

  launch_template {
    id      = aws_launch_template.ec2_launch_template.id
    version = "$Latest"
  }
}