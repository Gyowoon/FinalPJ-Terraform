# Check The $<...> REGION, ECR_REGISTRY
# 1. Authenticate to ECR and create repositories if needed
aws ecr get-login-password --region "$REGION" | sudo docker login --username AWS --password-stdin "$ECR_REGISTRY"

if ! aws ecr describe-repositories --repository-names shop-backend --region "$REGION" >/dev/null 2>&1; then
  aws ecr create-repository --repository-name shop-backend --region "$REGION"
fi
if ! aws ecr describe-repositories --repository-names shop-frontend --region "$REGION" >/dev/null 2>&1; then
  aws ecr create-repository --repository-name shop-frontend --region "$REGION"
fi

