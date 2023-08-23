#!/bin/bash

#export EKS_CLUSTER_NAME="eks-workshop"
export ACCOUNT_ID=`aws sts get-caller-identity --query 'Account' --output text`

WRK_DIR=`dirname $0`
cd ${WRK_DIR}

kubectl delete -f ~/environment/apps/k6.yaml
kubectl delete -f ~/environment/apps/nginx.yaml
kubectl delete -f ~/environment/apps/tomcat.yaml
kubectl delete -f ~/environment/apps/namespaces.yaml
kubectl delete -f ~/environment/apps/hpa.yam

kubectl delete ingress ingress-httpd
kubectl delete -f ~/environment/ingress-nginx-1.5.1.yaml
kubectl delete deployment httpd
kubectl delete svc httpd

eksctl delete iamserviceaccount --name aws-load-balancer-controller --namespace kube-system \
  --cluster ${EKS_CLUSTER_NAME} --region ${AWS_REGION}

helm -n kube-system uninstall aws-load-balancer-controller

eksctl delete nodegroup \
  --name umng \
  --cluster ${EKS_CLUSTER_NAME} \
  --region ${AWS_REGION}

# eksctl scale nodegroup --name tomcat --nodes 1 --cluster ${EKS_CLUSTER_NAME} --region ${AWS_REGION}
# aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME --nodegroup-name tomcat

eksctl scale nodegroup --name default --nodes 3 --cluster ${EKS_CLUSTER_NAME} --region ${AWS_REGION}
aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME --nodegroup-name default

eksctl delete nodegroup --name tomcat --cluster ${EKS_CLUSTER_NAME} --region ${AWS_REGION}
eksctl delete nodegroup --name lbc --cluster ${EKS_CLUSTER_NAME} --region ${AWS_REGION}
eksctl delete nodegroup --name umng --cluster ${EKS_CLUSTER_NAME} --region ${AWS_REGION}

