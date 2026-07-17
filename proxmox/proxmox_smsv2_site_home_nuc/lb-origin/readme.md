# F5 XC No-Code Terraform Module Example

## *** ARCH ***

- Need to deploy sentence app sites (AWS/EKS and Azure/AKS)
- need to deploy NUC site for BGP advertisment into my home network for VIPs (192.168.10.x)
- update the helm to deploy all microservices.
- modify the vars.auto.tfvars to point at the frontend service IPs and port.
- second LB can point at Azure SMSv2 site nginx instances in peer-1 and peer-2 VNets.

## How to use this example (XC Administrator)

- In [lb-origin.tf](./modules/no-code/lb-origin.tf) update the references for your:
	- Organisation WAF policy `volterra_http_loadbalancer.lb.app_firewall.name`
	- User Identification Policy `volterra_http_loadbalancer.lb.user_identification.name`
- Update this readme for use by your application teams
- Commit to your private git repo.


## How to use this example (Application Team)

- Fork the repo
- Rename `vars.auto.tfvars.example` to `vars.auto.tfvars` and then update the variables as necessary.
- For F5 XC API cert auth, obtain a new .p12 from the F5 XC console.  Store.  Reference the location in the `volt_api_p12_file` variable.  Then set the .p12 passphrase as ENV:

	`export VES_P12_PASSWORD=<cert passphrase>`

- Initialise, plan and apply terraform in the usual way.