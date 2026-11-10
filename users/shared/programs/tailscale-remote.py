"""List tailnet peers or open a RustDesk session by peer name."""

import json
from pathlib import Path
import subprocess
import sys


def main():
    if len(sys.argv) > 2:
        raise ValueError("사용법: dotfiles-remote [호스트 이름]")
    binary = "/Applications/Tailscale.app/Contents/MacOS/Tailscale"
    if not Path(binary).is_file():
        raise ValueError("Tailscale 앱을 먼저 설치하세요.")
    result = subprocess.run(
        [binary, "status", "--json"], capture_output=True, text=True, timeout=15
    )
    if result.returncode:
        raise ValueError("Tailscale 앱을 열어 연결 상태를 확인하세요.")
    status = json.loads(result.stdout)
    if status.get("BackendState") != "Running":
        raise ValueError("Tailscale 앱에서 최초 로그인과 VPN 연결을 완료하세요.")
    peers = list((status.get("Peer") or {}).values())
    if len(sys.argv) == 1:
        for peer in sorted(peers, key=lambda p: p["HostName"]):
            state = "온라인" if peer.get("Online") else "오프라인"
            print(f'{peer["HostName"]}\t{state}')
        return
    name = sys.argv[1].lower().rstrip(".")
    matches = [
        peer for peer in peers
        if name in {peer["HostName"].lower(), peer.get("DNSName", "").lower().rstrip(".")}
    ]
    if len(matches) != 1:
        raise ValueError("호스트 이름이 없거나 중복됩니다. dotfiles-remote로 목록을 확인하세요.")
    addresses = matches[0].get("TailscaleIPs") or []
    if not addresses:
        raise ValueError("해당 호스트의 Tailscale 주소가 없습니다.")
    rustdesk = "/Applications/RustDesk.app/Contents/MacOS/RustDesk"
    if not Path(rustdesk).is_file():
        raise ValueError("RustDesk 앱을 먼저 설치하세요.")
    subprocess.Popen([rustdesk, "--connect", addresses[0]], start_new_session=True)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        # Do not relay command output (which can contain account information).
        message = str(error) if isinstance(error, ValueError) else "앱 실행에 실패했습니다."
        print(message, file=sys.stderr)
        sys.exit(1)
