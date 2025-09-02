# 초기 검증 및 실행 절차
1. aws configure
2. aws sts get-caller-identity
## 필요 시, 코드 내용 수정
3. terraform init
4. terraform plan
5. terraform apply
- 삭제 시)terraform destory 
- 수동으로 변경한 리소스를 state 파일에 반영시키려면)terraform refresh


# 기타
- 사용자가 변수의 값을 특정하고 싶을 때, .tfvars 파일을 사용한다
- 사용자가 출력값을 변수처럼 사용하고 싶을 때, terraform output 명령을 이용하여 outputs.tf에 명시된 값들을 참조할 수 있다 ➡️ (단, terraform.tfstate 파일에 접근할 수 있어야 함)

# 실행 후 확인 절차
- 웹 콘솔에서, main.tf에 정의된 리소스들이 생성되었는지 확인한다 

## 주의 
- Route 53, ECR, S3 등 일부 리소스들은 별도로 관리(생성/수정/삭제) 되며, 변경 시 해당 코드에 영향을 고려해야 한다
- 실행 후 사용자가 수동으로 추가/삭제한 리소스들은 terraform destroy 시 의도치 않은 동작을 발생시킬 수 있다 
- ⚠️ ALB 수동으로 삭제해야 한다

# 클러스터 실행 후 참고할만한 명령어 
## 1. 노드 상태확인
 ```bash
 kubectl get nodes # 클러스터의 모든 노드에 대한 정보 조회 
 kubectl describe node <노드명> # 특정 노드의 상세 정보
 kubectl get node -o wide # 특정 노드의 상세 정보  
 kubectl top node # 노드의 리소스 사용량 확인 
 ```
## 2. 파드 상태 확인
```bash
 kubectl get pods # 클러스터 내 모든 파드 정보 확인
 kubectl describe pod <파드명> # 특정 파드 정보 상세 확인 
 kubectl get services # 클러스터 내 모든 서비스 정보 확인 
```

 로드밸런서 타겟그룹 상태확인: `aws elbv2 describe-target-health --target-group-arn`
- k8s 내부 상태 확인
    - `kubectl get -n <네임스페이스> all` # 해당 네임스페이스 리소스 전부 확인 
    - `kubectl describe pod <파드이름>` # 해당 파드 상세정보 확인 
    - `kubectl get pods -l <셀렉터=레이블>` # 특정 라벨만 가지는 파드만 조회 
    - `kubectl get node -o wide` #



## 2. 