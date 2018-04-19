provider "aws"{
  region = "us-east-1"
  access_key = "AKIAI3J3SM4LDP67TT2Q"
  secret_key = "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"
}

# 
# PostReader API
#
resource "aws_api_gateway_rest_api" "PostReaderAPI"{
  name = "PostReaderAPI"
  description = "It is the API used for Dairy Project"
}

resource "aws_api_gateway_resource" "PostReaderResource"{
  rest_api_id = "${aws_api_gateway_rest_api.PostReaderAPI.id}"
  parent_id = "${aws_api_gateway_rest_api.PostReaderAPI.root_resource_id}"
  path_part = "mypostreaderresource"
}

#
# Staging to Dev
#

resource "aws_api_gateway_deployment" "dev_deployment" {
  depends_on = ["aws_api_gateway_integration.PostReaderIntegration"]
  rest_api_id = "${aws_api_gateway_rest_api.PostReaderAPI.id}"
  stage_name = "dev"
}

#
# Get Posts Method
#
resource "aws_api_gateway_method" "PostReaderGETMethod"{
  rest_api_id = "${aws_api_gateway_rest_api.PostReaderAPI.id}"
  resource_id = "${aws_api_gateway_resource.PostReaderResource.id}"
  http_method = "GET"
  authorization = "NONE"

  request_parameters = { "method.request.querystring.postId" = false,
    "method.request.querystring.user" = false,
    "method.request.querystring.time" = false
   }
}

resource "aws_api_gateway_integration" "PostReaderIntegration"{
  rest_api_id = "${aws_api_gateway_rest_api.PostReaderAPI.id}"
  resource_id = "${aws_api_gateway_resource.PostReaderResource.id}"
  http_method = "${aws_api_gateway_method.PostReaderGETMethod.http_method}"
  type = "AWS"
  integration_http_method = "POST"
  uri = "arn:aws:apigateway:${var.myregion}:lambda:path/2015-03-31/functions/${aws_lambda_function.PostReader_GetPostsFunction.arn}/invocations"
}

#
# NewPosts method 
#
resource "aws_api_gateway_method" "NewPostReaderMethod"{
  rest_api_id = "${aws_api_gateway_rest_api.PostReaderAPI.id}"
  resource_id = "${aws_api_gateway_resource.PostReaderResource.id}"
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "NewPostReaderIntegration"{
  rest_api_id = "${aws_api_gateway_rest_api.PostReaderAPI.id}"
  resource_id = "${aws_api_gateway_resource.PostReaderResource.id}"
  http_method = "${aws_api_gateway_method.NewPostReaderMethod.http_method}"
  type = "AWS"
  integration_http_method = "POST"
  uri = "arn:aws:apigateway:${var.myregion}:lambda:path/2015-03-31/functions/${aws_lambda_function.PostReader_NewPostsFunction.arn}/invocations"
}

#
# SNS Topic
#
resource "aws_sns_topic" "new_posts" {
  name = "new-posts"
}

#
# GetPosts Lambda Function
#
data "archive_file" "lambda_zip" {
    type        = "zip"
    source_dir  = "source"
    output_path = "PostReader_GetPosts.zip"
}

resource "aws_lambda_function" "PostReader_GetPostsFunction"{
  filename = "PostReader_GetPosts.zip"
  function_name = "PostReader_GetPosts"
  role = "${aws_iam_role.lambdarole.arn}"
  handler = "lambda.lambda_handler"
  runtime = "python2.7"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"

  environment {
    variables = {
      DB_TABLE_NAME = "Posts"
    }
  }
}

resource "aws_lambda_permission" "apigw_persmission"{
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.PostReader_GetPostsFunction.arn}"
  principal = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.PostReaderAPI.id}/*/${aws_api_gateway_method.PostReaderGETMethod.http_method}${aws_api_gateway_resource.PostReaderResource.path}"
}

#
# NewPosts Lambda Function
#
data "archive_file" "newposts_lambda_zip" {
    type        = "zip"
    source_dir  = "newposts_source"
    output_path = "PostReader_NewPosts.zip"
}

resource "aws_iam_role" "lambdarole" {
  name = "myrole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["sts:AssumeRole"],
      "Principal": {
        "Service": ["lambda.amazonaws.com","dynamodb.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
} 

resource "aws_lambda_function" "PostReader_NewPostsFunction"{
  filename = "PostReader_NewPosts.zip"
  function_name = "PostReader_NewPosts"
  role = "${aws_iam_role.lambdarole.arn}"
  handler = "lambda.lambda_handler"
  runtime = "python2.7"
  source_code_hash = "${data.archive_file.newposts_lambda_zip.output_base64sha256}"

  environment {
    variables = {
      DB_TABLE_NAME = "Posts"
      SNS_TOPIC = "${aws_sns_topic.new_posts.name}"
    }
  }
}

resource "aws_lambda_permission" "apigw_persmission_newposts"{
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.PostReader_NewPostsFunction.arn}"
  principal = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.PostReaderAPI.id}/*/${aws_api_gateway_method.PostReaderGETMethod.http_method}${aws_api_gateway_resource.PostReaderResource.path}"
}

#
# S3 bucket for website
#
resource "aws_s3_bucket" "aa-diary-website"{
  bucket = "aa-diary-website-2"
  acl = "public-read"
}

data "aws_iam_user" "user" {
  user_name = "api-user"
}

resource "aws_iam_user_policy" "api-user_policy"{
  name = "api-user-policy"
  user = "api-user"

  policy= <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::aa-diary-website-2",
        "arn:aws:s3:::aa-diary-website-2/*",
        "arn:aws:s3:::aa-diary-mp3s-2",
        "arn:aws:s3:::aa-diary-mp3s-2/*"
      ]
    }
  ]
}
EOF
}

resource "aws_s3_bucket" "aa-diary-mp3s"{
  bucket = "aa-diary-mp3s-2"
  acl = "private"
}

resource "aws_s3_bucket_object" "website-index"{
  bucket = "aa-diary-website-2"
  key    = "index.html"
  source = "/Users/ptata/AdvancedAliens/aa-diary-website/index.html"
  etag = "${md5(file("/Users/ptata/AdvancedAliens/aa-diary-website/index.html"))}"
  acl = "public-read"
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "website-scripts"{
  bucket = "aa-diary-website-2"
  key = "scripts.js"
  source = "/Users/ptata/AdvancedAliens/aa-diary-website/scripts.js"
  etag = "${md5(file("/Users/ptata/AdvancedAliens/aa-diary-website/scripts.js"))}"
  acl = "public-read"
}

resource "aws_s3_bucket_object" "website-styles"{
  bucket = "aa-diary-website-2"
  key = "styles.css"
  source = "/Users/ptata/AdvancedAliens/aa-diary-website/styles.css"
  etag = "${md5(file("/Users/ptata/AdvancedAliens/aa-diary-website/styles.css"))}"
  acl = "public-read"
}
