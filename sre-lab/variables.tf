variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  default     = "test-vpc"
}


variable "subnet_cidr_public_a" {
  description = "CIDR block for Public Subnet A"
  default     = "10.0.1.0/24"
}

variable "subnet_cidr_public_b" {
  description = "CIDR block for Public Subnet B"
  default     = "10.0.2.0/24"
}

variable "subnet_name_public_a" {
  description = "Name tag for Public Subnet A"
  default     = "PublicA"
}

variable "subnet_name_public_b" {
  description = "Name tag for Public Subnet B"
  default     = "PublicB"
}


variable "az_public_a" {
  description = "Availability Zone for Public Subnet A"
  default     = "uap-northeast-1a"
}

variable "az_public_b" {
  description = "Availability Zone for Public Subnet B"
  default     = "ap-northeast-1b"
}


variable "gateway_name" {
  description = "Name tag for the Internet Gateway"
  default     = "test-igw"
}

variable "route_table_cidr" {
  description = "CIDR block for the Route Table"
  default     = "0.0.0.0/0"
}

variable "route_table_name" {
  description = "Name tag for the Route Table"
  default     = "test-rt"
}