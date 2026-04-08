# OpenClaw × Claude Code 도입 가이드

> Azure Terraform 예시로 배운 Claude Code 개념들을 OpenClaw 프로젝트에 적용하는 실전 가이드

---

## 목표

단순한 코딩 어시스턴트를 넘어,  
**"OpenClaw의 비즈니스 도메인, 인프라, 배포 프로세스, 팀 컨벤션을 모두 숙지한 시니어 개발자"** 를 프로젝트에 상주시키는 것.

---

## 1. CLAUDE.md — OpenClaw 컨텍스트 주입

### 역할
매 대화마다 Claude가 자동으로 읽는 온보딩 문서.  
"이 프로젝트가 무엇인지, 어떤 규칙으로 움직이는지"를 항상 인지시킨다.

### Terraform 예시와의 차이

| Terraform 예시 | OpenClaw 적용 |
|----------------|-------------|
| 인프라 모듈/변수 설명 | 서비스 아키텍처 + 비즈니스 도메인 설명 |
| 환경(dev/staging/prod) 구분 | API 명세, 데이터 모델 참조 |
| 명명 규칙 (리소스 그룹명 등) | 코딩 컨벤션, 폴더 구조 원칙 |

### 적용 예시

```markdown
# OpenClaw 프로젝트 지시사항

## 프로젝트 개요
- 서비스: OpenClaw 플랫폼 (SaaS)
- 프론트엔드: React / Next.js (App Router)
- 백엔드: Spring Boot 3.x
- DB: PostgreSQL + Redis (캐시)
- 배포: GitHub Actions → AWS ECS

## 핵심 참조 파일
See @src/types/index.ts for 도메인 타입 정의
See @docs/api-spec.md for API 명세

## 코딩 규칙
- 컴포넌트는 반드시 기능 단위 폴더로 분리 (src/features/)
- Service 레이어에서만 비즈니스 로직 처리
- API 응답은 공통 ResponseDto 형식 준수
```

### 핵심 포인트
- `@파일경로` 문법으로 타입 정의, API 명세를 자동 인클루드
- Claude가 매 대화마다 OpenClaw의 데이터 구조를 꿰뚫고 시작
- 도메인 지식 + 스타일 가이드를 한 곳에서 관리

---

## 2. Skills — OpenClaw 개발 워크플로우 표준화

### 역할
반복되는 개발/테스트/배포 절차를 `/명령어` 하나로 묶는다.

### Terraform 예시와의 차이

| Terraform 예시 | OpenClaw 적용 |
|----------------|-------------|
| /tf-plan (fmt→checkov→plan→비용) | /oclaw-test (테스트 실행→커버리지→케이스 보완) |
| /tf-apply (plan 검토→apply→검증) | /oclaw-build (빌드→에러 분석→해결책 제안) |
| /tf-validate (fmt+tflint+checkov) | /oclaw-pr-review (변경 요약→컨벤션 검토→PR 초안) |

### 추천 스킬 설계

#### `/oclaw-test [기능명]`
```
1. 해당 기능 관련 테스트 파일 탐색
2. 단위 테스트 실행
3. 커버리지 보고서 분석
4. 누락된 케이스 식별 후 테스트 코드 보완
```

#### `/oclaw-build`
```
1. 빌드 실행 (mvn build / npm run build)
2. 에러 로그 파싱 및 원인 분석
3. 수정 방안 즉시 제안 및 적용
```

#### `/oclaw-pr-review`
```
1. 현재 브랜치 변경사항 요약 (git diff main)
2. OpenClaw 코딩 컨벤션 준수 여부 검토
3. 보안/성능 이슈 체크
4. PR 본문 초안 자동 작성
```

#### `/oclaw-feature [기능명]`
```
1. 기능 요구사항 분석
2. 영향 받는 파일/모듈 탐색
3. 구현 계획 수립 후 사용자 확인
4. 코드 생성 (Controller → Service → Repository 순)
5. 테스트 코드 생성
```

---

## 3. Hooks — OpenClaw 안전망 및 품질 강제

### 역할
명령 실행 전후를 가로채어 실수를 방지하고 품질을 자동으로 유지한다.

### Terraform 예시와의 차이

| Terraform 예시 | OpenClaw 적용 |
|----------------|-------------|
| pre-destroy-guard (destroy 차단) | 운영 DB 직접 쿼리 차단 |
| post-apply-snapshot (state 저장) | 핵심 파일 수정 후 린트 자동 실행 |
| post-tf-edit-review (코드 리뷰 트리거) | 서비스/컨트롤러 수정 시 아키텍처 검토 |

### 추천 훅 설계

