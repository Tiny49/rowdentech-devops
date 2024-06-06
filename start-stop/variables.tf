variable "startup_shutdown" {
  description = "Whether to deploy the startup-shutdown solution. Must have yes or no value"
  default     = "no"
}

variable "start_time_hour" {
  description = "The hour component of the time to start instances at each weekday. Must be given as an integer value in 24 hour time. Defaults to 7am."
  default     = 7
}

variable "start_time_minute" {
  description = "The minute component of the time to start instances at each weekday. Defaults to on the hour."
  default     = "00"
}

variable "stop_time_hour" {
  description = "The hour componnent of the time to stop instances at each weekday. Must be given as an integer value in 24 hour time. Defaults to 7pm."
  default     = 19
}

variable "stop_time_minute" {
  description = "The minute component of the time to stop instances at each weekday. Defaults to on the hour."
  default     = "00"
}

variable "default_shutdown" {
  description = "If set to 'yes' then this will by default shutdown all untagged instances. By default this is no."
  default     = "no"
}

variable "project" {
  description = "The name of the project."
  default     = "Rowdentech"
}
