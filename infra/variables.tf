variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "Name prefix used for all resources"
  type        = string
  default     = "sewalink"
}

variable "instance_type" {
  description = "EC2 instance type. t4g.micro is the cheapest arm64 option that comfortably runs Rails + Postgres. Bump to t4g.small if you hit OOM issues."
  type        = string
  default     = "t4g.micro"
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB (gp3, cheapest volume type)"
  type        = number
  default     = 20
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH into the instance. Restrict this to your own IP (e.g. 1.2.3.4/32) instead of leaving it open."
  type        = string
  default     = "0.0.0.0/0"
}

variable "github_repo" {
  description = "GitHub repo in owner/name form to clone and deploy"
  type        = string
  default     = "nirojsapkota/sewalink"
}

variable "github_pat" {
  description = "GitHub Personal Access Token with repo read access, required only if the repository is private. Leave empty for a public repo."
  type        = string
  default     = ""
  sensitive   = true
}

variable "rails_master_key" {
  description = "Contents of config/master.key, required to decrypt Rails credentials in production"
  type        = string
  sensitive   = true
}