#### PreToolUse — DB 보호 훅
```bash
# 운영 DB에 대한 위험 쿼리 차단
# UPDATE/DELETE without WHERE, DROP TABLE 등 감지 시 실행 차단
```

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": ".claude/hooks/pre-db-guard.sh"
      }]
    }]
  }
}
```

#### PostToolUse — 코드 품질 자동 검증
```bash
# .java, .ts, .tsx 파일 수정 후 자동 실행
# - ESLint / Checkstyle 실행
# - 오류 발견 시 Claude가 즉시 수정
```

#### PostToolUse — 보안 민감 파일 감지
```bash
# 인증/인가 관련 파일(AuthService, JwtFilter 등) 수정 시
# security-agent 자동 트리거
```

---

## 4. Agents — OpenClaw 전문 파트 위임

### 역할
메인 Claude가 모든 것을 처리하지 않고, 특화된 서브 에이전트에게 위임한다.

### Terraform 예시와의 차이

| Terraform 예시 | OpenClaw 적용 |
|----------------|-------------|
| terraform-reviewer | openclaw-architect-agent (설계 원칙 검토) |
| azure-validator | openclaw-security-agent (보안 취약점 점검) |
| cost-optimizer | openclaw-db-optimizer (쿼리 성능 최적화) |
| plan-validator | openclaw-test-validator (테스트 커버리지 검증) |

### 추천 에이전트 설계

#### `openclaw-architect-agent`
- 트리거: 새 파일 생성 또는 핵심 레이어 파일 수정 시
- 역할: 클린 아키텍처 원칙 준수 여부, 의존성 방향, 레이어 침범 감지

#### `openclaw-security-agent`
- 트리거: 인증/인가/암호화 관련 코드 수정 시
- 역할: 하드코딩된 시크릿, 취약한 JWT 로직, SQL Injection 가능성 점검

#### `openclaw-db-optimizer`
- 트리거: Repository/Query 파일 수정 시
- 역할: N+1 쿼리 감지, 인덱스 활용 여부, 실행 계획 예측

#### `openclaw-test-validator`
- 트리거: 기능 구현 완료 후
- 역할: 테스트 커버리지 분석, 엣지 케이스 누락 여부, 통합 테스트 필요성 판단

---

## 5. MCP Servers — OpenClaw 도구 생태계 연동

### 역할
OpenClaw가 실제로 의존하는 외부 시스템에 Claude를 직접 연결한다.

### Terraform 예시와의 차이

| Terraform 예시 | OpenClaw 적용 |
|----------------|-------------|
| Azure MCP (리소스 상태 확인) | Database MCP (스키마/데이터 조회) |
| Terraform MCP (plan/apply) | Jira/Linear MCP (이슈 기반 개발) |
| GitHub MCP (커밋/PR) | GitHub MCP (동일) + APM MCP |

### 추천 MCP 연동

#### Jira / Linear MCP
```
"오늘 내 할당 이슈 목록 보여줘"
"OC-1234 이슈 내용 기반으로 API 만들어줘"
"구현 완료, 이슈 Done으로 변경해줘"
```

#### Database MCP (개발 DB)
```
"users 테이블 스키마 확인하고 DTO 만들어줘"
"현재 데이터 기반으로 테스트 픽스처 생성해줘"
"이 쿼리 실행 계획 분석해줘"
```

#### Log / APM MCP (CloudWatch, Datadog)
```
"어제 발생한 로그인 오류 원인 찾아줘"
"응답 지연이 급증한 시점 전후 로그 분석해줘"
"특정 사용자 ID의 요청 흐름 추적해줘"
```

---

## 6. .claudeignore — 컨텍스트 최적화

### 역할
불필요한 파일을 컨텍스트에서 제거해 토큰 낭비를 막고 응답 품질을 높인다.

### OpenClaw 적용 예시

```gitignore
# 의존성
node_modules/
.gradle/
build/
dist/
.next/
target/

# 캐시
__pycache__/
.cache/
*.class

# 환경 변수 (민감 정보)
.env
.env.local
.env.production
application-secret.yml

# 빌드 산출물
*.jar
*.war
*.map

# 로그
logs/
*.log

# 교육 자료 (컨텍스트 제외)
edu_docs/
```

---

## 전체 아키텍처 조감도

```
CLAUDE.md                          ← OpenClaw 도메인 지식 상시 주입
    ├── @src/types/index.ts        ← 타입 자동 참조
    └── @docs/api-spec.md          ← API 명세 자동 참조

Skills (개발자 명령)
    ├── /oclaw-feature  → 기능 구현 자동화
    ├── /oclaw-test     → 테스트 실행 + 보완
    ├── /oclaw-build    → 빌드 + 에러 분석
    └── /oclaw-pr-review → PR 초안 자동 작성
            └→ openclaw-architect-agent (설계 검토)
            └→ openclaw-security-agent  (보안 점검)

Hooks (자동 안전망)
    ├── PreToolUse   → 운영 DB 쿼리 차단
    └── PostToolUse  → 린트 자동 실행, 에이전트 트리거

Agents (전문 위임)
    ├── openclaw-architect-agent  ← 설계 원칙 검토
    ├── openclaw-security-agent   ← 보안 취약점 점검
    ├── openclaw-db-optimizer     ← 쿼리 성능 최적화
    └── openclaw-test-validator   ← 테스트 커버리지 검증

MCP Servers (외부 연결)
    ├── GitHub MCP    ← PR/이슈 자동화
    ├── Jira MCP      ← 이슈 기반 개발
    ├── Database MCP  ← 스키마/데이터 조회
    └── APM MCP       ← 로그/성능 분석
```

---

## 도입 우선순위 추천

| 단계 | 항목 | 이유 |
|------|------|------|
| 1순위 | CLAUDE.md 작성 | 모든 것의 기반, 즉시 효과 체감 |
| 2순위 | .claudeignore 설정 | 토큰 절약, 빠른 응답 |
| 3순위 | /oclaw-pr-review 스킬 | 반복 업무 즉시 자동화 |
| 4순위 | PostToolUse 훅 (린트) | 코드 품질 자동 유지 |
| 5순위 | openclaw-security-agent | 보안 사고 사전 방지 |
| 6순위 | MCP 연동 (Jira, DB) | 고급 자동화로 생산성 극대화 |
