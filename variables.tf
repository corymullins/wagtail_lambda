variable region {
  type = string
  default = "us-east-1"
  description = "AWS Region"
}

variable name_prefix {
  type = string
  default = "wagtail"
  description = "Prefix applied to the name of most resources"
}

variable environment_tag {
  type = string
  default = "wagtail"
  description = "Environment tag applied to most resources"
}

variable vpc_cidr_block {
  type = string
  default = "172.32.0.0/16"
  description = "Private IPv4 address space for the VPC"
}

variable default_from_email {
  type = string
  default = "cory@cmullins.tech"
  description = "Email address to send from; also used as the default initial superuser email address"
}

variable "endpoint" {
  type        = string
  default = "wagtail.corymullins.com"
  description = "endpoint URL"
}

variable "domain_name" {
  type = string
  default = "corymullins.com"
  description = "domain URL"
}