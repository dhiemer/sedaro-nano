locals {
  sites = {
    sedaro-nano = {
      url      = "sedaro-nano.daveops.pro"
      Priority = 200
      Port     = 3030
    }
  }
}

#####################################
# ALB Security Group
#####################################
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow inbound traffic to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "sedaro-alb-sg"
  }
}

#####################################
# Application Load Balancer
#####################################
resource "aws_lb" "alb" {
  name               = "sedaro-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  tags = {
    Name = "sedaro-alb"
  }
}

#####################################
# Target Group for Web (NodePort 30080)
#####################################
resource "aws_lb_target_group" "sedaro_nano_web" {
  name        = "sedaro-nano-web"
  port        = 30080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "30080"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name = "sedaro-nano-web"
  }
}

#####################################
# Target Group for App (NodePort 30081)
#####################################
resource "aws_lb_target_group" "sedaro_nano_app" {
  name        = "sedaro-nano-app"
  port        = 30081
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "30081"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name = "sedaro-nano-app"
  }
}

#####################################
# HTTP Listener (Redirect to HTTPS)
#####################################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

#####################################
# HTTPS Listener
#####################################
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:032021926264:certificate/61734d9b-fb9f-4b91-b120-58c475678c4a"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sedaro_nano_web.arn
  }
}

#####################################
# Listener Rule: /api → App (port 30081)
#####################################
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sedaro_nano_app.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

#####################################
# Listener Rule: / → Web (port 30080)
#####################################
resource "aws_lb_listener_rule" "web" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sedaro_nano_web.arn
  }

  condition {
    host_header {
      values = ["sedaro-nano.daveops.pro"]
    }
  }
}
