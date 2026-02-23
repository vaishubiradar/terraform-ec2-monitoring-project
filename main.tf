provider "aws" {
  region = "ap-south-1"
}

# ----------------------------
# Security Group
# ----------------------------

resource "aws_security_group" "my_sg" {
  name        = "terraform-sg"
  description = "Allow SSH and HTTP"

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  ingress {
    description = "HTTP Access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Terraform-SG"
  }
}

# ----------------------------
# EC2 Instance
# ----------------------------

resource "aws_instance" "myec2" {
  ami                    = "ami-051a31ab2f4d498f5"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.my_sg.id]

  tags = {
    Name = "Terraform-EC2"
  }
}

# ----------------------------
# SNS Topic
# ----------------------------

resource "aws_sns_topic" "cpu_alerts" {
  name = "cpu-alert-topic"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.cpu_alerts.arn
  protocol  = "email"
  endpoint  = "vsbiradar25@gmail.com"
}

# ----------------------------
# CloudWatch Alarm
# ----------------------------

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70

  alarm_description = "Alarm when CPU exceeds 70%"

  dimensions = {
    InstanceId = aws_instance.myec2.id
  }

  alarm_actions = [aws_sns_topic.cpu_alerts.arn]
}