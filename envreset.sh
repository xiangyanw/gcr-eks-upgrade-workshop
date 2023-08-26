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

kubectl delete -f ~/environment/long-live-connection-demo/
kubectl delete -f ~/environment/ingress-nginx-1.5.1.yaml

EBS_CSI_ARN=$(aws eks describe-addon --addon-name aws-ebs-csi-driver --cluster-name ${EKS_CLUSTER_NAME} \
  --region ${AWS_REGION} --query 'addon.addonArn')

if [[ ! -z "${EBS_CSI_ARN}" ]]; then
  echo "Deleting EKS addon aws-ebs-csi-driver ..."
  
  aws eks delete-addon --addon-name aws-ebs-csi-driver --cluster-name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}
fi

IRSA=$(eksctl get iamserviceaccount --name ebs-csi-controller-sa --namespace kube-system \
  --cluster ${EKS_CLUSTER_NAME} --region ${AWS_REGION} | grep ebs-csi-controller-sa)

if [[ ! -z "${IRSA}" ]]; then
  echo "Deleting iamserviceaccount ebs-csi-controller-sa ..."
  eksctl delete iamserviceaccount --name ebs-csi-controller-sa --namespace kube-system \
    --cluster ${EKS_CLUSTER_NAME} --region ${AWS_REGION}
fi

IRSA=$(eksctl get iamserviceaccount --name aws-load-balancer-controller --namespace kube-system \
  --cluster ${EKS_CLUSTER_NAME} --region ${AWS_REGION} | grep aws-load-balancer-controller)

if [[ ! -z "${IRSA}" ]]; then
  echo "Deleting iamserviceaccount aws-load-balancer-controller ..."
  eksctl delete iamserviceaccount --name aws-load-balancer-controller --namespace kube-system \
    --cluster ${EKS_CLUSTER_NAME} --region ${AWS_REGION}
fi

helm -n kube-system uninstall aws-load-balancer-controller

# eksctl delete nodegroup \
#   --name umng \
#   --cluster ${EKS_CLUSTER_NAME} \
#   --region ${AWS_REGION}

# eksctl scale nodegroup --name tomcat --nodes 1 --cluster ${EKS_CLUSTER_NAME} --region ${AWS_REGION}
# aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME --nodegroup-name tomcat

eksctl scale nodegroup --name default --nodes 3 --cluster ${EKS_CLUSTER_NAME} --region ${AWS_REGION}
aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME --nodegroup-name default

ARN=$(aws eks describe-nodegroup --nodegroup-name tomcat --cluster-name ${EKS_CLUSTER_NAME} --region ${AWS_REGION} --query 'nodegroup.nodegroupArn')

if [[ ! -z "${ARN}" ]]; then
  echo "Deleting nodegroup tomcat ..."
  eksctl delete nodegroup --name tomcat --cluster ${EKS_CLUSTER_NAME} --region ${AWS_REGION}
fi

ARN=$(aws eks describe-nodegroup --nodegroup-name lbc --cluster-name ${EKS_CLUSTER_NAME} --region ${AWS_REGION} --query 'nodegroup.nodegroupArn')

if [[ ! -z "${ARN}" ]]; then
  echo "Deleting nodegroup lbc ..."
  eksctl delete nodegroup --name lbc --cluster ${EKS_CLUSTER_NAME} --region ${AWS_REGION}
fi

ARN=$(aws eks describe-nodegroup --nodegroup-name umng --cluster-name ${EKS_CLUSTER_NAME} --region ${AWS_REGION} --query 'nodegroup.nodegroupArn')

if [[ ! -z "${ARN}" ]]; then
  echo "Deleting nodegroup umng ..."
  eksctl delete nodegroup --name umng --cluster ${EKS_CLUSTER_NAME} --region ${AWS_REGION}
fi
