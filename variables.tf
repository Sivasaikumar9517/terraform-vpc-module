variable "vpc_cidr" {
  type        = string
 
}

variable "project" {
    type = string
}

variable "env" {
    type = string
}

variable "vpc_tags" {
    default = {}
}

variable "igw_tags" {
    default = {}
}

variable "public_cidr_tags" {
    default = {}
}


variable "public_cidr" {
    type = list
}

variable "private_cidr_tags" {
    default = {}
}

variable "private_cidr" {
    type = list
}

variable "database_cidr_tags" {
    default = {}
}
variable "database_cidr" {
    type = list
}