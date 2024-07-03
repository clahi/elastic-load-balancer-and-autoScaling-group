# elastic-load-balancer-and-autoScaling-group
Creating an AWS CodeDeploy to manage the deployment of a web app on web-app servers in an autoscaling group behind an application load balancer.

# Terraform
The whole infrastructure is managed by Terrafor, so that it can be easily maintainced and replicated.

## An Application Load Balancer
Created a load balancer which will balance the traffic between the servers inside an autoscaling group. I chose an application load balancer as my type of load balancer.

## AutoScaling Group
The autoScaling group automatically spins up and down servers for us according to the usage.

## S3
We will use and s3 bucket to store our code and updates.

## AWS CodeDeploy
We will be installing a CodeDeploy agent onto our servers in the autoScaling group to automatically deploy code in S3. We need to give the EC2 servers a role which allows them to read code from s3. 
Also the CodeDeploy service will also require a role inroder to deploy the code on s3.
