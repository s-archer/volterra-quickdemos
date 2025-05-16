# Deployment Details

The repo deploys the following components:
  - Azure Resource Group, VNet, 3 subnets (outside, inside, workers) 
  - F5 Distributed Cloud CE (node count depends on value of `f5xc_sms_node_count` variable, and automatically distributed across AZs)
  

# Instructions for Deployment

This sub-repo deploys F5 Distributed Cloud CE(s) into Azure using Secure Site Mesh version 2 (SMSv2).

## Obtain and configure Azure credentials

For Volterra cert auth .p12. need to:

	export VES_P12_PASSWORD=<cert passphrase>

To apply terraform, either reference the below vars as environment variables or reference a separate credentials file:

terraform apply -var-file=../../../creds/azure_creds.tfvars 

The creds.tfvars file must contain four variables defined like this :

subscription_id = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
client_secret   = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
client_id       = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
tenant_id       = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

In order to populate these variables, you need to configure API access to your Azure account:

 - within the Azure Active Directory create a new 'App' on the 'App Registration' page.
 - within the new 'App' you just created, create a new Client Secret.  The value must be saved, as you cannot retrieve it again:  
   - this value is your "${client_secret}".
 - the 'App' overview page will provide:
   - the 'Application (client) ID' is your ${client_id}"
   - the 'Directory (tenant) ID' is your ${tenant_id}"
 - 'Expose an API' by adding a 'Scope' and a 'Client Application', with the latter referencing your 'Application (client) ID'.
 - if you type 'subscriptions' into the search box at the top of the Azure Portal, you can find your Subscription ID:
  - the 'Subscription ID' is your ${subscription_id}"
- within your subscription, go to 'Access Control (IAM)' and 'Role Assignments'.  Add a Role Assignment and give your 'App' the 'Contributor Role'. 

## Prepare variables

Rename the `vars.tf.example` as `vars.tf` and update the values as far as `f5xc_sms_storage_account_type`.  The remaining vars do not need to be modified, but can be if required.

## Obtain XC API Token

https://docs.cloud.f5.com/docs-v2/administration/how-tos/user-mgmt/Credentials?searchQuery=credentials
