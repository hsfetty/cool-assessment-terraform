# cloud-init commands for configuring Terraformer instances

data "cloudinit_config" "terraformer_cloud_init_tasks" {
  gzip          = true
  base64_encode = true

  # Note: The filename parameters in each part below are only used to
  # name the mime-parts of the user-data.  They do not affect the
  # final name for the templates. For any x-shellscript parts, the
  # filenames will also be used as a filename in the scripts
  # directory.

  # Create a credentials file for the VNC user that can be used to
  # configure the AWS CLI to assume the Terraformer role by default
  # and other roles by selecting the correct profile.  For details,
  # see
  # https://boto3.amazonaws.com/v1/documentation/api/latest/guide/configuration.html#using-a-configuration-file
  #
  # Input variables are:
  # * aws_region - the AWS region where the roles are to be assumed
  # * permissions - the octal permissions to assign the AWS
  #   configuration
  # * read_cool_assessment_terraform_state_role_arn - the ARN of the
  #   IAM role that can be assumed to read the Terraform state of the
  #   cisagov/cool-assessment-terraform root module
  # * organization_read_role_arn - the ARN of the IAM role that can be
  #   assumed to read information about the AWS Organization to which
  #   the assessment environment belongs
  # * terraformer_role_arn - the ARN of the Terraformer role, which can
  #   be assumed to create certain resources in the assessment
  #   environment
  # * vnc_read_parameter_store_role_arn - the ARN of the role that
  #   grants read-only access to certain VNC-related SSM Parameter Store
  #   parameters, including the VNC username
  # * vnc_username_parameter_name - the name of the SSM Parameter Store
  #   parameter containing the VNC user's username
  part {
    content = templatefile(
      "${path.module}/cloud-init/write-aws-config.tpl.sh", {
        aws_region                                    = var.aws_region
        permissions                                   = "0400"
        read_cool_assessment_terraform_state_role_arn = module.read_terraform_state.role.arn
        organization_read_role_arn                    = data.terraform_remote_state.master.outputs.organizationsreadonly_role.arn
        terraformer_role_arn                          = aws_iam_role.terraformer_role.arn
        vnc_read_parameter_store_role_arn             = aws_iam_role.vnc_parameterstorereadonly_role.arn
        vnc_username_parameter_name                   = var.ssm_key_vnc_username
    })
    content_type = "text/x-shellscript"
    filename     = "write-aws-config.sh"
  }
}
