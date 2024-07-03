resource "aws_iam_role" "codedeployService" {
  name = "codedeployService"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "codedeploy.amazonaws.com"
          ]
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "CodeDeployPolicy" {
  name = "CodeDeployPolicy"
  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        "Effect" : "Allow",
        "Action" : [
          "autoscaling:*",
          "codedeploy:*",
          "ec2:*",
          "lambda:*",
          "elasticloadbalancing:*",
          "iam:AddRoleToInstanceProfile",
          "iam:CreateInstanceProfile",
          "iam:CreateRole",
          "iam:DeleteInstanceProfile",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:GetInstanceProfile",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
          "iam:ListRoles",
          "iam:PassRole",
          "iam:PutRolePolicy",
          "iam:RemoveRoleFromInstanceProfile",
          "s3:*"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# attach AWS managed policy called AWSCodeDeployRole
# required for deployments which are to an EC2 compute platform
resource "aws_iam_role_policy_attachment" "codedeployService" {
  role       = aws_iam_role.codedeployService.name
  policy_arn = aws_iam_policy.CodeDeployPolicy.arn
}

resource "aws_codedeploy_app" "codeDeployApp" {
  compute_platform = "Server"
  name = "codeDeployApp"
}

resource "aws_codedeploy_deployment_group" "deploymentGroup" {
  app_name = aws_codedeploy_app.codeDeployApp.name
  deployment_group_name = "deploymentGroup"
  service_role_arn = aws_iam_role.codedeployService.arn

  autoscaling_groups = [aws_autoscaling_group.autoscaling_group.name]
}