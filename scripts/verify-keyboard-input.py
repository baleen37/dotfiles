#!/usr/bin/env python3
"""
macOS 키보드 입력 설정 검증 스크립트
설정된 키보드 입력 변경사항을 확인합니다.
"""

import plistlib
import os
import sys

def load_plist(plist_path):
    """plist 파일을 로드합니다."""
    try:
        with open(plist_path, 'rb') as f:
            return plistlib.load(f)
    except FileNotFoundError:
        return None
    except Exception as e:
        print(f"❌ 설정 파일 로드 실패: {e}")
        return None

def verify_keyboard_settings(plist_path):
    """키보드 설정을 검증합니다."""
    print("🔍 키보드 입력 설정 검증")
    print(f"   파일: {plist_path}")
    print()

    # 파일 존재 여부 확인
    if not os.path.exists(plist_path):
        print("❌ 설정 파일이 존재하지 않습니다")
        return False

    # plist 파일 로드
    data = load_plist(plist_path)
    if data is None:
        print("❌ 설정 파일을 읽을 수 없습니다")
        return False

    # AppleSymbolicHotKeys 섹션 확인
    if 'AppleSymbolicHotKeys' not in data:
        print("❌ AppleSymbolicHotKeys 설정이 없습니다")
        return False

    hotkeys = data['AppleSymbolicHotKeys']
    expected_params = [49, 49, 1179648]  # Space + Shift+Cmd

    print("📋 키보드 단축키 설정 확인:")

    success = True

    for key_id in ['60', '61']:
        key_name = "이전 입력 소스" if key_id == '60' else "다음 입력 소스"

        if key_id not in hotkeys:
            print(f"❌ 키 ID {key_id} ({key_name}) 설정이 없습니다")
            success = False
            continue

        key_config = hotkeys[key_id]

        # 활성화 상태 확인
        enabled = key_config.get('enabled', False)
        print(f"   키 ID {key_id} ({key_name}):")
        print(f"     활성화: {'✅ 예' if enabled else '❌ 아니오'}")

        if not enabled:
            success = False
            continue

        # 파라미터 확인
        actual_params = key_config.get('value', {}).get('parameters', [])
        params_match = actual_params == expected_params

        print(f"     파라미터: {actual_params}")
        print(f"     예상값: {expected_params}")
        print(f"     일치: {'✅ 예' if params_match else '❌ 아니오'}")

        if not params_match:
            success = False

        print()

    return success


def show_keyboard_shortcuts_info():
    """키보드 단축키 정보를 출력합니다."""
    print("📖 키보드 단축키 정보:")
    print("   키 ID 60: 이전 입력 소스 선택 (Select the previous input source)")
    print("   키 ID 61: 다음 입력 소스 선택 (Select next source in input menu)")
    print("   설정값: [49, 49, 1179648] = Space + Shift+Cmd")
    print()
    print("🎯 사용법:")
    print("   Shift+Cmd+Space를 눌러 한영 전환")
    print()
    print("📝 주의사항:")
    print("• 시스템 환경설정 > 키보드 > 입력 소스에서 한국어 입력기 추가 필요")
    print("• 변경사항은 로그아웃 후 재로그인 또는 시스템 재시작 후 적용")
    print("• 다른 앱의 단축키와 충돌할 수 있음")
    print()


def main():
    """메인 함수"""
    print("🔍 macOS 키보드 입력 설정 검증 스크립트")
    print()

    # HIToolbox plist 파일 경로
    plist_path = os.path.expanduser('~/Library/Preferences/com.apple.HIToolbox.plist')

    try:
        # 설정 검증
        if verify_keyboard_settings(plist_path):
            print("🎉 모든 키보드 설정이 올바르게 적용되었습니다!")
            show_keyboard_shortcuts_info()
            sys.exit(0)
        else:
            print("⚠️  키보드 설정에 문제가 있습니다")
            print("   configure-keyboard-input.py 스크립트를 실행하여 설정을 다시 적용하세요")
            show_keyboard_shortcuts_info()
            sys.exit(1)

    except KeyboardInterrupt:
        print("\n\n⏹️  사용자에 의해 중단되었습니다")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ 예상치 못한 오류 발생: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
