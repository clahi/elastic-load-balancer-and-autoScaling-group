resource "aws_iam_role" "CodePipelineServiceRole" {
  name = "CodePipelineServiceRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = ["codepipeline.amazonaws.com"]
        },
        Action = "sts:AssumeRole"
      }

    ]
  })
}

resource "aws_iam_policy" "CodePipelinePolicy" {
  name   = "CodePipelinePolicy"
  policy = file("codepipeline_policy.json")
}

resource "aws_iam_role_policy_attachment" "CodePipelinePolicyAttachment" {
  role       = aws_iam_role.CodePipelineServiceRole.name
  policy_arn = aws_iam_policy.CodePipelinePolicy.arn

}

resource "aws_codepipeline" "myCodePipeline" {
  name     = "myCodePipeline"
  role_arn = aws_iam_role.CodePipelineServiceRole.arn
  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.mySourceBucket.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket    = aws_s3_bucket.mySourceBucket.bucket
        S3ObjectKey = "SampleApp_Linux.zip"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ApplicationName     = aws_codedeploy_app.codeDeployApp.name
        DeploymentGroupName = aws_codedeploy_deployment_group.deploymentGroup.deployment_group_name
      }
    }
  }
}


resource "aws_iam_role" "eventbridge_role" {
  name = "EventBridgeInvokePipelineRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "eventbridge_policy" {
  name        = "EventBridgeInvokePipelinePolicy"
  description = "Policy for EventBridge to invoke CodePipeline"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "codepipeline:StartPipelineExecution",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_attach_policy" {
  role       = aws_iam_role.eventbridge_role.name
  policy_arn = aws_iam_policy.eventbridge_policy.arn
}

resource "aws_cloudwatch_event_rule" "s3_put_object" {
  name        = "s3_put_object"
  description = "Trigger CodePipeline when a new object is created in the S3 bucket"
  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["s3.amazonaws.com"],
      "eventName" : ["PutObject"],
      "requestParameters" : {
        "bucketName" : [aws_s3_bucket.mySourceBucket.bucket]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "codepipeline_target" {
  rule      = aws_cloudwatch_event_rule.s3_put_object.name
  target_id = "CodePipeline"
  arn       = aws_codepipeline.myCodePipeline.arn
  role_arn  = aws_iam_role.eventbridge_role.arn
}