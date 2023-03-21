## Deploy EKS, XC CE and then Helm for Sentence App

To create the AWS environment (VPC, subnest and EKS cluster (single node)) and the XC CE site:

- Modify vars.tf.example and rename to vars.tf

- terraform init

- terraform apply

To deploy Sentence App using helm:

- cd ./helm

- terraform init

- terraform apply

To get the kubeconfig.yaml for EKS, 

For Volterra cert auth .p12. need to:

	export VES_P12_PASSWORD=<cert passphrase>
