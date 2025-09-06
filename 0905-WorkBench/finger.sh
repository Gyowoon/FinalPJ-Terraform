#!/bin/bash
# fingerprint_verification.sh

SSH_KEY="./mybastion"

echo "=== SSH 키 지문 검증 ==="

# 1. 로컬 키의 다양한 지문 형식 생성
echo "1. 로컬 SSH 키 지문들:"
echo "   SHA256 (Base64): $(ssh-keygen -lf "$SSH_KEY" | awk '{print $2}')"
echo "   MD5 (Hex):       $(ssh-keygen -E md5 -lf "$SSH_KEY" | awk '{print $2}' | cut -d: -f2-)"

# 2. OpenSSL을 통한 지문 생성 (AWS import 형식)
echo "   AWS Import MD5:  $(openssl rsa -in "$SSH_KEY" -pubout -outform DER 2>/dev/null | openssl md5 -c | awk '{print $2}')"

# 3. EC2에서 보고된 지문과 비교
EC2_FINGERPRINT="66:cd:46:74:03:8b:0c:41:b2:e8:84:13:93:a3:1e:e4:13:6c:12:06:45:e5:e6:df:66:f1:56:1f:83:db:91:54"
echo -e "\n2. EC2 인스턴스 등록 지문:"
echo "   EC2 Reported:    $EC2_FINGERPRINT"

# 4. 지문 형식 변환 및 비교
echo -e "\n3. 지문 비교:"
LOCAL_MD5=$(ssh-keygen -E md5 -lf "$SSH_KEY" | awk '{print $2}' | cut -d: -f2-)
if [[ "$LOCAL_MD5" == "$EC2_FINGERPRINT" ]]; then
    echo "   ✅ MD5 지문 일치"
else
    echo "   ❌ MD5 지문 불일치"
    echo "   로컬: $LOCAL_MD5"
    echo "   EC2:  $EC2_FINGERPRINT"
fi

# 5. Base64 to Hex 변환 시도
SSH_CLIENT_FINGERPRINT="Zs1GdAOLDEGy6IQTk6Me5BNsEgZF5ebfZvFWH4PbkVQ"
echo -e "\n4. SHA256 지문 분석:"
echo "   SSH Client:      SHA256:$SSH_CLIENT_FINGERPRINT"
echo "   로컬 SSH-KEYGEN: $(ssh-keygen -lf "$SSH_KEY" | awk '{print $2}')"

