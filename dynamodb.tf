resource "aws_dynamodb_table" "post-dynamodb-table" {
  name           = "Posts"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"
  range_key      = ""

  attribute {
    name = "id"
    type = "S"
  }
/*
  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "text"
    type = "S"
  }

  attribute {
    name = "voice"
    type = "S"
  }

  attribute {
    name = "url"
    type = "S"
  }
*/
  attribute {
    name = "time"
    type = "S"
  }

  attribute {
    name = "user"
    type = "S"
  }

 /* ttl {
    attribute_name = "TimeToExist"
    enabled = false
  }
 */
  global_secondary_index {
    name               = "user-time-index"
    hash_key           = "user"
    range_key          = "time"
    write_capacity     = 5
    read_capacity      = 5
    projection_type    = "ALL"
    #non_key_attributes = ["status", "text", "voice", "url"]
  }

  tags {
    Name        = "dynamodb-table-posts"
    Environment = "dev"
  }
}
