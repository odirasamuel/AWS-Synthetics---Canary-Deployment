# AWS-Synthetics---Canary-Deployment
Synthetic monitoring via Canary Deployment

# Introduction 
This project provides a terraform module to provision AWS Synthetics Canary resources along with necessary IAM roles, S3 buckets, CloudWatch Alarms and SNS topics to monitor and manage canary runs.

# Overview
## Directories
* **canary_scripts**: This contains sub-folders with unique canary scripts grouped by products. 
    * The canary script by default can be generated via the AWS CloudWatch Synthetic Recorder chrome browser plugin.
    * The canary script sub-folder under the right product must be named in this convention;
    > `<customer_name>`_`<instance>`_`<canary_type>`
    * The script's name should be the same as the `async function` in the script and canary lambda entry point `<script_name>.handler` 
* **modules**: This contains the module for deplying a synthetic canary.
* **policies**: This contains the policies defined for the canary IAM role.
* **product**: This represent the root modules from where the child module will be called from, grouped by the product type also. This is the folder where the terraform commands to deploy the canary are run.
* **state_backend**: This contains the configuration for provisioning a state backend for managing and securing terraform state.
* **zipped_canary_scripts**: This contains the zipped version of the canary script's sub-folder which is what is used in the module to deploy canary, also grouped by product type.

# Prerequisites
1. AWS CLI configured with the necessary permissions, prefarably `version 2`
2. Terraform installed, at least `version 1.5.0`

# Usage
To deploy a canary;
1. Create a sub-folder in the `canary_scripts` folder under product with the required naming convention and structure.
2. Ensure the canary script (`.js` file) is properly formatted and the conditions stated above in [Directories](#directories) is adhered to.
3. Duplicate this block of code under the right product the url belong to in the `product` folder and modify the variables as best suited. The module name should follow this convention;
> `environment`_`customer_name`_`classification`_`canary_type`_canary
```terraform
module "<environment>_<customer_name>_<classification>_<canary_type>_canary" {
  source                 = "../../modules/deploy_canary"
  aws_region             = "<value>"
  environment            = "<value>"
  customer_name          = "<value>"
  cluster                = "<value>"
  isVip                  = <value>
  classification         = "<value>"
  canary_type            = "<value>"
  endpoint               = "<value>"
  protocol               = "<value>"
  unit                   = "<value>"
  stat                   = "<value>"
  period                 = <value>
  namespace              = "<value>"
  metric_name            = "<value>"
  metric_query_id        = "<value>"
  threshold              = <value>
  treat_missing_data     = "<value>"
  evaluation_periods     = <value>
  datapoints_to_alarm    = <value>
  comparison_operator    = "<value>"
  alarm_description      = "<value>"
  location               = "<value>"
  group                  = "<value>"
  secret_name            = "<value>"
  start_canary           = <value>
  create_cw_metric_alarm = <value>
  product                = <value>
}
```
4. Run `terraform fmt` to format the changes made.
5. Run `terraform init` to initialize the terraform directory.
6. Run `terraform plan -out tf_plan` to view the plan of the changes/deployment to be made.
7. Run `terraform apply "tf_plan"` to deploy the plan.

> For more details of the variables values, refer to the module's variable definitions. Module's variables can be overriden by specifying a different value for the module in the above block of code.