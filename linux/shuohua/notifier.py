"""Desktop notifications via notify-send."""

from __future__ import annotations

import subprocess

from .logger import slog


def notify(summary: str, body: str = "", timeout_ms: int = 2000) -> None:
    """Show a desktop notification using notify-send."""
    cmd = [
        "notify-send",
        "--app-name=说话",
        f"--expire-time={timeout_ms}",
        summary,
    ]
    if body:
        cmd.append(body)
    try:
        subprocess.run(cmd, check=True, timeout=5)
    except Exception as e:
        slog(f"通知失败: {e}")
