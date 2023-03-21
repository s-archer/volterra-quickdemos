## Deploy EKS, XC CE and then Helm for Sentence App

To create the AWS environment (VPC, subnest and EKS cluster (single node)) and the XC CE site:

- login to XC and create and download a .p12 API Certificate and specifiy a passphrase

- on the CLI issue the command `export VES_P12_PASSWORD=<cert passphrase>` using the passphrase created in the previous step

- Rename `vars.tf.example` to `vars.tf` and update (make sure point relevant var to the location of your .p12 API Certificate file) 

- cd ./infra-deploy

- terraform init

- terraform apply

To deploy Sentence App using helm:

- cd ../helm

- terraform init

- terraform apply


To deploy Sentence App LB & Origin:

- cd ../lb-and-origin

- terraform init

- terraform apply