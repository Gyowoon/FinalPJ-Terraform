# 8. Create application secret containing DB and Redis connection strings
DB_URI="mysql+pymysql://${DB_MASTER_USERNAME}:${DB_MASTER_PASSWORD}@${RDS_ENDPOINT}:3306/${DB_NAME}?charset=utf8mb4"
REDIS_URL="redis://${REDIS_ENDPOINT}:6379"

if [[ -z "$JWT_SECRET_KEY" ]]; then
  # Generate a random JWT secret if one was not provided
  JWT_SECRET_KEY=$(openssl rand -hex 32)
fi

kubectl delete secret shop-secrets -n shop >/dev/null 2>&1 || true
kubectl create secret generic shop-secrets -n shop \
  --from-literal=DB_URI="$DB_URI" \
  --from-literal=REDIS_URL="$REDIS_URL" \
  --from-literal=JWT_SECRET_KEY="$JWT_SECRET_KEY"

