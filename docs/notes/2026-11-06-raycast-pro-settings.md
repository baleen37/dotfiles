# Raycast v2 Pro 기능의 Nix 관리 조사

조사일: 2026-11-06. 로컬 설치 버전: 2.11.1.0.

## 결론

“공식 Nix 옵션이 없다”는 사실은 “자동화가 불가능하다”는 뜻이 아니다.
AI와 Cloud Sync를 변경하는 내부 API는 실제 존재한다. 다만 일반 defaults
키로 끄는 방식이나 외부에서 내부 API를 안정적으로 호출하는 방법은 확인하지
못했다. 따라서 이번 조사로 Pro 비활성화가 구현되거나 적용된 것은 아니다.

| 대상                   | 확인된 경로                                            | 확인 수준                          |
| ---------------------- | ------------------------------------------------------ | ---------------------------------- |
| AI 전체                | 내부 확장 설정의 `enabled: false`                      | 공식 UI 및 로컬 배포 코드에서 확인 |
| Cloud Sync             | `settings.toggleCloudSyncSettings({ enabled: false })` | 공식 UI 및 로컬 배포 코드에서 확인 |
| 명령 숨기기            | 명령별 활성화 설정                                     | 공식 문서에 존재                   |
| Pro 전체 일괄 끄기     | 단일 키·명령 미확인                                    | 없다고 단정할 수 없음              |
| 외부 settings API 호출 | 앱 내부 RPC 존재, 외부 진입점 미확인                   | 구현 가능성을 추가 검증해야 함     |

## 로컬 2.11.1.0에서 직접 확인한 근거

아래는 설치된 앱 파일의 정적 읽기 결과다. DB·Keychain 비밀값을 읽거나
프로세스에 코드를 주입하지 않았다.

리소스 기준 경로:
`/Applications/Raycast.app/Contents/Resources/macos-app_RaycastDesktopApp.bundle/Contents/Resources/`

1. `frontend/ai-settings-view-Ia7kcAbO.js`: AI 전역 스위치는 내부 확장 설정의
   `enabled`를 읽고, 변경 시 `C({enabled: !de.enabled})`를 호출한다.
   이 호출은 `Re(D.id)`에서 얻는 확장 설정 업데이트 함수다.
2. `frontend/startup-BaQB8Hzu.js`: `settings.updateInternalExtensionSettings`,
   `settings.getInternalExtensionSettings`, `settings.getCloudSyncSettings`,
   `settings.toggleCloudSyncSettings`의 backend RPC 프록시가 존재한다.
3. `backend/index.mjs`: `updateInternalExtensionSettings`는 `extensionId`와
   `update`를 받아 저장소를 갱신하고 host/frontend에 변경을 알린다.
   `enabled`가 달라지면 추가 갱신 동작도 실행한다.
4. 같은 backend의 `toggleCloudSyncSettings`는 `c8.setEnabled(e.enabled)`를
   호출한다. 단순 DB 값 변경이 실제 서비스 상태 변경과 같다고 볼 수 없다.
5. 로컬 plist에 AI·Pro·Cloud Sync 설정 키는 발견되지 않았다.
   `settings.db`, `settings_v2.db`는 읽기 전용 sqlite3 연결에서
   `file is not a database`를 반환했다. 일반 SQLite DB로 취급할 수 없다.

파일명에 빌드 해시가 들어 있으므로 업데이트 후 경로와 구현을 재확인해야 한다.
내부 API가 존재한다는 사실만으로 외부 CLI에서 호출할 수 있다고 주장하지 않는다.

## 외부 자료 교차 확인

