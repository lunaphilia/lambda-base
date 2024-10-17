
resource "aws_ecr_repository" "package" {
  name = "package"
}

data "archive_file" "package" {
  type        = "zip"
  output_path = "${path.module}/src.zip"
  source_dir  = "${path.module}/src"
  # excludes = setunion()
}

resource "docker_image" "package" {
  name         = "${aws_ecr_repository.package.repository_url}:latest"
  platform     = "linix/amd64"
  keep_locally = true
  build {
    context = "${path.module}/src"
  }
  triggers = {
    sha256 = data.archive_file.package.output_sha256
  }
}


resource "docker_registry_image" "package" {
  name          = docker_image.package.name
  keep_remotely = true

  triggers = {
    sha256 = data.archive_file.package.output_sha256
  }
}

resource "aws_lambda_function" "lambda" {
  function_name = "hello-world"
  role          = aws_iam_role.lambda.arn

  package_type = "Image"
  image_uri    = "${aws_ecr_repository.package.repository_url}@${docker_registry_image.package.sha256_digest}"
  publish      = true
}

resource "aws_iam_role" "lambda" {
  name               = "lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
