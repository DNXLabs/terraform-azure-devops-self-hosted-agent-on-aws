#resource "aws_autoscaling_group" "asg" {
#  count = var.instance_count
#  name  = "${var.name}-${var.cluster_name}-${count.index}"

 # max_size         = var.asg_max_size
 # min_size         = var.asg_min_size
 # desired_capacity = var.asg_desired_size

 # vpc_zone_identifier = var.instances_subnet

 # launch_template {
 #   name    = aws_launch_template.default.name
 #   version = "$Latest"
 # }

 # tags = [
 #   map("key", "Name", "value", "${var.name}", "propagate_at_launch", true)
 # ]

 # lifecycle {
 #   create_before_destroy = true
 # }
#}