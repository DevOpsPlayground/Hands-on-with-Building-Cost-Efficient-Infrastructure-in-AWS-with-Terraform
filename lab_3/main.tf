resource "aws_s3_bucket" "website" {
  bucket = "playground-${var.my_panda}.devopsplayground.org"
  acl    = "public-read"

  tags = {
    ManagedBy = "terraform"
  }
  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  content      = templatefile("${path.module}/content/index.tmpl", { URL = aws_api_gateway_deployment.deployment.invoke_url })
  acl          = "public-read"
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "image" {
  bucket       = aws_s3_bucket.website.id
  key          = "image.jpeg"
  source       = "./content/image.jpeg"
  acl          = "public-read"
  content_type = "image/jpeg"
}

data "aws_route53_zone" "main" {
  name         = "devopsplayground.org"
  private_zone = false
}

resource "aws_route53_record" "link" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.my_panda
  type    = "CNAME"
  ttl     = "300"

  records = [aws_s3_bucket.website.website_endpoint]
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "./content/app.py"
  output_path = "./content/${var.my_panda}.zip"
}
resource "aws_lambda_function" "main" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "playground-${var.my_panda}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "app.lambda_handler"
  timeout          = 180
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  runtime = "python3.7"
  environment {
    variables = var.env_vars
  }
  tags = {
    "Owner" = "playground-${var.my_panda}"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "playground-${var.my_panda}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    "Owner" = "playground-${var.my_panda}"
  }
}

resource "aws_lambda_permission" "allow_apiGateway" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "playground-${var.my_panda}-api"
  description = "The api gateway for ${var.my_panda}"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.integration,
    aws_api_gateway_integration_response.response_200,
    aws_api_gateway_integration.options_integration_item
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "v1"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id        = aws_api_gateway_rest_api.api.id
  resource_id        = aws_api_gateway_rest_api.api.root_resource_id
  http_method        = "POST"
  authorization      = "NONE"
  request_parameters = { "method.request.path.proxy" = true }
}
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_rest_api.api.root_resource_id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.main.invoke_arn
  depends_on              = [aws_api_gateway_method.method]
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.method.http_method
  status_code = 200
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = true }
  depends_on          = [aws_api_gateway_method.method]
}

resource "aws_api_gateway_integration_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  depends_on = [aws_api_gateway_integration.integration]
}

resource "aws_api_gateway_method" "options_method_item" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
resource "aws_api_gateway_method_response" "options_200_item" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.options_method_item.http_method
  status_code = 200
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
  depends_on = [aws_api_gateway_method.options_method_item]
}
resource "aws_api_gateway_integration" "options_integration_item" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.options_method_item.http_method
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
  type       = "MOCK"
  depends_on = [aws_api_gateway_method.options_method_item]
}
resource "aws_api_gateway_integration_response" "options_integration_item_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.options_method_item.http_method
  status_code = aws_api_gateway_method_response.options_200_item.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,X-Amz-Security-Token,Authorization,X-Api-Key,X-Requested-With,Accept,Access-Control-Allow-Methods,Access-Control-Allow-Origin,Access-Control-Allow-Headers'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_method_response.options_200_item]
}