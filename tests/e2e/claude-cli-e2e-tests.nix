# Claude CLI End-to-End Tests - Improved Version
# 실제 사용자 시나리오를 완전히 시뮬레이션하는 종합 테스트

{ pkgs }:

let
  testLib = import ../lib/claude-cli-test-lib.nix { inherit pkgs; };
in

{
  # E2E Test 1: 신규 개발자 온보딩 시나리오
  newDeveloperOnboardingTest = testLib.isolatedTest "new-developer-onboarding" ''
    echo "Testing new developer onboarding scenario..."

    # 시나리오: 새로운 개발자가 프로젝트에 참여하여 첫 기능을 개발
    ${testLib.createTestRepo "onboarding-project"}

    # 프로젝트 초기 구조 생성
    mkdir -p src/{components,utils,styles}
    echo "# Awesome Project" > README.md
    echo "export const version = '1.0.0';" > src/version.js
    git add .
    git commit -m "Initial project structure"

    # Step 1: 개발자가 첫 번째 기능 작업 시작
    feature1="feature/add-login-page"
    echo "Developer starts working on login page..."

    ccw_feature1=$(ccw "$feature1" 2>&1)
    assert_contains "$ccw_feature1" "Creating new git worktree" "Login feature worktree created"
    assert_git_branch "$feature1" "Working on login feature branch"

    # 로그인 페이지 개발
    mkdir -p src/pages
    cat > src/pages/Login.js << 'EOF'
import React from 'react';
export const Login = () => {
  return <div>Login Page</div>;
};
EOF

    cat > src/styles/login.css << 'EOF'
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
}
EOF

    git add .
    git commit -m "Add login page component and styles"

    # Step 2: 메인 브랜치에서 핫픽스 작업 필요
    echo "Urgent hotfix needed on main branch..."
    cd "$test_repo"

    hotfix_branch="hotfix/critical-security-fix"
    ccw_hotfix=$(ccw "$hotfix_branch" 2>&1)
    assert_contains "$ccw_hotfix" "Creating new git worktree" "Hotfix worktree created"
    assert_git_branch "$hotfix_branch" "Working on hotfix branch"

    # 보안 수정
    echo "// Security fix applied" >> src/version.js
    git add .
    git commit -m "Apply critical security fix"

    # Step 3: 다시 기능 개발로 돌아가기
    echo "Returning to feature development..."
    ccw_return=$(ccw "$feature1" 2>&1)
    assert_contains "$ccw_return" "Switching to existing worktree" "Returned to login feature"
    assert_git_branch "$feature1" "Back on login feature branch"

    # 이전 작업이 보존되었는지 확인
    assert_success "test -f src/pages/Login.js" "Login component preserved"
    assert_success "test -f src/styles/login.css" "Login styles preserved"

    # 추가 기능 개발
    cat >> src/pages/Login.js << 'EOF'

