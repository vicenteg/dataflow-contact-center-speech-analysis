
# Purpose

This directory contains a method to install the Speech Analytics Framework.

# How to Use

# Get Terraform and Terragrunt

If you're using Cloud Shell, `terraform` should already be installed.

If not, install it:

https://learn.hashicorp.com/tutorials/terraform/install-cli

Install terragrunt:

```
curl -LO https://github.com/gruntwork-io/terragrunt/releases/download/v0.24.4/terragrunt_linux_amd64
chmod +x terragrunt_linux_amd64
mkdir -p $HOME/bin
mv terragrunt_linux_amd64 $HOME/bin/terragrunt
```


# Configure

In this directory, create a `terraform.tvars` file that contains values for required variables. 

Example:

```
project_id = "my-project-id"
region     = "us-central1"
saf_flex_template_image     = "gcr.io/my-project-id/saf_dataflow"
```

Create a file `terragrunt.hcl` that contains values for the Terraform state backend, substituting your project
ID and your bucket:

```
remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    project        = "my-project-id"
    bucket         = "my-bucket"
    prefix         = "terraform/state"
  }
}
```

# Run

```
terragrunt apply
```

