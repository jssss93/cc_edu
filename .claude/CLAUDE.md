# Claude Code 설정 구조

```
.claude/
├── settings.json                  # 권한, 훅, 모델 설정
├── rules/
│   ├── azure.md                   # Azure 인프라 규칙 (명명, 하드코딩 금지 등)
│   ├── terraform.md               # Terraform 작업 규칙 (fmt, checkov, plan 순서)
│   ├── mcp.md                     # MCP 활용 규칙
│   └── secrets.md                 # 민감정보 비노출 (.claudeignore 보조)
├── agents/
│   ├── azure-validator/           # 배포 후 Azure 리소스 상태 검증
│   ├── cost-optimizer/            # SKU/크기 최적화 방안 분석
│   ├── plan-validator/            # plan 결과 → 검증 체크리스트 생성
│   └── terraform-reviewer/        # tf 코드 리뷰 및 변경 영향도 분석
├── skills/
│   ├── tf-plan/                   # /tf-plan     : fmt→checkov→plan→비용분석
│   ├── tf-apply/                  # /tf-apply    : staleness 체크→apply→검증
│   ├── tf-destroy/                # /tf-destroy  : 다중 확인 후 destroy
│   ├── tf-init/                   # /tf-init     : init (로컬 state 기본, 원격 backend는 팀 선택)
│   ├── tf-validate/               # /tf-validate : fmt+tflint+checkov 빠른 검증
│   ├── miro-update/               # /miro-update : Miro 다이어그램 자동 생성
│   ├── env-diff/                  # /env-diff    : 환경 간 리소스 차이 비교
│   └── tf-terratest/              # /tf-terratest: 모듈별 Terratest(선택)
├── scripts/
│   └── memory-dir.sh              # ~/.claude/projects/…/memory 절대경로 출력 (훅·에이전트 경로 통일)
├── hooks/
│   ├── pre-destroy-guard.sh       # PreToolUse(Bash): destroy 차단
│   ├── pre-push-tf-check.sh     # PreToolUse(Bash): git push 전 TF 점검
│   ├── notify-on-tool.sh        # PreToolUse: 도구 실행 알림(async)
│   ├── post-apply-snapshot.sh     # PostToolUse(Bash): memory/terraform_state.md 갱신
│   ├── post-tf-edit-review.sh     # PostToolUse(Edit|Write): .tf 편집 후 리뷰 안내
│   └── notify-on-stop.sh          # Stop: 응답 완료 알림
```

또한 `settings.json`에 **SubagentStart**(서브에이전트 실행 알림) 훅이 있다.

`plan-validator` 체크리스트·`post-apply-snapshot` state 요약은 모두 **`bash .claude/scripts/memory-dir.sh`** 가 출력하는 `~/.claude/projects/<slug>/memory/` 에 둔다.

## 권한·비용·훅 (현재 정책 요약)

- **민감정보**: 루트 `.claudeignore` + [rules/secrets.md](rules/secrets.md). tfvars·`.env` 실값은 채팅·커밋·memory 인용 시 노출하지 않음.
- **권한**: `mcp__terraform__terraform_apply` / `mcp__terraform__terraform_destroy` 는 deny. 배포·삭제는 Bash + `/tf-apply`·`/tf-destroy` 스킬 절차. (교육안과 동일하게 MCP로 apply/destroy 하지 않음.)
- **비용**: **infracost 예상치만** (`/tf-plan`). 실비용·청구 조회는 하지 않음 — [`.claude/rules/mcp.md`](rules/mcp.md), [`.claude/rules/terraform.md`](rules/terraform.md) 참고.
- **훅**: `post-apply-snapshot.sh` 는 **`~/.claude/projects/<경로인코딩>/memory/terraform_state.md`** 갱신 후 **infracost·Miro 안내만 stdout** (자동 비용 조회·자동 Miro 생성 아님).
- **사용 원칙**: Terraform 관련 작업은 `/tf-init`, `/tf-plan`, `/tf-apply`, `/tf-destroy`, `/tf-validate` 등 스킬 경로를 우선 사용하고, 예외적인 상황이 아니라면 직접 `terraform` Bash 명령을 호출하지 않는다.
