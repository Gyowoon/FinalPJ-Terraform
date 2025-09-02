# Gyowoon Edited @08/31
## Bastion 파일 
- 해당 파일 내부의 컨텐츠는 Bastion EC2 Instance 생성 이후 xShell 등으로 접속하고,  xftp 등으로 ~/ec2-user 아래에 배치해야 한다
- ⚠️⚠️ Terraform 파일 내용을 이용해 AWS 리소스가 생성된 이후 생성된 tfstate 파일을 Bastion 파일 내부에 배치해야 한다 ⚠️⚠️

## Terrafrom  파일
- 해당 파일 내부의 컨텐츠를 이용하여 
1. VPC 1개 (Subnet 4개, RTB 2개, NAT/EIP/IGW 각 1개, )
2. Bastion EC2 (t3.micro + al2023-ami-minimal-2023.8.20250818.0-kernel-6.1-x86_64 + Public SN 아래에 1개, 자동으로 EKS Cluster 전용 보안그룹(eks-cluster-sg)까지 추가)
3. EKS Cluster (m7i-flex.large + amazon-eks-node-al2023-x86_64-standard-1.33-v20250821 + Worker Node 4대)
4. RDS(MySQL) + 기본 DB 생성(shopdb) + 관리자ID/PW는 admin/passWord
5. ElastiCache(Redis) 
이 자동으로 생성됨을 확인할 수 있어야 한다


~~⚠️ 삭제 시 다음을 <수동으로>삭제해야 한다~~
1. Route 53 > Hosted zones > 사용중인 퍼블릭 호스트 존 > ALB에 등록했던 A레코드
2. 


