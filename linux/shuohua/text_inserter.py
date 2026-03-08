"""X11 text insertion using xdotool and xclip."""

from __future__ import annotations

import subprocess
import time

from .logger import slog


def _set_clipboard(text: str) -> None:
    """Set both clipboard and primary selection using xsel (synchronous)."""
    encoded = text.encode("utf-8")
    subprocess.run(
        ["xsel", "--clipboard", "--input"],
        input=encoded, check=True, timeout=2,
    )
    subprocess.run(
        ["xsel", "--primary", "--input"],
        input=encoded, check=True, timeout=2,
    )


def _paste() -> None:
    """Simulate paste: Shift+Insert (universal for both terminal and GUI)."""
    subprocess.run(
        ["xdotool", "key", "--clearmodifiers", "shift+Insert"],
        check=True,
        timeout=5,
    )


def insert_delta(text: str) -> None:
    """Paste text via clipboard (xsel + Ctrl+V). Reliable for CJK."""
    if not text:
        return
    try:
        _set_clipboard(text)
        _paste()
    except Exception as e:
        slog(f"文本插入失败: {e}")


def replace(delete_count: int, text: str) -> None:
    """Delete old text via BackSpace, then paste new text via clipboard."""
    if delete_count <= 0 and not text:
        return

    try:
        # Delete old characters using BackSpace
        if delete_count > 0:
            subprocess.run(
                ["xdotool", "key", "--clearmodifiers"] + ["BackSpace"] * delete_count,
                check=True,
                timeout=10,
            )
            time.sleep(0.1)

        if not text:
            return

        # Paste new text
        _set_clipboard(text)
        time.sleep(0.05)
        _paste()

    except Exception as e:
        slog(f"文本替换失败: {e}")
