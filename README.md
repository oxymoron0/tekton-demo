# Tekton CI/CD Pipeline for Modern Application Deployment

이 프로젝트는 Tekton을 기반으로 CI/CD 파이프라인 예제입니다.

## 아키텍처 개요

### CI/CD 플로우
```
Git Push → Tekton Trigger → Build & Test → Image Push → Manifest Update → ArgoCD Deploy
```

### 주요 구성 요소
- **Tekton Pipelines**: CI/CD 파이프라인 실행 엔진
- **Tekton Triggers**: Git 이벤트 기반 자동 트리거
- **ArgoCD**: GitOps 기반 지속적 배포
- **Kaniko**: 컨테이너 이미지 빌드 (Docker-in-Docker 불필요)
- **Kustomize**: 환경별 매니페스트 관리

## 프로젝트 구조

```
.
├── README.md                 # 이 파일
├── scripts/
│   └── setup.sh             # 자동 설치 스크립트
├── app/                      # 샘플 Node.js 애플리케이션
│   ├── src/
│   │   └── index.js
│   ├── tests/
│   │   └── app.test.js
│   └── package.json
├── Dockerfile                # 멀티스테이지 Docker 빌드
├── tekton/                   # Tekton 리소스
│   ├── tasks/               # 재사용 가능한 작업들
│   │   ├── git-clone.yaml
│   │   ├── run-tests.yaml
│   │   ├── build-push-image.yaml
│   │   └── update-manifest.yaml
│   ├── pipelines/           # CI/CD 파이프라인 정의
│   │   └── ci-cd-pipeline.yaml
│   └── triggers/            # Git 이벤트 트리거
│       └── github-trigger.yaml
├── kubernetes/              # Kubernetes 매니페스트
│   ├── base/               # 기본 리소스
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   └── overlays/           # 환경별 오버레이
│       ├── dev/
│       ├── staging/
│       └── prod/
└── argocd/                 # ArgoCD 애플리케이션
    └── application.yaml
```

## 빠른 시작

### 1. 사전 요구사항
- Kubernetes 클러스터 (v1.21+)
- kubectl 설치 및 클러스터 연결 설정
- Docker Hub 또는 GitHub Container Registry 계정

### 2. 자동 설치
```bash
./scripts/setup.sh
```

### 3. 수동 설치 (선택사항)
```bash
# Tekton Pipelines 설치
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

# Tekton Triggers 설치
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml

# ArgoCD 설치
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 네임스페이스 생성
kubectl create namespace tekton-pipelines
kubectl create namespace sample-app-dev

# Tekton 리소스 적용
kubectl apply -f tekton/tasks/
kubectl apply -f tekton/pipelines/
kubectl apply -f tekton/triggers/

# ArgoCD 애플리케이션 생성
kubectl apply -f argocd/application.yaml
```

## 설정

### Container Registry 인증
```bash
# Docker Hub 예시
kubectl create secret docker-registry docker-credentials \
  --docker-server=docker.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_TOKEN \
  --docker-email=YOUR_EMAIL \
  -n tekton-pipelines

# GitHub Container Registry 예시
kubectl create secret docker-registry docker-credentials \
  --docker-server=ghcr.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_TOKEN \
  --docker-email=YOUR_EMAIL \
  -n tekton-pipelines
```

### Git 인증 (Private Repository)
```bash
kubectl create secret generic git-credentials \
  --from-literal=username=YOUR_USERNAME \
  --from-literal=password=YOUR_TOKEN \
  -n tekton-pipelines
```

### GitHub Webhook 설정
1. GitHub Repository → Settings → Webhooks
2. Payload URL: `http://YOUR_CLUSTER_IP:PORT` (EventListener 서비스 URL)
3. Content type: `application/json`
4. Events: `Push events`, `Pull requests`

## 🎯 사용 방법

### 개발자 워크플로우
1. **코드 수정**: 애플리케이션 코드 변경
2. **Git Push**: `main` 브랜치에 푸시
3. **자동 트리거**: Tekton이 자동으로 파이프라인 실행
4. **결과 확인**: 
   - 빌드 상태: Tekton Dashboard
   - 배포 상태: ArgoCD Dashboard

### 파이프라인 단계
1. **소스 코드 클론**: Git 저장소에서 코드 가져오기
2. **테스트 실행**: Jest를 통한 단위 테스트
3. **이미지 빌드**: Kaniko로 컨테이너 이미지 생성
4. **이미지 푸시**: Container Registry에 업로드
5. **매니페스트 업데이트**: GitOps 저장소의 이미지 태그 자동 업데이트
6. **ArgoCD 동기화**: 클러스터에 새 버전 자동 배포

## 📊 모니터링 및 관리

### Tekton Dashboard 접근
```bash
kubectl port-forward -n tekton-pipelines service/tekton-dashboard 9097:9097
# 브라우저에서 http://localhost:9097 접속
```

