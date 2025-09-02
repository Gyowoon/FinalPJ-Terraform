# 1) kubeconfig 
`aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME`

1. kubectl 명령어가 참조할 클러스터를 지정
2. 실행 시 kubeconfig 파일이 수정됨, 이전에 입력한 환경변수를 바탕으로 EKS Cluster를 연결 
3. 실행 후 연결 여부 확인은 kubectl config current-context 또는 kubectl config get-contexts  

# 2-1) LBC(로드밸런서 컨트롤러) Role용 Policy 준비(존재하면 재사용)

```bash
if ! aws iam list-policies --scope Local --query "Policies[?PolicyName=='AWSLoadBalancerControllerIAMPolicy'].Arn | [0]" --output text | grep -q 'arn:'; then
  curl -sS -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.13.4/docs/install/iam_policy.json
  aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json >/dev/null
fi
POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='AWSLoadBalancerControllerIAMPolicy'].Arn | [0]" --output text)
```
1. 조건문을 이용하여 연결된 AWS 계정에 해당 Poilcy 없으면 만들고, 있으면 변수화 시켜서 사용함 
2. 로드밸런서 컨트롤러란, AWS EKS 환경의 K8S Resource(Service,Ingress)에 따라 AWS ELB를 자동으로 생성 및 관리해주는 객체
3. 실행 후 정상생성 확인은 `kubectl [get|descrive] [svc|ingress] -n <네임스페이스>`


# 2-2) Pod Identity용 IAM Role 생성(존재하면 스킵)
```bash
ROLE_NAME=AmazonEKSLoadBalancerControllerRole
if ! aws iam get-role --role-name $ROLE_NAME >/dev/null 2>&1; then
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
  aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://lbc-trust.json >/dev/null
  aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY_ARN
fi
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)
```

1. 조건문을 사용해 연결된 AWS 계정의 LBC용 Role 유무 조회 및 없으면 <직전 생성(2-1)Policy 부여>
2. 조회(1)후 있으면, fi 직후의 ROLE_ARN 변수 저장
3. cf. `if <abc> then ... fi <def>` 의 경우 <abc>가 거짓(false)일 때 then 블록 건너뛰고 fi 이후를 실행함


# 2-3) Helm으로 LBC 설치(기본 ServiceAccount 사용) 
```bash
helm repo add eks https://aws.github.io/eks-charts >/dev/null
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system --create-namespace \
  --set clusterName=$CLUSTER_NAME \
  --set region=$REGION \
  --set vpcId=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION \
  --query "cluster.resourcesVpcConfig.vpcId" --output text)
```

1. helm이 사용할 레포 추가
2. Helm 차트(eks/aws-load-balancer-controller)를 aws-load-balancer-controller라는 Release 이름으로 설치(없으면 새로 설치, 있으면 업그레이드)
    - upgrade -i 플래그는 install/upgrade를 동시에 처리
3. 설치할 k8s의 네임스페이스 지정 (없으면 자동 생성`--create-namespace`)
4. Helm Chart에 등록할 클러스터/리젼/VPCID를 현재 쉘 환경변수 및 AWS 연동을 참고 

- Helm이란, k8s에서 사용하는 패키지 설치/삭제 등 관리를 돕는 패키지 매니져(dnf,pip,apt 에 대응)
- Helm Chart란, k8s 리소스 파일(YAML)집합(Set)을 하나의 패키지로 저장해 둔 것 ➡️ *미리 정의된 템플릿 & 변수/설정이 포함되어 다양한 배포 환경에서 쉽게 재사용 가능하다는 장점이 있음*
- Helm Chart는 쿠버네티스 애플리케이션을 빠르게, 표준화해서 배포할 수 있게 해주는 배포 패키지 (deb, rpm 에 대응 [pre-build package])


# 2-4) SA와 Role을 Pod Identity Association으로 연결(중복 생성 시 에러 무시)
```bash
aws eks create-pod-identity-association \
  --cluster-name $CLUSTER_NAME \
  --namespace kube-system \
  --service-account aws-load-balancer-controller \
  --role-arn $ROLE_ARN >/dev/null || true

kubectl -n kube-system rollout status deploy/aws-load-balancer-controller --timeout=3m
```
1. EKS Pod Identity 기능, 해당 k8s SA(aws-load-balancer-controller)에 AWS IAM Role을(2-2생성) 연결
2. rollout(배포) 상태를 확인함 ➡️ 정상 연동 및 SA 배포를 점검함 
- cf. rollout이란, k8s가 앱 업데이트/배포를 점진적으로(Gradually) 적용시키는 행위/과정을 의미
    - 롤아웃을 통해 서비스의 중단 없이 점진적으로 새 버젼의 앱을 배포 가능
    - 기존 Pod와 새 Pod가 공존하다가, 기존 Pod를 하나씩 종료함 
    - Rolling 전략이라고도 하며, 배포 절차에 대한 이력관리 기능 지원(Revision)

