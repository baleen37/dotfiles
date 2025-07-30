#!/usr/bin/env python3
"""
macOS 키보드 입력 설정 스크립트
Shift+Cmd+Space로 한영 전환 설정을 적용합니다.
"""

import plistlib
import os
import shutil
import sys
from datetime import datetime


def create_backup(plist_path):
    """plist 파일의 백업을 생성합니다."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{plist_path}.backup.{timestamp}"

    try:
        if os.path.exists(plist_path):
            shutil.copy2(plist_path, backup_path)
            print(f"✅ 백업 생성: {backup_path}")
            return backup_path
        else:
            print("ℹ️  기존 설정 파일이 없습니다. 새로 생성합니다.")
            return None
    except Exception as e:
        print(f"⚠️  백업 생성 실패: {e}")
        return None


def load_plist(plist_path):
    """plist 파일을 로드합니다."""
    try:
        with open(plist_path, 'rb') as f:
            return plistlib.load(f)
    except FileNotFoundError:
        print("ℹ️  설정 파일이 없습니다. 새로 생성합니다.")
        return {}
    except Exception as e:
        print(f"❌ 설정 파일 로드 실패: {e}")
        return {}


def save_plist(data, plist_path):
    """plist 파일을 저장합니다."""
    try:
        # 디렉토리 생성
        os.makedirs(os.path.dirname(plist_path), exist_ok=True)

        with open(plist_path, 'wb') as f:
            plistlib.dump(data, f)
        print(f"✅ 설정 파일 저장: {plist_path}")
        return True
    except Exception as e:
        print(f"❌ 설정 파일 저장 실패: {e}")
        return False


def configure_korean_input_switching(plist_path):
    """한영 전환 키를 Shift+Cmd+Space로 설정합니다."""
    print("🔧 한영 전환 키 설정 중...")

    # 백업 생성
    backup_path = create_backup(plist_path)

    # 현재 설정 로드
    data = load_plist(plist_path)

    # AppleSymbolicHotKeys 섹션 초기화
    if 'AppleSymbolicHotKeys' not in data:
        data['AppleSymbolicHotKeys'] = {}

    # 키 ID 60과 61을 Shift+Cmd+Space로 설정
    # 60: 이전 입력 소스 선택 (Select the previous input source)
    # 61: 다음 입력 소스 선택 (Select next source in input menu)
    hotkey_config = {
        'enabled': True,
        'value': {
            'parameters': [49, 49, 1179648],  # Space (49) + Shift+Cmd (1179648)
            'type': 'standard'
        }
    }

    # 키 ID 60, 61 설정
    for key_id in ['60', '61']:
        data['AppleSymbolicHotKeys'][key_id] = hotkey_config.copy()
        print(f"  ✅ 키 ID {key_id} 설정 완료")

    # 설정 저장
    if save_plist(data, plist_path):
        print("🎉 한영 전환 키 설정이 완료되었습니다!")
        print("   👉 Shift+Cmd+Space로 한영 전환이 가능합니다")

        # 추가 안내
        print("\n📝 추가 안내:")
        print("• 시스템 환경설정 > 키보드 > 입력 소스에서 한국어 입력기가 추가되어 있는지 확인하세요")
        print("• 변경사항은 로그아웃 후 다시 로그인하거나 시스템 재시작 후 적용됩니다")
        print("• 다른 앱에서 같은 단축키를 사용하는 경우 충돌이 발생할 수 있습니다")

        if backup_path:
            print(f"• 문제가 발생하면 백업 파일을 복원하세요: {backup_path}")

        return True
    else:
        print("❌ 설정 저장에 실패했습니다.")
        return False


def verify_settings(plist_path):
    """설정이 올바르게 적용되었는지 검증합니다."""
    print("\n🔍 설정 검증 중...")

    data = load_plist(plist_path)

    if 'AppleSymbolicHotKeys' not in data:
        print("❌ AppleSymbolicHotKeys 설정이 없습니다")
        return False

    hotkeys = data['AppleSymbolicHotKeys']
    expected_params = [49, 49, 1179648]

    success = True

    for key_id in ['60', '61']:
        if key_id not in hotkeys:
            print(f"❌ 키 ID {key_id} 설정이 없습니다")
            success = False
            continue

        key_config = hotkeys[key_id]

        if not key_config.get('enabled', False):
            print(f"❌ 키 ID {key_id}가 비활성화되어 있습니다")
            success = False
            continue

        actual_params = key_config.get('value', {}).get('parameters', [])

        if actual_params != expected_params:
            print(f"❌ 키 ID {key_id} 파라미터 불일치")
            print(f"   예상: {expected_params}")
            print(f"   실제: {actual_params}")
            success = False
        else:
            print(f"✅ 키 ID {key_id} 설정 확인")

    if success:
        print("🎉 모든 설정이 올바르게 적용되었습니다!")
    else:
        print("⚠️  일부 설정에 문제가 있습니다")

    return success


def main():
    """메인 함수"""
    print("🚀 macOS 키보드 입력 설정 스크립트 시작")
    print("   목표: Shift+Cmd+Space로 한영 전환 설정")
    print()

    # HIToolbox plist 파일 경로
    plist_path = os.path.expanduser('~/Library/Preferences/com.apple.HIToolbox.plist')

    try:
        # 설정 적용
        if configure_korean_input_switching(plist_path):
            # 설정 검증
            if verify_settings(plist_path):
                print("\n✅ 설정이 성공적으로 완료되었습니다!")
                sys.exit(0)
            else:
                print("\n⚠️  설정 검증에 실패했습니다")
                sys.exit(1)
        else:
            print("\n❌ 설정 적용에 실패했습니다")
            sys.exit(1)

    except KeyboardInterrupt:
        print("\n\n⏹️  사용자에 의해 중단되었습니다")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ 예상치 못한 오류 발생: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
