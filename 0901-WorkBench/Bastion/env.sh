export REGION=ap-northeast-2
export ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
export CLUSTER_NAME=$(terraform output -raw cluster_name)       # 테라폼으로 생성된 EKS 클러스터
export DOMAIN=gyowoon.shop # 사용할 도메인 (쇼핑몰)
export FQDN=shop.${DOMAIN} # 풀 도메인 
export DB_MASTER_PASS="passWord" # RDS 의 관리자 비밀번호 