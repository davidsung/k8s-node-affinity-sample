# Use `NodeAffinity` to restrict pods scheduling in specific AZ on a EKS Cluster with Managed Node Group
1. Copy the example tf variables to terraform.tfvars
```sh
cd terraform
cp example.tfvars terraform.tfvars
```

2. Modify the value of `aws_destination_profile` to your own AWS Profile Name specified in `~/.aws/config`

3. Terraforming
```sh
terraform init
terraform plan
terraform apply
```
After 10-15mins, a EKS cluster with a Managed Node Group should be provisioned. The Managed Node Group should contain 3 nodes with instance type `t3.medium` spanning across 3 AZs

4. Update kubeconfig
```
aws eks update-kubeconfig --name $(terraform output cluster_name)
```

5. Confirmed the nodes are provisioned
```
kubectl get no --show-labels
```
Check the value of the key `failure-domain.beta.kubernetes.io/zone` for each node. All values should be different, e.g. ap-northeast-1a, ap-northeast-1c, ap-northeast-1d. It means the managed node group is spanning across all AZs.

6. Deploy some workloads
```
kubectl apply -f ../kustomize/deployment.yaml
```

7. Scale the deployment to 6 replicas
```
kubectl scale deployment/podinfo --replicas=6
```

8. Check which node all the pods running on
```
kubectl get pods -o custom-columns=Name:.metadata.name,Node:.spec.nodeName
```
You should find that all pods are scheduled to run on the same node

9. Check the availability zone of that particular node
```
aws ec2 describe-instances --filters "Name=private-dns-name,Values=<THE NAME SHOWN ABOVE IN THE NODE>" | jq '.Reservations[].Instances[].Placement.AvailabilityZone'
```
You will find the result AZ should match the one we specified in the `affinity:` section of the `Deployment` (kustomize/deployment.yaml) declaration. Kubernetes will only run the pods on the specified AZ. 

*Please take note that the key `failure-domain.beta.kubernetes.io/zone` will change to `topology.kubernetes.io/zone` from k8s v1.17 onwards (EKS latest version is v1.16)*