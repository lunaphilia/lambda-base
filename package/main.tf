
resource "aws_ecr_repository" "package" {
  name = "package"
}

data "aws_ecr_authorization_token" "token" {}