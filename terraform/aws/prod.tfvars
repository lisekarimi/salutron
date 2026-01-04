# terraform/aws/prod.tfvars - this file contains the variables for the production environment
project_name = "salutron"
aws_region   = "us-east-1"
custom_domain = "awsterraform.lisekarimi.com"
min_instances = 2  # Prod needs more
max_instances = 5