### ArgoCD Dashboard 접근
```bash
# 포트 포워딩
kubectl port-forward -n argocd service/argocd-server 8080:443

# 초기 관리자 비밀번호 확인
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# 브라우저에서 https://localhost:8080 접속 (username: admin)
```

### 파이프라인 실행 모니터링
```bash
# 현재 실행 중인 파이프라인 확인
kubectl get pipelineruns -n tekton-pipelines

# 파이프라인 로그 확인
kubectl logs -f -l tekton.dev/pipelineRun=PIPELINE_RUN_NAME -n tekton-pipelines

# 작업 상태 확인
kubectl get taskruns -n tekton-pipelines
```

## 🔄 환경별 배포

### Development 환경
- **네임스페이스**: `sample-app-dev`
- **리플리카**: 1개
- **리소스**: 최소 사양
- **자동 배포**: Git push 시 즉시

### Staging 환경
- **네임스페이스**: `sample-app-staging`
- **리플리카**: 2개
- **리소스**: 중간 사양
- **배포**: 수동 승인 후

### Production 환경
- **네임스페이스**: `sample-app-prod`
- **리플리카**: 3개
- **리소스**: 높은 사양
- **배포**: 다단계 승인 프로세스

## 🛠️ 커스터마이징

### 다른 언어 지원
`tekton/tasks/run-tests.yaml`에서 테스트 단계를 수정:
```yaml
# Python 예시
- name: test
  image: python:3.9
  script: |
    pip install -r requirements.txt
    pytest

# Go 예시  
- name: test
  image: golang:1.19
  script: |
    go test ./...
```

### 보안 스캔 추가
```yaml
- name: security-scan
  taskRef:
    name: trivy-scanner
  runAfter:
    - build-push-image
```

### Slack 알림 통합
```yaml
- name: notify-slack
  taskRef:
    name: send-to-webhook-slack
  params:
    - name: webhook-secret
      value: slack-webhook
    - name: message
      value: "Pipeline $(context.pipelineRun.name) completed"
```

## 🚨 트러블슈팅

### 일반적인 문제들

**1. 파이프라인이 트리거되지 않음**
- GitHub Webhook URL 확인
- EventListener 서비스 상태 점검
- 네트워크 연결성 확인

**2. 이미지 푸시 실패**
- Container Registry 인증 정보 확인
- 네트워크 정책 점검

**3. ArgoCD 동기화 실패**
- GitOps 저장소 접근 권한 확인
- 매니페스트 문법 오류 점검

### 로그 확인 명령어
```bash
# Tekton 트리거 로그
kubectl logs -l app.kubernetes.io/name=eventlistener -n tekton-pipelines

# ArgoCD 애플리케이션 상태
kubectl get applications -n argocd

# Pod 상태 확인
kubectl get pods -n sample-app-dev
kubectl describe pod POD_NAME -n sample-app-dev
```

## 📈 확장 계획

### 고급 기능
- [ ] 멀티 클러스터 배포
- [ ] Canary 배포 전략
- [ ] 자동 롤백 메커니즘
- [ ] 성능 테스트 통합
- [ ] 보안 스캔 자동화

### 통합 가능한 도구들
- **Monitoring**: Prometheus + Grafana
- **Logging**: ELK Stack
- **Security**: Falco, OPA Gatekeeper
- **Testing**: Selenium Grid
- **Notification**: Slack, Microsoft Teams

## 🤝 기여 방법

1. 이슈 생성 또는 기존 이슈 확인
2. 브랜치 생성: `git checkout -b feature/amazing-feature`
3. 변경사항 커밋: `git commit -m 'Add amazing feature'`
4. 브랜치 푸시: `git push origin feature/amazing-feature`
5. Pull Request 생성

## 📄 라이센스

이 프로젝트는 MIT 라이센스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 🙋‍♂️ 지원

질문이나 도움이 필요하시면:
- GitHub Issues 생성
- 문서 검토 및 업데이트 제안
- 커뮤니티 포럼 참여

---

**🎉 이제 완전한 CI/CD 파이프라인이 준비되었습니다!**

코드를 푸시하고 자동으로 배포되는 과정을 경험해보세요. 현대적인 DevOps 방식으로 더 빠르고 안정적인 소프트웨어 배포를 실현할 수 있습니다.

---

# Pipeline Test

### 2025-08-13 10:00
- TEST
  - tekton_demo-run-이라는 이름에 언더스코어(_)가 포함되어 있어서 Kubernetes 명명 규칙 위반
### 2025-08-13 10:35
- TEST
  - Image 업로드까지 확인, tekton pipelines Dashboard 확인까지 가능한!
  - `kubectl apply -f https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml`
### 2025-08-13 15:11
  - ArgoCD 업데이트 기능을 보류, 일단 Tasks 하나씩 추가해나가기
  - 작동하는 Task 및 Pipeline 검증
