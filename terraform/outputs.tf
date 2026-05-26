output "dynamodb_table" {
  value = aws_dynamodb_table.users.name
}
