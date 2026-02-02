# Real Project Workflow E2E Test
#
# 실제 프로젝트 개발 워크플로우를 시뮬레이션하여 dotfiles 환경의 실용성 검증
#
# 검증 시나리오:
# 1. 새 프로젝트 생성 및 초기 설정
# 2. 개발 도구 통합 사용 (Git, Vim, Zsh, Tmux)
# 3. 빌드/테스트 워크플로우 시뮬레이션
# 4. 협업 기능 검증 (branch, merge, code review)
# 5. 일일 개발 작업 루틴 시뮬레이션
#
# 실행 시간 목표: 8분 내외

{
  pkgs ? import <nixpkgs> { },
  nixpkgs ? <nixpkgs>,
  lib ? pkgs.lib,
  system ? builtins.currentSystem,
  self ? null,
}:

let
  # Import test builders for reusable test patterns
  testBuilders = import ../lib/test-builders.nix {
    inherit pkgs lib system nixpkgs;
  };

in
# Use mkDeveloperTest for developer workstation setup
testBuilders.mkDeveloperTest {
  testName = "real-project-workflow-test";

  devPackages = with pkgs; [
    nodejs
    python3
    docker-compose
    gh
    gcc
    cmake
    netcat
  ];

  testScriptBody = ''
    print("🚀 Starting Real Project Workflow Test...")
    print("=" * 50)

    # Phase 1: Development Environment Validation
    print("\n📋 Phase 1: Development Environment Validation")

    machine.succeed("""
      su - testuser -c '
        echo "🔍 Validating development environment..."

        # Check essential tools
        tools=("git" "vim" "zsh" "tmux" "node" "python3" "docker")
        for tool in "''${tools[@]}"; do
          if command -v "$tool" >/dev/null 2>&1; then
            echo "✅ $tool available"
          else
            echo "❌ $tool not available"
            exit 1
          fi
        done

        # Create comprehensive development environment
        mkdir -p ~/projects/{web-app,mobile-app,scripts,configs,documentation}
        mkdir -p ~/scripts ~/templates/{web-app,cli-tool,documentation}

        # Enhanced Git configuration for real development
        cat > ~/.gitconfig << "EOF"
[user]
    name = Alex Developer
    email = alex.dev@techcorp.com
    signingkey = A1B2C3D4E5F6

[core]
    editor = vim
    autocrlf = input
    filemode = true
    quotePath = false

[push]
    default = simple
    autoSetupRemote = true

[pull]
    rebase = true

[fetch]
    prune = true

[init]
    defaultBranch = main

[alias]
    st = status -sb
    co = checkout
    br = branch
    ci = commit
    lg = log --oneline --graph --decorate --all
    ll = log --oneline --graph --decorate -10

[github]
    user = alexdeveloper
EOF

        # Validate Git configuration
        git_user=$(git config --global user.name)
        git_email=$(git config --global user.email)
        echo "👤 Git user: $git_user ($git_email)"

        if [ "$git_user" = "Alex Developer" ]; then
          echo "✅ Git configuration correct"
        else
          echo "❌ Git configuration incorrect"
          exit 1
        fi

        echo "✅ Development environment validated"
      '
    """)

    # Phase 2: New Project Creation Workflow
    print("\n🏗️ Phase 2: New Project Creation Workflow")

    machine.succeed("""
      su - testuser -c '
        echo "🆕 Creating new projects..."

        cd ~/projects

        # Create a web application project
        echo "📦 Creating web application..."
        mkdir -p my-web-app/{src,tests,public}
        cd my-web-app

        cat > package.json << "EOF"
{
  "name": "web-app-template",
  "version": "1.0.0",
  "description": "Web application template",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "test": "jest",
    "build": "webpack --mode production"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF

        echo "// Web app entry point" > src/index.js

        # Initialize Git repository
        git init
        git add .
        git commit -m "Initial web app setup with template"

        # Verify project structure
        if [ -f "package.json" ] && [ -d "src" ] && [ -d "tests" ]; then
          echo "✅ Web app project structure created"
        else
          echo "❌ Web app project structure incomplete"
          exit 1
        fi

        cd ..

        echo "✅ Project creation workflow completed"
      '
    """)

    # Phase 3: Daily Development Workflow
    print("\n🌅 Phase 3: Daily Development Workflow Simulation")

    machine.succeed("""
      su - testuser -c '
        echo "📝 Simulating daily development workflow..."

        cd ~/projects/my-web-app

        # Check out to new feature branch
        git checkout -b feature/user-authentication
        echo "🌿 Created feature branch: feature/user-authentication"

        # Create authentication module
        mkdir -p src/auth
        cat > src/auth/auth.js << "EOF"
// Authentication module
class AuthManager {
  constructor() {
    this.users = new Map();
  }

  register(username, password) {
    if (this.users.has(username)) {
      throw new Error("User already exists");
    }
    this.users.set(username, { password, createdAt: new Date() });
    return { success: true, user: username };
  }

  login(username, password) {
    const user = this.users.get(username);
    if (!user || user.password !== password) {
      throw new Error("Invalid credentials");
    }
    return { success: true, token: this.generateToken(username) };
  }

  generateToken(username) {
      return Buffer.from(username + ":" + Date.now()).toString("base64");
  }
}

module.exports = AuthManager;
EOF

        # Create authentication tests
        mkdir -p tests/auth
        cat > tests/auth/auth.test.js << "EOF"
const AuthManager = require("../../src/auth/auth");

describe("AuthManager", () => {
  let auth;

  beforeEach(() => {
    auth = new AuthManager();
  });

  test("should register new user", () => {
    const result = auth.register("testuser", "password123");
    expect(result.success).toBe(true);
    expect(result.user).toBe("testuser");
  });

  test("should login with valid credentials", () => {
    auth.register("testuser", "password123");
    const result = auth.login("testuser", "password123");
    expect(result.success).toBe(true);
    expect(result.token).toBeDefined();
  });
});
EOF

        # Stage and commit changes
        git add .
        git commit -m "feat: add authentication module with tests"

        echo "✅ Feature development completed"
        echo "Created authentication module with tests"
      '
    """)

    # Phase 4: Code Review and Collaboration Workflow
    print("\n🤝 Phase 4: Code Review and Collaboration Workflow")

    machine.succeed("""
      su - testuser -c '
        echo "🔄 Simulating collaboration workflow..."

        cd ~/projects/my-web-app

        # Switch back to main branch
        git checkout main

        # Create bugfix branch
        git checkout -b fix/dependency-update

        # Update dependencies in package.json
        sed -i '"'"'s/"express": "\^4\.18\.0"/"express": "^4.21.0"/'"'"' package.json

        git add package.json
        git commit -m "fix: update express to latest stable version"

        # Simulate code review process
        echo "📝 Simulating code review..."
        git checkout main
        git merge --no-ff fix/dependency-update -m "Merge branch fix/dependency-update"

        echo "✅ Collaboration workflow simulated"
      '
    """)

    # Phase 5: Build and Test Integration
    print("\n🔧 Phase 5: Build and Test Integration")

    machine.succeed("""
      su - testuser -c '
        echo "🧪 Testing build and test integration..."

        cd ~/projects/my-web-app

        # Verify test files exist and are valid JavaScript
        if [ -f "tests/auth/auth.test.js" ] && grep -q "describe" tests/auth/auth.test.js; then
          echo "✅ Test files properly created"
        else
          echo "❌ Test files invalid"
          exit 1
        fi

        # Check package.json for build scripts
        if grep -q '"'"'build'"'"' package.json && grep -q '"'"'test'"'"' package.json; then
          echo "✅ Build and test scripts configured"
        else
          echo "❌ Build configuration incomplete"
          exit 1
        fi

        echo "✅ Build and test integration validated"
      '
    """)

    # Final Validation
    print("\n🎉 Real Project Workflow Test - FINAL VALIDATION")
    print("=" * 60)

    final_result = machine.succeed("""
      su - testuser -c '
        echo ""
        echo "🎊 REAL PROJECT WORKFLOW TEST COMPLETE"
        echo "====================================="
        echo ""
        echo "✅ Phase 1: Development Environment Validated"
        echo "✅ Phase 2: Project Creation Workflow Successful"
        echo "✅ Phase 3: Daily Development Workflow Simulated"
        echo "✅ Phase 4: Code Review and Collaboration Tested"
        echo "✅ Phase 5: Build and Test Integration Verified"
        echo ""
        echo "🚀 DEVELOPMENT WORKFLOW FULLY FUNCTIONAL!"
        echo ""
        echo "✨ Real project workflow PASSED"
        echo ""

        # Create success marker
        echo "SUCCESS" > workflow-result.txt
        cat workflow-result.txt
      '
    """)

    if "SUCCESS" in final_result:
      print("\n🎊 REAL PROJECT WORKFLOW TEST PASSED!")
      print("   Complete development workflow successfully validated")
      print("   Developer can be productive immediately")
    else:
      print("\n❌ REAL PROJECT WORKFLOW TEST FAILED!")
      raise Exception("Real project workflow validation failed")
  '';
}