- [공식 Settings](https://manual.raycast.com/settings): AI 전체 토글 및 명령별
  비활성화를 지원한다. 따라서 앱 기능 자체를 끌 수 없다는 설명은 틀리다.
- [공식 Cloud Sync](https://manual.raycast.com/cloud-sync): 동기화는 별도 토글이다.
  끄면 이 기기의 로컬 콘텐츠를 유지하고 서버 데이터는 삭제하지 않는다.
- [공식 MDM](https://manual.raycast.com/enterprise/mdm-deployment): 공개된 관리
  프로필 키는 제한적이다. 이 목록만으로 모든 비공식 설정 경로를 부정할 수 없다.
- [공식 Import & Export](https://manual.raycast.com/import-export): 암호화된
  `.rayconfig`로 설정을 옮기는 공식 경로다. 선언적 상태 강제 적용 API와는 다르다.
- [oma-cast의 v2.8.2 저장 구조 직접 분석](https://github.com/typecraft-dev/oma-cast/blob/main/reference/05-data-config.md):
  `settings_v2.db`에 일반·명령·내부 확장·Cloud Sync 설정이 저장된다고 기록한다.
  v1 SQLCipher와 다른 v2 암호화를 추론하며 관찰과 추론을 구분한다.
- [같은 프로젝트의 backend 직접 분석](https://github.com/typecraft-dev/oma-cast/blob/main/reference/02-backend.md):
  settings RPC와 앱 내부 stdio/WebView 연결 구조를 기록한다. 로컬 2.11.1에서
  확인한 메서드들과 일치한다.
- [확장 런타임 직접 분석](https://github.com/typecraft-dev/oma-cast/blob/main/reference/03-extensions.md):
  확장 요청에는 허용 메서드 검증이 있다. 일반 확장에서 임의 settings RPC를
  호출할 수 있다고 가정하면 안 된다.

## Nix 구현 판단

| 방식                                                  | 판단                                                          |
| ----------------------------------------------------- | ------------------------------------------------------------- |
| `CustomUserPreferences`에 추측한 AI/Pro 키 추가       | 근거 없음. 사용하지 않음                                      |
| 앱 내부 API를 호출하는 helper를 Nix activation에 연결 | 검토 가능. 외부 연결·현재 상태 읽기·반복 적용 검증 필요       |
| 앱 UI 토글을 자동화해 Nix activation에서 실행         | 기술적으로 검토 가능. UI 접근과 버전별 안정성 검증 필요       |
| 설정 DB 전체를 Nix store에 복사                       | 계정별 암호화·다른 설정 포함 때문에 이번 목적에 부적합        |
| `.rayconfig` 배포                                     | 백업 운반 가능. 자동 가져오기·재적용을 해결했다는 의미는 아님 |

`aiDisabled`, `showProFeatures`, `cloudSyncEnabled`를 macOS defaults 키로
사용하는 유효한 공개 코드 근거는 이번 검색에서 찾지 못했다. 검색 실패가
그런 키의 부재를 증명하지는 않는다.

다음 검증은 외부 호출 진입점을 찾고, AI 하나만 끄는 최소 실험에서 현재 상태
읽기 → 변경 → 앱 동작 확인 → 반복 적용을 통과시키는 것이다. 그 전에는
Pro 전체 비활성화가 Nix로 동작한다고 표시하지 않는다.

## 후속 실행 검증: 저장소 라이브러리 직접 호출

로컬 Raycast의 Node 26.12.1 런타임으로 앱에 포함된
`backend/data.darwin-arm64.node`를 불러오는 데 성공했다.
`DatabaseClient.settings`에 다음 메서드가 실제로 노출되어 있었다.

- `getInternalExtensionSettings`, `allInternalExtensionsSettings`
- `updateInternalExtensionSettings`
- `getCloudSyncSettings`, `toggleCloudSyncSettings`
- `shutdown`은 `DatabaseClient`에 존재한다.

따라서 외부 Node 프로세스에서 라이브러리를 사용하는 경로 자체는 존재한다.
이는 실행 중인 Raycast에 연결되는 RPC가 아니라 별도의 DB 연결이다.

### 실패한 최소 실험

1. 로그인 키체인의 `com.raycast.macos` / `database_key_backup` 항목 읽기에
   성공했다. 값은 출력·파일 저장·Nix store 전달하지 않았다.
2. 사용자 전용 임시 디렉터리에 암호화 DB와 WAL, `last_key`를 복사했다.
   실험은 복사본에만 수행했다.
3. 앱 backend와 동일한 형태인
   `new DatabaseClient(snapshotDirectory, key, logger)`로 열었다.
4. `initReport.overallSuccess`는 `false`였고 Main DB가
   `file is not a database (sqlite error code 26)`로 실패했다.
   라이브러리는 `Encryption key mismatch`와
   `Last used key different from current one`도 보고했다.
5. DB 연결을 종료하고 실험용 복사본을 제거했다. 원본 DB 설정은 변경하지 않았다.

현재 접근 가능한 백업 키로는 이 DB 복사본을 열지 못했다. 백업 키와 실제
키의 관계, 키 변환 과정, 실행 중 WAL 복사 조건을 추가로 검증하기 전에는
원인을 하나로 단정할 수 없다. 일반 로그인 키체인에서 `database_key`와
`classic_database_key` 항목은 발견하지 못했다.

AI 상태 읽기부터 성공하지 못했으므로 비활성화·반복 적용·재시작 후 유지도
검증하지 못했다. 이 경로를 Nix activation에 연결하지 않았다.
