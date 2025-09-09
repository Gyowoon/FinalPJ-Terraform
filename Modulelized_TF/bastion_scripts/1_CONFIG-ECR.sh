# Check The $<...> REGION, ECR_REGISTRY
# 정상적으로 ECR 레지스트리가 생성되었는지 확인하고, 없으면 생성함, 로그인 가능여부 확인

aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME" --alias "$CLUSTER_NAME"
aws ecr get-login-password --region "$REGION" | sudo docker login --username AWS --password-stdin "$ECR_REGISTRY"

if ! aws ecr describe-repositories --repository-names shop-backend --region "$REGION" >/dev/null 2>&1; then
  aws ecr create-repository --repository-name shop-backend --region "$REGION"
fi
if ! aws ecr describe-repositories --repository-names shop-frontend --region "$REGION" >/dev/null 2>&1; then
  aws ecr create-repository --repository-name shop-frontend --region "$REGION"
fi

