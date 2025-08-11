# TEKTON CI/CD 프로젝트 진행 상황

## 📋 프로젝트 개요
TEKTON을 사용한 애플리케이션 CI/CD를 구성하기 위한 첫 단계인 Github Repository 입니다.

### 원래 요구사항

**사용자 관점**
1. Code 수정
2. Code 수정 후 Stage, Commit, Push
3. Test 결과 수신
4. Test 배포 또는 Production 배포의 자동화
5. 적용 시간은 짧을수록 좋습니다.

**OPS 구축자**
1. Git이 WebHook 이건 어떤 요청이건 통해 State가 갱신됨을 알림
2. Git Code를 clone하여 Container 내에서 Build
3. Build 후 Test를 수행
4. Test 통과 시 Container Image를 지정된 Registry에 업데이트 (Image tag 새롭게 수정)
5. Registry에 Image가 업로드 된 경우 Kubernetes Cluster가 감지하여 새롭게 배포

---

## 🎯 구축 완료된 CI/CD 아키텍처

### 현재 완성된 구조
```
Git Push → Tekton Trigger → Build & Test → Image Push → Manifest Update → ArgoCD Deploy
```

### 주요 구성 요소
- **Tekton Pipelines**: CI/CD 파이프라인 실행 엔진
- **Tekton Triggers**: Git 이벤트 기반 자동 트리거
- **ArgoCD**: GitOps 기반 지속적 배포
- **Kaniko**: 컨테이너 이미지 빌드 (Docker-in-Docker 불필요)
- **Kustomize**: 환경별 매니페스트 관리

---

## 📁 완성된 프로젝트 구조

```
.
├── README.md                 # 상세 문서
├── scripts/setup.sh          # 자동 설치 스크립트 (일부 수정됨)
├── app/                      # 샘플 Node.js 애플리케이션
│   ├── src/index.js         # Express 서버
│   ├── tests/app.test.js    # Jest 테스트
│   └── package.json         # 의존성 관리
├── Dockerfile               # 멀티스테이지 빌드
├── tekton/                  # Tekton 리소스
│   ├── tasks/              # 재사용 가능한 작업들
│   │   ├── git-clone.yaml
│   │   ├── run-tests.yaml
│   │   ├── build-push-image.yaml
│   │   └── update-manifest.yaml
│   ├── pipelines/          # CI/CD 파이프라인
│   │   └── ci-cd-pipeline.yaml
│   └── triggers/           # Git 이벤트 트리거
│       └── github-trigger.yaml
├── kubernetes/             # K8s 매니페스트
│   ├── base/              # 기본 리소스
│   └── overlays/          # 환경별 오버레이 (dev/staging/prod)
└── argocd/                # ArgoCD 설정
    └── application.yaml
```

---

## 🚀 다음 실행 계획 (30분 Quick Start)

### 현재 클러스터 상태 (확인됨)
- ✅ Kubernetes 클러스터 정상 작동 (K3s v1.31.4)
- ✅ Tekton Pipelines 설치됨 
- ✅ ArgoCD 설치됨 (모든 Pod 정상)
- ✅ 필요한 네임스페이스 존재

### 필요한 작업들
1. ❌ Docker/Git 인증 정보 설정
2. ❌ Tekton 리소스 배포 (Tasks, Pipelines)
3. ❌ 매니페스트 수정 (이미지 URL, 저장소 URL)
4. ❌ 수동 파이프라인 테스트

### Step-by-Step 실행 계획

#### **Step 1: 필수 설정 (5분)**
```bash
# Container Registry 인증 (GitHub Container Registry)
kubectl create secret docker-registry docker-credentials \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_TOKEN \
  --docker-email=YOUR_EMAIL \
  -n tekton-pipelines

# Git 인증
kubectl create secret generic git-credentials \
  --from-literal=username=YOUR_GITHUB_USERNAME \
  --from-literal=password=YOUR_GITHUB_TOKEN \
  -n tekton-pipelines
```

#### **Step 2: Tekton 리소스 배포 (5분)**
```bash
cd /home/shogle/workspace/practice/tekton_build_test
kubectl apply -f tekton/tasks/
kubectl apply -f tekton/pipelines/
kubectl get tasks,pipelines -n tekton-pipelines  # 확인
```

#### **Step 3: 매니페스트 수정 (5분)**
파일 수정 필요:
- `kubernetes/base/deployment.yaml`: 이미지 URL 수정
- `argocd/application.yaml`: 저장소 URL 수정

#### **Step 4: 대시보드 실행 및 테스트 (15분)**
```bash
# 네임스페이스 생성
kubectl create namespace sample-app-dev

# 대시보드 실행 (백그라운드)
kubectl port-forward -n tekton-pipelines service/tekton-dashboard 9097:9097 &
kubectl port-forward -n argocd service/argocd-server 8080:443 &

# 접속 정보
# Tekton: http://localhost:9097
# ArgoCD: https://localhost:8080 (admin/비밀번호확인필요)
```

---

## 💡 학습 포인트

### CI/CD 개념 이해
- [x] GitOps 패턴 설계 완료
- [x] 컨테이너 기반 빌드 이해
- [x] 환경별 배포 전략 이해
- [ ] 실제 실행을 통한 전체 플로우 체험 (다음 단계)

### 개선사항 (향후 적용)
- 보안 강화 (Webhook 서명 검증, RBAC)
- 고급 배포 전략 (Blue-Green, Canary)
- 모니터링 연동 (Prometheus, Grafana)
- 품질 게이트 강화 (SonarQube, 보안 스캔)

---

## 📝 다음 세션 진행 사항

**우선순위 1: 기본 데모 완성**
1. GitHub 저장소 설정 및 토큰 생성
2. 위의 4단계 실행 계획 순서대로 진행
3. 수동 파이프라인 실행으로 전체 플로우 검증

**우선순위 2: 자동 트리거 설정**
1. GitHub Webhook 연동
2. 실제 Git push로 자동 파이프라인 실행
3. ArgoCD를 통한 자동 배포 확인

**우선순위 3: 모니터링 및 최적화**
1. 각 단계별 로그 및 메트릭 확인
2. 실패 케이스 처리 방법 학습
3. 성능 튜닝 및 리소스 최적화

---

## 🔗 유용한 명령어 모음

### 상태 확인
```bash
# 클러스터 전체 상태
kubectl get all --all-namespaces

# Tekton 리소스 확인
kubectl get tasks,pipelines,pipelineruns -n tekton-pipelines

# ArgoCD 상태 확인
kubectl get applications -n argocd
```

### 디버깅
```bash
# 파이프라인 로그 확인
kubectl logs -f -l tekton.dev/pipelineRun=PIPELINE_RUN_NAME -n tekton-pipelines

# ArgoCD 비밀번호 확인
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 정리
```bash
# 리소스 정리 (필요시)
kubectl delete pipelineruns --all -n tekton-pipelines
kubectl delete applications --all -n argocd
```

---

## 📚 참고 자료

- [Tekton 공식 문서](https://tekton.dev/)
- [ArgoCD 공식 문서](https://argo-cd.readthedocs.io/)
- [Kustomize 가이드](https://kustomize.io/)
- [Kaniko 사용법](https://github.com/GoogleContainerTools/kaniko)

**다음 세션에서 이 계획대로 진행하여 완전한 CI/CD 파이프라인을 실제 동작시켜보겠습니다!** 🚀