variable "Machinetype" {
  description = "Machine type"
  type = string
  default = "t2.micro"
}

variable "keyname" {
  description = "Machine Key"
  type = string
  default = "vv"
}

variable "InstanceZone" {
  description = "Zone of the Instance"
  type = string
  default = "ap-south-1"
}

variable "VolumeSize" {
  description = "Size of the Machine"
  type = number
  default = 1
}
