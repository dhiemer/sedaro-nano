locals {
  sites = {
    sedaro-demo = {
      url      = "sedaro-demo.daveops.pro"
      Priority = 200
      Port     = 30080
    }
  }
}



# ALB Security Group
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

# Application Load Balancer
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


##################################
# Listeners

# HTTP Listener (Redirect to HTTPS)
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

# HTTPS Listener 
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06" # ENFORCE TLS1.2!!!
  certificate_arn   = data.aws_acm_certificate.wildcard.arn # Using exiting, thus using data block

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404 Not Found"
      status_code  = "404"
    }
  }
}




##################################
# Target Groups

resource "aws_lb_target_group" "target_group" {
  for_each = local.sites
  name     = each.key
  port     = each.value.Port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = each.value.Port
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    matcher             = "200"

  }
}




##################################
# Listener Rules 

resource "aws_lb_listener_rule" "web_rule" {
  for_each     = local.sites
  listener_arn = aws_lb_listener.https.arn
  priority     = each.value.Priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[each.key].arn
  }

  condition {
    host_header {
      values = [each.value.url]
    }
  }
}


##################################
# Target Group Attachments

resource "aws_alb_target_group_attachment" "tg_kube_tgattachment" {
  for_each         = local.sites
  target_group_arn = aws_lb_target_group.target_group[each.key].arn
  target_id        = aws_instance.k3s_server.id
  port             = each.value.Port

}

