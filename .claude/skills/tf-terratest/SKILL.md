---
name: tf-terratest
description: Terratest 실행 — 모듈별 실제 Azure 리소스 생성·검증·삭제
argument-hint: "[테스트명: hub|spoke|peering|all]"
allowed-tools: Bash, Read
---

$ARGUMENTS 에 해당하는 Terratest를 실행한다. 인수가 없으면 all(전체)을 기본값으로 사용한다.

작업 디렉토리: `terraform/test`

## 테스트 대상 매핑

| 인수 | 실행 테스트 |
|------|-------------|
| hub | TestHubVNet |
| spoke | TestSpokeVNet |
| peering | TestVNetPeering |
| all (기본) | TestHubVNet\|TestSpokeVNet\|TestVNetPeering |

## 실행 전 확인

1. **Azure 로그인 상태 확인**
   ```bash
   az account show --query "{name:name, id:id}" -o table
   ```
   - 로그인 안 된 경우: "⚠️ Azure 로그인 필요 — `az login` 실행 후 재시도" 보고 후 중단

2. **Go 설치 확인**
   ```bash
   go version
   ```
   - 미설치 시: "⚠️ Go 미설치 — `brew install go` 실행 후 재시도" 보고 후 중단

3. **ARM_SUBSCRIPTION_ID 설정**
   ```bash
   export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
   ```

## 테스트 실행

```bash
export PATH=$PATH:/opt/homebrew/bin:/usr/local/go/bin
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export TF_CLI_CONFIG_FILE=$(pwd)/test.tfrc   # Nexus 미러 우회

cd terraform/test && go test -v -timeout 90m -count=1 -run "${TEST_FILTER}" ./...
```

- 전체(all): `-run "TestHubVNet|TestSpokeVNet|TestVNetPeering"`
- 단일: `-run "TestHubVNet"` 등

실행은 **백그라운드**로 띄우고 진행 상황을 주기적으로 확인한다.

## 진행 상황 모니터링

각 테스트 단계별 상태 출력:
- `terraform init` → `terraform apply` → assertion → `terraform destroy` 순서
- 현재 어느 단계인지 중간 보고

## 결과 보고

### 성공 시
```
✅ Terratest 완료

--- PASS: TestHubVNet     (N초)
--- PASS: TestVNetPeering (N초)
--- PASS: TestSpokeVNet   (N초)

총 소요: N분
```

### 실패 시
1. 실패한 테스트명과 에러 메시지 추출
2. 에러 유형 분류:
   - **네트워크 오류** (DNS, 인증): "⚠️ Azure 인증 만료 — `az login` 후 재시도"
   - **리소스 충돌**: 잔여 리소스 목록 출력 후 수동 삭제 안내
   - **assertion 실패**: 실패한 assert 내용과 실제값 출력
   - **코드 오류**: 에러 위치(파일:줄번호)와 내용 출력
3. 잔여 Azure 리소스가 있으면 목록 출력:
   ```bash
   az group list --query "[?contains(name, 'rg-test-')].name" -o tsv
   ```
   → 수동 삭제 명령 안내: `az group delete --name <RG명> --yes --no-wait`

## 주의사항

- 테스트 1회당 **실제 Azure 리소스** 생성·삭제 → 비용 발생 (VNet·NSG·RG 수분 분 과금)
- `defer terraform.Destroy` 가 cleanup 보장하나, 중단 시 RG 잔류 가능
- 순차 실행 (병렬 시 provider plugin 캐시 경합 발생)
- `test.tfrc` 는 Nexus 미러 인증서 만료 우회용 — direct 다운로드 사용
