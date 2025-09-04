#!/usr/bin/env bash
set -euo pipefail

# ===== 사용자 변수 =====
HZ_ID="Z076855811XMR50K5FM98"      # Route 53 Hosted Zone ID (공개 HZ)
RECORD_NAME="shop.gyowoon.shop"    # 등록할 FQDN
NAMESPACE="shop"                   # Ingress가 있는 네임스페이스
INGRESS_NAME="shop-ingress"        # Ingress 이름
REGION="${REGION:-ap-northeast-2}" # AWS 리전 (환경변수 REGION 우선)

# ===== 체크: AWS/K8s 컨텍스트 =====
aws sts get-caller-identity >/dev/null
kubectl cluster-info >/dev/null

echo "==> Waiting for Ingress LoadBalancer hostname ..."
ING_HOST=""
for i in {1..40}; do
  ING_HOST=$(kubectl -n "${NAMESPACE}" get ingress "${INGRESS_NAME}" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  if [[ -n "${ING_HOST}" ]]; then
    echo "    Ingress hostname: ${ING_HOST}"
    break
  fi
  printf "    not ready yet, retrying (%02d/40)...\n" "$i"
  sleep 6
done

if [[ -z "${ING_HOST}" ]]; then
  echo "❌ Ingress의 LoadBalancer 주소를 가져오지 못했습니다. (ALB 미생성)"
  exit 1
fi

# ===== ALB 정보 조회 (CanonicalHostedZoneId/Name) =====
# DNSName으로 ALB 찾기
ALB_NAME=$(aws elbv2 describe-load-balancers --region "${REGION}" \
  --query "LoadBalancers[?DNSName=='${ING_HOST}'].LoadBalancerName" \
  --output text)

if [[ -z "${ALB_NAME}" || "${ALB_NAME}" == "None" ]]; then
  echo "❌ ALB 이름을 찾지 못했습니다. DNSName='${ING_HOST}'"
  exit 1
fi
echo "==> Target ALB Name: ${ALB_NAME}"

ALB_HZID=$(aws elbv2 describe-load-balancers --region "${REGION}" --names "${ALB_NAME}" \
  --query "LoadBalancers[0].CanonicalHostedZoneId" --output text)
if [[ -z "${ALB_HZID}" || "${ALB_HZID}" == "None" ]]; then
  echo "❌ ALB HostedZoneId 조회 실패"
  exit 1
fi
echo "==> ALB HostedZoneId: ${ALB_HZID}"

# ===== Route53 UPSERT A Alias (IPv4 only) =====
# - Alias이므로 TTL은 무시됨
# - EvaluateTargetHealth는 보통 true 권장
CHANGE_BATCH_FILE=$(mktemp)
cat > "${CHANGE_BATCH_FILE}" <<JSON
{
  "Comment": "UPSERT A alias to ALB for ${RECORD_NAME}",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${RECORD_NAME}",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "${ALB_HZID}",
          "DNSName": "${ING_HOST}",
          "EvaluateTargetHealth": true
        }
      }
    }
  ]
}
JSON

echo "==> Applying Route53 change (UPSERT) ..."
CHANGE_ID=$(aws route53 change-resource-record-sets \
  --hosted-zone-id "${HZ_ID}" \
  --change-batch "file://${CHANGE_BATCH_FILE}" \
  --query 'ChangeInfo.Id' --output text)

echo "==> Waiting Route53 change to INSYNC ..."
aws route53 wait resource-record-sets-changed --id "${CHANGE_ID}"
echo "✅ Route53 A(ALIAs) record is in sync."

echo "==> Current record set:"
aws route53 list-resource-record-sets --hosted-zone-id "${HZ_ID}" \
  --query "ResourceRecordSets[?Name=='${RECORD_NAME}.']"

