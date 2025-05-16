# Provision a GCP VPC, GKE Cluster & XC GCP Site

1. gcloud auth login --project f5-gcs-4261-sales-emea-sa 

2. cd infra-deploy 

3. tfa

4. To get kubeconfig:  
    gcloud container clusters get-credentials $(terraform output -raw kubernetes_cluster_name) --region $(terraform output -raw region)

- Then you can deploy sentence app adjectives with helm (`cd ../helm` and `tfa`)
- Then cd ../infra... and `kubectl apply -f xc_site_gcp.yaml`
- check progress of `vp-manager-*` pod/s with `k get pod -n ves-system -o=wide`
- check for pending site registration in XC console, then accept all 3 registrations (change cluster to 3 in each registration).
- check pod logs with `kubectl logs vp-manager-0 -n ves-system`
