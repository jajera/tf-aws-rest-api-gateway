resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

data "archive_file" "create_function" {
  type        = "zip"
  output_path = "${path.module}/external/create_function.zip"
  source_file = "${path.module}/external/create/app.py"
}

data "archive_file" "list_function" {
  type        = "zip"
  output_path = "${path.module}/external/list_function.zip"
  source_file = "${path.module}/external/list/app.py"
}

output "suffix" {
  value = random_string.suffix.result
}
