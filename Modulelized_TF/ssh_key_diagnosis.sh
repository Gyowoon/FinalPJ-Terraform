#!/bin/bash
# ssh_key_diagnosis.sh

SSH_KEY="${1:-./LetMeIn.pem}" # Default path if not provided as argument


echo "=== SSH 키 파일 진단 ==="
echo "키 파일: $SSH_KEY"

# 파일 존재 여부 확인
if [[ ! -f "$SSH_KEY" ]]; then
    echo "❌ 키 파일이 존재하지 않습니다: $SSH_KEY"
    exit 1
fi

# 현재 권한 확인
echo "현재 권한: $(ls -la $SSH_KEY | awk '{print $1 " " $3 " " $4}')"

# 권한 수정
echo "권한을 400으로 수정합니다..."
chmod 400 "$SSH_KEY"
echo "수정된 권한: $(ls -la $SSH_KEY | awk '{print $1 " " $3 " " $4}')"

# 키 파일 유효성 확인
echo -e "\n키 파일 유효성 확인:"
ssh-keygen -lf "$SSH_KEY" 2>/dev/null && echo "✅ 유효한 키 파일" || echo "❌ 유효하지 않은 키 파일"

# 지문 확인 (AWS와 비교용)
echo -e "\n지문 확인:"
openssl rsa -in "$SSH_KEY" -pubout -outform DER 2>/dev/null | openssl md5 -c 2>/dev/null | awk '{print "MD5:" $0}'
