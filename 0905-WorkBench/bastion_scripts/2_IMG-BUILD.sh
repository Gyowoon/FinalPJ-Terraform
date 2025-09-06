# Check out $ <...> ECR_REGISTRY, IMAGE_TAG is configured 
# Caution: Path-Sensitive 
# 2. Build and push backend image
echo "[Remote] Building backend image"
cd backend
sudo docker build -t shop-backend:"$IMAGE_TAG" \
  -t "$ECR_REGISTRY/shop-backend:$IMAGE_TAG" \
  -t "$ECR_REGISTRY/shop-backend:latest" .
sudo docker push "$ECR_REGISTRY/shop-backend:$IMAGE_TAG"
sudo docker push "$ECR_REGISTRY/shop-backend:latest"
cd ..

# 3. Build and push frontend image
echo "[Remote] Building frontend image"
cd frontend
sudo docker build -t shop-frontend:"$IMAGE_TAG" \
  -t "$ECR_REGISTRY/shop-frontend:$IMAGE_TAG" \
  -t "$ECR_REGISTRY/shop-frontend:latest" .
sudo docker push "$ECR_REGISTRY/shop-frontend:$IMAGE_TAG"
sudo docker push "$ECR_REGISTRY/shop-frontend:latest"
cd ..