export const LoginForm = () => {
  return <form>Login Form</form>;
};
EOF

    git add .
    git commit -m "Add login form component"

    # Step 4: 또 다른 기능 병렬 개발
    cd "$test_repo"
    feature2="feature/user-profile"
    ccw_feature2=$(ccw "$feature2" 2>&1)
    assert_contains "$ccw_feature2" "Creating new git worktree" "Profile feature worktree created"

    # 프로필 페이지 개발
    mkdir -p src/pages
    echo "export const Profile = () => <div>Profile Page</div>;" > src/pages/Profile.js
    git add .
    git commit -m "Add user profile page"

    # Step 5: 모든 워크트리가 독립적으로 작동하는지 확인
    echo "Verifying independent development in multiple worktrees..."

    # 로그인 기능 확인
    cd "../$feature1"
    assert_git_branch "$feature1" "Login feature branch active"
    assert_success "test -f src/pages/Login.js" "Login files in login worktree"
    assert_failure "test -f src/pages/Profile.js" "Profile files not in login worktree"

    # 프로필 기능 확인
    cd "../$feature2"
    assert_git_branch "$feature2" "Profile feature branch active"
    assert_success "test -f src/pages/Profile.js" "Profile files in profile worktree"
    assert_failure "grep -q 'LoginForm' src/pages/Login.js" "Login updates not in profile worktree"

    # 핫픽스 확인
    cd "../$hotfix_branch"
    assert_git_branch "$hotfix_branch" "Hotfix branch active"
    assert_contains "$(cat src/version.js)" "Security fix applied" "Security fix in hotfix worktree"

    # 정리
    cd "$test_repo"
    for branch in "$feature1" "$feature2" "$hotfix_branch"; do
      git worktree remove "../$branch" 2>/dev/null || true
      rm -rf "../$branch" 2>/dev/null || true
      git branch -D "$branch" 2>/dev/null || true
    done
  '';

  # E2E Test 2: 팀 협업 시나리오
  teamCollaborationTest = testLib.isolatedTest "team-collaboration" ''
    echo "Testing team collaboration scenario..."

    # 시나리오: 여러 개발자가 동시에 다른 기능을 개발하는 상황
    ${testLib.createTestRepo "team-project"}

    # 프로젝트 베이스 구성
    mkdir -p {frontend,backend,docs,tests}
    echo "# Team Project" > README.md
    echo "package.json content" > package.json
    git add .
    git commit -m "Project initialization"

    # 팀원 1: 프론트엔드 개발
    frontend_branch="feature/frontend-redesign"
    echo "Team member 1 working on frontend..."

    ccw_frontend=$(ccw "$frontend_branch" 2>&1)
    assert_contains "$ccw_frontend" "Creating new git worktree" "Frontend worktree created"

    # 프론트엔드 작업
    mkdir -p frontend/{components,pages,styles}
    echo "React App" > frontend/App.js
    echo "Main styles" > frontend/styles/main.css
    git add .
    git commit -m "Frontend: Add main app structure"

    # 팀원 2: 백엔드 개발 (동시 작업)
    cd "$test_repo"
    backend_branch="feature/api-endpoints"
    echo "Team member 2 working on backend..."

    ccw_backend=$(ccw "$backend_branch" 2>&1)
    assert_contains "$ccw_backend" "Creating new git worktree" "Backend worktree created"

    # 백엔드 작업
    mkdir -p backend/{routes,models,middleware}
    echo "Express server" > backend/server.js
    echo "User model" > backend/models/User.js
    git add .
    git commit -m "Backend: Add server and user model"

    # 팀원 3: 문서화 작업
    cd "$test_repo"
    docs_branch="docs/api-documentation"
    echo "Team member 3 working on documentation..."

    ccw_docs=$(ccw "$docs_branch" 2>&1)
    assert_contains "$ccw_docs" "Creating new git worktree" "Documentation worktree created"

    # 문서 작업
    mkdir -p docs/{api,guides,examples}
    echo "# API Documentation" > docs/api/README.md
    echo "# User Guide" > docs/guides/getting-started.md
    git add .
    git commit -m "Docs: Add API documentation and user guide"

    # 팀원 4: 테스트 작성
    cd "$test_repo"
    test_branch="feature/test-suite"
    echo "Team member 4 working on tests..."

    ccw_test=$(ccw "$test_branch" 2>&1)
    assert_contains "$ccw_test" "Creating new git worktree" "Test worktree created"

    # 테스트 작업
    mkdir -p tests/{unit,integration,e2e}
    echo "describe('App', () => {})" > tests/unit/app.test.js
    echo "Integration tests" > tests/integration/api.test.js
    git add .
    git commit -m "Tests: Add unit and integration test structure"

    # 각 팀원의 작업 공간이 독립적인지 확인
    echo "Verifying independent team workspaces..."

    # 프론트엔드 워크스페이스 확인
    cd "../$frontend_branch"
    assert_git_branch "$frontend_branch" "Frontend team on correct branch"
    assert_success "test -f frontend/App.js" "Frontend files exist"
    assert_failure "test -f backend/server.js" "Backend files not in frontend workspace"
    assert_failure "test -f docs/api/README.md" "Doc files not in frontend workspace"

    # 백엔드 워크스페이스 확인
    cd "../$backend_branch"
    assert_git_branch "$backend_branch" "Backend team on correct branch"
    assert_success "test -f backend/server.js" "Backend files exist"
    assert_failure "test -f frontend/App.js" "Frontend files not in backend workspace"

    # 문서 워크스페이스 확인
    cd "../$docs_branch"
    assert_git_branch "$docs_branch" "Docs team on correct branch"
    assert_success "test -f docs/api/README.md" "Documentation files exist"
    assert_failure "test -f backend/server.js" "Backend files not in docs workspace"

    # 테스트 워크스페이스 확인
    cd "../$test_branch"
    assert_git_branch "$test_branch" "Test team on correct branch"
    assert_success "test -f tests/unit/app.test.js" "Test files exist"
    assert_failure "test -f frontend/App.js" "Frontend files not in test workspace"

    # 팀 워크플로우 시뮬레이션: 크로스 팀 협업
    echo "Simulating cross-team collaboration..."

    # 프론트엔드 팀이 백엔드 API 확인 필요
    cd "../$frontend_branch"
    git fetch origin 2>/dev/null || true  # 실제로는 원격에서 가져옴

    # 백엔드 팀이 문서 업데이트
    cd "../$backend_branch"
    echo "# Backend API Endpoints" > API_ENDPOINTS.md
    git add .
    git commit -m "Backend: Document API endpoints"

    # 정리
    cd "$test_repo"
    branches=("$frontend_branch" "$backend_branch" "$docs_branch" "$test_branch")
    for branch in "''${branches[@]}"; do
      git worktree remove "../$branch" 2>/dev/null || true
      rm -rf "../$branch" 2>/dev/null || true
      git branch -D "$branch" 2>/dev/null || true
    done
  '';

  # E2E Test 3: 릴리스 관리 시나리오
  releaseManagementTest = testLib.isolatedTest "release-management" ''
    echo "Testing release management scenario..."

    # 시나리오: 제품 릴리스 준비 및 관리
    ${testLib.createTestRepo "product-release"}

    # 초기 제품 버전
    echo "v0.9.0" > VERSION
    mkdir -p src/{core,features,utils}
    echo "Core functionality" > src/core/main.js
    git add .
    git commit -m "Initial v0.9.0 release"

    # 개발 브랜치에서 새 기능들 개발
    dev_branch="develop"
    git checkout -b "$dev_branch"

    # 여러 기능 추가
    echo "New feature 1" > src/features/feature1.js
    git add .
    git commit -m "Add feature 1"

    echo "New feature 2" > src/features/feature2.js
    git add .
    git commit -m "Add feature 2"

    git checkout main

    # 릴리스 준비 시작
    release_branch="release/v1.0.0"
    echo "Starting v1.0.0 release preparation..."

    ccw_release=$(ccw "$release_branch" 2>&1)
    assert_contains "$ccw_release" "Creating new git worktree" "Release branch worktree created"
    assert_git_branch "$release_branch" "Working on release branch"

    # 릴리스 준비 작업
    echo "v1.0.0" > VERSION
    echo "# Release Notes v1.0.0" > RELEASE_NOTES.md
    echo "- Added feature 1" >> RELEASE_NOTES.md
    echo "- Added feature 2" >> RELEASE_NOTES.md
    echo "- Bug fixes and improvements" >> RELEASE_NOTES.md

    # 개발 브랜치의 기능들 수동 병합 시뮬레이션
    mkdir -p src/features
    echo "New feature 1" > src/features/feature1.js
    echo "New feature 2" > src/features/feature2.js

    git add .
    git commit -m "Prepare v1.0.0 release"

    # 릴리스 도중 핫픽스 필요 상황
    cd "$test_repo"
    hotfix_branch="hotfix/v0.9.1"
    echo "Critical bug found in production, need hotfix..."

    ccw_hotfix=$(ccw "$hotfix_branch" 2>&1)
    assert_contains "$ccw_hotfix" "Creating new git worktree" "Hotfix worktree created"

    # 핫픽스 적용
    echo "v0.9.1" > VERSION
    echo "// Critical bug fix" >> src/core/main.js
    git add .
    git commit -m "Fix critical bug in v0.9.1"

    # 다시 릴리스 준비로 돌아가기
    cd "../$release_branch"
    assert_git_branch "$release_branch" "Back on release branch"

    # 릴리스 최종 점검
    assert_success "test -f RELEASE_NOTES.md" "Release notes prepared"
    assert_success "test -f src/features/feature1.js" "Feature 1 included in release"
    assert_success "test -f src/features/feature2.js" "Feature 2 included in release"
    assert_contains "$(cat VERSION)" "v1.0.0" "Version updated to 1.0.0"

    # 다음 개발 사이클 시작
    cd "$test_repo"
    next_feature="feature/post-release-feature"
    ccw_next=$(ccw "$next_feature" 2>&1)
    assert_contains "$ccw_next" "Creating new git worktree" "Post-release feature worktree created"

    # 다음 버전을 위한 기능 개발 시작
    echo "Post-release feature" > src/features/next-feature.js
    git add .
    git commit -m "Start development for next version"

    # 모든 브랜치가 독립적으로 관리되는지 확인
    echo "Verifying independent release management..."

    # 릴리스 브랜치 확인
    cd "../$release_branch"
    assert_contains "$(cat VERSION)" "v1.0.0" "Release branch has v1.0.0"
    assert_failure "test -f src/features/next-feature.js" "Next features not in release"

    # 핫픽스 브랜치 확인
    cd "../$hotfix_branch"
    assert_contains "$(cat VERSION)" "v0.9.1" "Hotfix branch has v0.9.1"
    assert_contains "$(cat src/core/main.js)" "Critical bug fix" "Bug fix in hotfix"

    # 다음 기능 브랜치 확인
    cd "../$next_feature"
    assert_success "test -f src/features/next-feature.js" "Next feature exists"
    assert_failure "test -f RELEASE_NOTES.md" "Release notes not in feature branch"

    # 정리
    cd "$test_repo"
    branches=("$release_branch" "$hotfix_branch" "$next_feature")
    for branch in "''${branches[@]}"; do
      git worktree remove "../$branch" 2>/dev/null || true
      rm -rf "../$branch" 2>/dev/null || true
      git branch -D "$branch" 2>/dev/null || true
    done
    git branch -D "$dev_branch" 2>/dev/null || true
  '';

  # E2E Test 4: 대규모 프로젝트 워크플로우
  largescaleProjectTest = testLib.isolatedTest "largescale-project" ''
    echo "Testing large-scale project workflow..."

    # 시나리오: 마이크로서비스 아키텍처 프로젝트
    ${testLib.createTestRepo "microservices-project"}

    # 프로젝트 구조 생성
    mkdir -p {services/{auth,user,order,payment},infrastructure,docs,tests}
    echo "# Microservices Platform" > README.md
    echo "monorepo structure" > .gitignore
    git add .
    git commit -m "Initialize microservices project"

    # 각 서비스별 개발 워크스페이스 생성
    services=("auth-service" "user-service" "order-service" "payment-service")

    for service in "''${services[@]}"; do
      service_branch="feature/$service-enhancement"
      echo "Setting up $service development environment..."

      ccw_service=$(ccw "$service_branch" 2>&1)
      assert_contains "$ccw_service" "Creating new git worktree" "$service worktree created"

      # 서비스별 개발 작업 시뮬레이션
      case "$service" in
        "auth-service")
          mkdir -p services/auth/{src,tests,config}
          echo "JWT authentication" > services/auth/src/auth.js
          echo "Auth tests" > services/auth/tests/auth.test.js
          ;;
        "user-service")
          mkdir -p services/user/{src,tests,models}
          echo "User management" > services/user/src/user.js
          echo "User model" > services/user/models/User.js
          ;;
        "order-service")
          mkdir -p services/order/{src,tests,handlers}
          echo "Order processing" > services/order/src/order.js
          echo "Order handlers" > services/order/handlers/create.js
          ;;
        "payment-service")
          mkdir -p services/payment/{src,tests,gateways}
          echo "Payment processing" > services/payment/src/payment.js
          echo "Payment gateway" > services/payment/gateways/stripe.js
          ;;
      esac

      git add .
      git commit -m "Implement $service enhancements"

      # 메인 프로젝트로 돌아가기
      cd "$test_repo"
    done

    # 인프라스트럭처 팀 작업
    infra_branch="infrastructure/k8s-deployment"
    ccw_infra=$(ccw "$infra_branch" 2>&1)
    assert_contains "$ccw_infra" "Creating new git worktree" "Infrastructure worktree created"

    # 인프라 구성
    mkdir -p infrastructure/{kubernetes,docker,terraform}
    echo "Kubernetes manifests" > infrastructure/kubernetes/deployment.yaml
    echo "Docker configurations" > infrastructure/docker/Dockerfile
    echo "Terraform scripts" > infrastructure/terraform/main.tf
    git add .
    git commit -m "Add Kubernetes deployment configuration"

    # 문서팀 작업
    cd "$test_repo"
    docs_branch="docs/microservices-guide"
    ccw_docs=$(ccw "$docs_branch" 2>&1)
    assert_contains "$ccw_docs" "Creating new git worktree" "Documentation worktree created"

    # 문서 작성
    mkdir -p docs/{architecture,api,deployment}
    echo "# Microservices Architecture" > docs/architecture/overview.md
    echo "# API Documentation" > docs/api/endpoints.md
    echo "# Deployment Guide" > docs/deployment/guide.md
    git add .
    git commit -m "Add comprehensive documentation"

    # 통합 테스트 환경
    cd "$test_repo"
    integration_branch="tests/integration-suite"
    ccw_integration=$(ccw "$integration_branch" 2>&1)
    assert_contains "$ccw_integration" "Creating new git worktree" "Integration test worktree created"

    # 통합 테스트 구성
    mkdir -p tests/{integration,e2e,performance}
    echo "Integration tests for all services" > tests/integration/services.test.js
    echo "End-to-end user flows" > tests/e2e/user-journey.test.js
    echo "Performance benchmarks" > tests/performance/load.test.js
    git add .
    git commit -m "Add comprehensive test suite"

    # 대규모 프로젝트에서의 독립성 확인
    echo "Verifying large-scale project isolation..."

    # 각 서비스 워크스페이스 검증
    for service in "''${services[@]}"; do
      service_branch="feature/$service-enhancement"
      cd "../$service_branch"

      assert_git_branch "$service_branch" "$service branch is active"

      # 해당 서비스의 파일은 존재하고
      service_name=$(echo "$service" | cut -d'-' -f1)
      assert_success "test -d services/$service_name" "$service directory exists"

      # 다른 전문 분야 파일들은 없는지 확인
      if [[ "$service" != "auth-service" ]]; then
        assert_failure "test -f infrastructure/kubernetes/deployment.yaml" "Infrastructure files not in $service workspace"
      fi
    done

    # 인프라 워크스페이스 검증
    cd "../$infra_branch"
    assert_git_branch "$infra_branch" "Infrastructure branch is active"
    assert_success "test -f infrastructure/kubernetes/deployment.yaml" "Kubernetes files exist"
    assert_failure "test -f services/auth/src/auth.js" "Service files not in infrastructure workspace"

    # 대규모 워크트리 목록 확인
    cd "$test_repo"
    worktree_count=$(git worktree list | wc -l)
    expected_count=8  # main + 7 worktrees
    if [[ $worktree_count -ge $expected_count ]]; then
      echo "✅ PASS: Large-scale project has multiple worktrees ($worktree_count >= $expected_count)"
    else
      echo "❌ FAIL: Insufficient worktrees for large-scale project ($worktree_count < $expected_count)"
      return 1
    fi

    # 정리
    all_branches=()
    for service in "''${services[@]}"; do
      all_branches+=("feature/$service-enhancement")
    done
    all_branches+=("$infra_branch" "$docs_branch" "$integration_branch")

    for branch in "''${all_branches[@]}"; do
      git worktree remove "../$branch" 2>/dev/null || true
      rm -rf "../$branch" 2>/dev/null || true
      git branch -D "$branch" 2>/dev/null || true
    done
  '';
}