# 3) 앱 컨테이너 이미지 빌드/푸시 (ECR) 
```bash
aws ecr create-repository --repository-name shop-frontend --region $REGION >/dev/null 2>&1 || true
aws ecr create-repository --repository-name shop-backend  --region $REGION >/dev/null 2>&1 || true

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
```

1. AWS 계정의 ECR을 새로 생성(없을 경우) 시도, 각각 프론트엔드 Pod 이미지 저장용
2. 상동, 백엔드 이미지 Pod 저장용 
3. 해당 ECR에 로그인 


## 로컬에 소스가 있다고 가정: ./shop-eks/{frontend,backend}
```bash
#pushd shop-eks/frontend
#docker build -t $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/shop-frontend:latest .
#docker push    $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/shop-frontend:latest
#popd

#pushd shop-eks/backend
#docker build -t $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/shop-backend:latest .
#docker push    $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/shop-backend:latest
#popd
```
- 당장은 사용 안함 



# ~~4) 네임스페이스/시크릿/매니페스트 적용~~ 
➡️ setup_bastion.sh 를 이용할 것 !
~~시크릿(이미 있으면 스킵, 값은 미리 채워두기)~~

``` bash
# kubectl apply -f shop-eks/k8s/namespaces.yaml
# kubectl -n shop create secret generic shop-secrets \
#  --from-literal=DB_URI="mysql+pymysql://shopuser:<DB-PASSWORD>@<RDS-ENDPOINT>:3306/shopdb" \
#  --from-literal=JWT_SECRET_KEY="<YOUR-JWT-SECRET>" \
#  --from-literal=REDIS_URL="redis://<REDIS-ENDPOINT>:6379/0" \
#  --dry-run=client -o yaml | kubectl apply -f -
```


# 5) ECR 이미지 경로 치환(최초 1회만)
- 해당 작업은 경로에 유의해야함, (`/home/ec2-user/shop-eks`)

```bash
ECR="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
sed -i "s#<ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com#$ECR#g" shop-eks/k8s/backend-deployment.yaml shop-eks/k8s/frontend-deployment.yaml

# Ingress Host를 내 도메인으로 교체  4.에서 setup_bastion.sh 적용 시 필요 없음 ⚠️⚠️
sed -i "s/host: shop\.example\.com/host: $FQDN/" shop-eks/k8s/ingress.yaml
```


# 6) 배포 (경로 유의)
```bash
kubectl apply -f shop-eks/k8s/backend-deployment.yaml
kubectl apply -f shop-eks/k8s/backend-service.yaml
kubectl apply -f shop-eks/k8s/frontend-deployment.yaml
kubectl apply -f shop-eks/k8s/frontend-service.yaml
kubectl apply -f shop-eks/k8s/ingress.yaml
```

# 7) Route 53 의 A-ALIAS 추가 (shop.gyowoon.shop → ALB) 
```bash
HZ_ID=$(aws route53 list-hosted-zones-by-name --dns-name $DOMAIN --query 'HostedZones[0].Id' --output text)
ALB_DNS=$(kubectl -n shop get ingress shop-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
# ALB HostedZoneId 구하기
ALB_HZ=$(aws elbv2 describe-load-balancers --names $(echo $ALB_DNS | cut -d'-' -f1-3) --region $REGION \
  --query 'LoadBalancers[0].CanonicalHostedZoneId' --output text 2>/dev/null || true)
# HostedZoneId 조회가 이름 기반으로 실패할 수 있어, 보조 방식(전체 검색)
if [ "$ALB_HZ" = "None" ] || [ -z "$ALB_HZ" ]; then
  ALB_HZ=$(aws elbv2 describe-load-balancers --region $REGION \
    --query "LoadBalancers[?DNSName=='$ALB_DNS'].CanonicalHostedZoneId | [0]" --output text)
fi

cat > /tmp/rr.json <<JSON
{
  "Comment": "Alias to ALB for $FQDN",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$FQDN",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "$ALB_HZ",
        "DNSName": "$ALB_DNS",
        "EvaluateTargetHealth": false
      }
    }
  }]
}
JSON
aws route53 change-resource-record-sets --hosted-zone-id $HZ_ID --change-batch file:///tmp/rr.json >/dev/null

echo "[OK] Visit: http://$FQDN
```
