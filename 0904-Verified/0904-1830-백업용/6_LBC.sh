#!/usr/bin/env bash
set -euo pipefail

: "${CLUSTER_NAME:?CLUSTER_NAME is required}"
: "${REGION:?REGION is required}"

echo "[LBC] region=$REGION, cluster=$CLUSTER_NAME"

#-----------------------------
# 1) LBC IAM Policy (없으면 생성, 있으면 재사용)
#-----------------------------
if ! aws iam list-policies --scope Local \
  --query "Policies[?PolicyName=='AWSLoadBalancerControllerIAMPolicy'].Arn | [0]" \
  --output text | grep -q '^arn:'; then
  curl -sS -o iam_policy.json \
    https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.13.4/docs/install/iam_policy.json
  aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json >/dev/null
fi

POLICY_ARN=$(aws iam list-policies --scope Local \
  --query "Policies[?PolicyName=='AWSLoadBalancerControllerIAMPolicy'].Arn | [0]" \
  --output text)
echo "[LBC] POLICY_ARN=${POLICY_ARN}"

#-----------------------------
# 2) LBC용 IAM Role (없으면 생성)
#-----------------------------
ROLE_NAME=AmazonEKSLoadBalancerControllerRole
if ! aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  cat > lbc-trust.json <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "pods.eks.amazonaws.com" },
    "Action": [ "sts:AssumeRole", "sts:TagSession" ]
  }]
}
JSON
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document file://lbc-trust.json >/dev/null
fi

# 정책이 안 붙어 있으면 부착
if ! aws iam list-attached-role-policies --role-name "$ROLE_NAME" \
  --query "AttachedPolicies[?PolicyName=='AWSLoadBalancerControllerIAMPolicy']" \
  --output text | grep -q . ; then
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY_ARN"
fi

ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
echo "[LBC] ROLE_ARN=${ROLE_ARN}"

#-----------------------------
# 3) (중요) SA를 '미리' 생성  ### CHANGED
#    Helm이 만드는 SA를 쓰지 않고, 우리가 만든 SA를 재사용하게 해서
#    PIA를 '먼저' 연결하도록 함.
#-----------------------------
kubectl -n kube-system get sa aws-load-balancer-controller >/dev/null 2>&1 || \
kubectl -n kube-system create sa aws-load-balancer-controller

#-----------------------------
# 4) PIA 연결(이미 있으면 통과)  ### CHANGED
#-----------------------------
if ! aws eks list-pod-identity-associations \
    --cluster-name "$CLUSTER_NAME" --region "$REGION" \
    --query "associations[?serviceAccount=='aws-load-balancer-controller' && namespace=='kube-system'] | length(@)" \
    --output text | grep -q '^1$'; then
  aws eks create-pod-identity-association \
    --cluster-name "$CLUSTER_NAME" \
    --namespace kube-system \
    --service-account aws-load-balancer-controller \
    --role-arn "$ROLE_ARN" >/dev/null || true
fi

aws eks list-pod-identity-associations \
  --cluster-name "$CLUSTER_NAME" --region "$REGION" \
  --query "associations[?serviceAccount=='aws-load-balancer-controller' && namespace=='kube-system']"

#-----------------------------
# 5) Helm으로 LBC 설치하되, 우리가 만든 SA 재사용  ### CHANGED
#-----------------------------
helm repo add eks https://aws.github.io/eks-charts >/dev/null || true
helm repo update >/dev/null

VPC_ID=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" \
          --query "cluster.resourcesVpcConfig.vpcId" --output text)

helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system --create-namespace \
  --set clusterName="$CLUSTER_NAME" \
  --set region="$REGION" \
  --set vpcId="$VPC_ID" \
  --set serviceAccount.create=false \           # 우리가 만든 SA 사용
  --set serviceAccount.name=aws-load-balancer-controller

#-----------------------------
# 6) 컨트롤러 정상 롤아웃 대기
#   (PIA를 먼저 걸고 배포했기 때문에 보통 재시작 불필요)  ### CHANGED
#-----------------------------
kubectl -n kube-system rollout status deploy/aws-load-balancer-controller --timeout=5m

#-----------------------------
# 7) Webhook 서비스 Endpoint 준비 대기(유효성 검사 실패 방지)  ### CHANGED
#-----------------------------
echo "[LBC] Waiting for webhook endpoints..."
for i in {1..60}; do
  if kubectl -n kube-system get endpoints aws-load-balancer-webhook-service \
      -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null | grep -q '.'; then
    echo "[LBC] Webhook endpoints are ready."
    break
  fi
  sleep 3
done

#-----------------------------
# 8) 간단 검증
#-----------------------------
kubectl -n kube-system get sa aws-load-balancer-controller
kubectl -n kube-system get deploy aws-load-balancer-controller
kubectl -n kube-system get svc aws-load-balancer-webhook-service || true

echo "[LBC] Done."

