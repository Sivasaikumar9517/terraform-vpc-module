locals {
    common_tags = {
        project = var.project
        environment = var.env
        Terraform = "true"
    }

    common_name_suffix = "${var.project}-${var.env}" #roboshop-dev/prod
    az-names= slice(data.aws_availability_zones.available.names, 0, 2 )

}