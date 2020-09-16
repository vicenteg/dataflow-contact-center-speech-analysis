variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "region" {
  type        = string
  description = "The region in which to provision resources."
}

variable "saf_flex_template_image" {
  description = "Where the flex template image should be pushed after build."
  type        = string
}

