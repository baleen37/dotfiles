# iTerm2 to WezTerm Migration TODO

## 📋 현재 진행 상황

### ✅ 완료된 작업
- [x] 현재 dotfiles 구조 분석
- [x] iTerm2 설정 파일 위치 확인 (`modules/darwin/config/iterm2/DynamicProfiles.json`)  
- [x] WezTerm 설정 구조 연구 (Lua 기반, ~/.config/wezterm/wezterm.lua)
- [x] 마이그레이션 계획 수립 및 plan.md 작성

### 🔄 진행 중인 작업
#### Phase 2: WezTerm Setup and Configuration
- [ ] **Task 2.1**: Create WezTerm configuration directory and base files
- [ ] **Task 2.2**: Convert iTerm2 color scheme to WezTerm format
- [ ] **Task 2.3**: Configure fonts to match iTerm2 settings  
- [ ] **Task 2.4**: Convert iTerm2 key mappings to WezTerm format
- [ ] **Task 2.5**: Migrate terminal behavior settings

### ⏳ 대기 중인 작업
#### Phase 3: Nix Integration  
- [ ] **Task 3.1**: Update package installations (casks.nix)
- [ ] **Task 3.2**: Update Nix file deployment (files.nix)
- [ ] **Task 3.3**: Test and validate build process

#### Phase 4: Testing and Validation
- [ ] **Task 4.1**: Verify core WezTerm functionality
- [ ] **Task 4.2**: Test all keyboard shortcuts
- [ ] **Task 4.3**: Test with existing workflow

#### Phase 5: Documentation and Cleanup
- [ ] **Task 5.1**: Update project documentation
- [ ] **Task 5.2**: Clean up old references

## 📊 세부 Task 진행률

### Phase 2 진행률: 0% (0/5)
- **Task 2.1**: WezTerm 설정 디렉토리 생성 및 기본 파일 작성
  - modules/darwin/config/wezterm/ 디렉토리 생성
  - wezterm.lua 기본 설정 파일 생성
  - wezterm.config_builder() 구조 설정

- **Task 2.2**: iTerm2 색상 스키마를 WezTerm 형식으로 변환
  - ANSI 색상을 iTerm2 JSON에서 WezTerm Lua 색상 스키마로 매핑
  - 배경 (#000000), 전경 (#ffffff), 커서 색상 변환
  - 선택 색상 및 투명도 설정 보존
  - 'iTerm2-Dark'라는 사용자 정의 색상 스키마 생성

- **Task 2.3**: iTerm2 설정과 일치하도록 폰트 구성
  - 기본 폰트 설정: MesloLGS-NF-Regular
  - 볼드 폰트 설정: MesloLGS-NF-Bold  
  - 폰트 크기: 14pt
  - 폰트 렌더링 옵션 구성 (안티앨리어싱 등)

- **Task 2.4**: iTerm2 키 매핑을 WezTerm 형식으로 변환
  - Ctrl+Shift+Arrow 키 매핑 (0xf700-0x260000 → [1;6A 형식)
  - Home/End 키 매핑 변환 (0xf729-0x40000, 0xf72b-0x40000)
  - 적절한 터미널 시퀀스 출력 보장

- **Task 2.5**: 터미널 동작 설정 마이그레이션
  - scrollback_lines = 10000 설정
  - 창 투명도 구성 (0.1 알파)
  - 터미널 타입을 xterm-256color로 설정
  - 초기 창 크기 구성 (80x25)
  - 마우스 보고 기능 활성화

### Phase 3 진행률: 0% (0/3)
### Phase 4 진행률: 0% (0/3)  
### Phase 5 진행률: 0% (0/2)

## 🎯 현재 다음 액션
**다음에 수행할 작업**: Task 2.1 - WezTerm 설정 디렉토리 및 기본 파일 생성

## 📝 주요 메모

### 기술적 세부사항
- **iTerm2 현재 설정**:
  - 폰트: MesloLGS-NF-Regular/Bold 14pt
  - 색상: 어두운 테마, 사용자 정의 ANSI 색상
  - 키바인딩: Ctrl+Shift+Arrow 키 네비게이션
  - 터미널: 10000줄 스크롤백, 투명도 0.1

- **WezTerm 목표 설정**:
  - 위치: ~/.config/wezterm/wezterm.lua
  - 언어: Lua 기반 설정
  - 색상 스키마: 'iTerm2-Dark' 사용자 정의 스키마
  - 동일한 키바인딩 및 터미널 동작 유지

### 위험 요소
1. 폰트 렌더링 차이점
2. 키바인딩 동작 차이
3. 성능 특성 변화
4. 기존 워크플로우와의 통합 문제

### 완료 기준
- [ ] WezTerm이 올바르게 시작하고 표시됨
- [ ] 모든 색상이 iTerm2 모양과 일치하거나 개선됨
- [ ] 키바인딩이 iTerm2와 동일하게 작동
- [ ] 폰트 렌더링이 허용 가능함
- [ ] 성능이 동등하거나 더 좋음
- [ ] 기존 도구와의 통합이 유지됨
- [ ] 빌드/배포 프로세스가 올바르게 작동함

## 🕒 예상 소요 시간
- **Phase 2**: 60분 (설정 생성 및 테스트)
- **Phase 3**: 30분 (Nix 통합)
- **Phase 4**: 45분 (종합 테스트)
- **Phase 5**: 15분 (정리 및 문서화)
- **총계**: ~2.5시간 (예상치 못한 문제에 대한 버퍼 포함)

## 🔄 업데이트 로그
- **2025-07-23**: 초기 계획 수립 및 TODO 생성
- **Phase 1 완료**: 분석 및 기초 작업 완료 (30분)
