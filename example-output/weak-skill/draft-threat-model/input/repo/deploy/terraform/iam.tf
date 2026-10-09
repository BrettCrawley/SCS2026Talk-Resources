# One role for both services. Splitting them was on the list and did not happen.
resource "aws_iam_role" "assistant_pilot" {
  name               = "assistant-pilot"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust.json
}

resource "aws_iam_role_policy" "assistant_secrets" {
  role = aws_iam_role.assistant_pilot.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        # Every assistant secret, including both provider keys and all five
        # connector credentials.
        Resource = "arn:aws:secretsmanager:eu-west-1:000000000000:secret:assistant/*"
      }
    ]
  })
}
