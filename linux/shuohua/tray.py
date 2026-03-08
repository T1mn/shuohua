"""System tray icon using pystray."""

from __future__ import annotations

import os
import subprocess
import threading
from typing import Callable, Optional

from PIL import Image, ImageDraw

# Force gtk backend — appindicator raises ValueError (not ImportError)
# when the GIR typelib is missing, crashing pystray's fallback logic.
os.environ.setdefault("PYSTRAY_BACKEND", "gtk")
import pystray

from .config import get_config_path
from .logger import slog, get_log_path


def _make_circle(color: str, size: int = 64) -> Image.Image:
    """Create a circle icon."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse([4, 4, size - 4, size - 4], fill=color)
    return img


_ICON_IDLE = _make_circle("#808080")     # gray = idle
_ICON_RECORDING = _make_circle("#FF0000") # red = recording
_ICON_LOADING = _make_circle("#FFA500")   # orange = loading


class TrayIcon:
    def __init__(self) -> None:
        self._icon: Optional[pystray.Icon] = None
        self._is_recording = False
        self._quit_callback: Optional[Callable[[], None]] = None

    def set_recording(self, recording: bool) -> None:
        self._is_recording = recording
        if self._icon is not None:
            self._icon.icon = _ICON_RECORDING if recording else _ICON_IDLE
            self._icon.title = "说话 — 录音中..." if recording else "说话"

    def set_loading(self) -> None:
        if self._icon is not None:
            self._icon.icon = _ICON_LOADING
            self._icon.title = "说话 — 加载模型中..."

    def set_idle(self) -> None:
        if self._icon is not None:
            self._icon.icon = _ICON_IDLE
            self._icon.title = "说话"

    def run(self, quit_callback: Callable[[], None]) -> None:
        """Run the tray icon (blocks the calling thread)."""
        self._quit_callback = quit_callback

        menu = pystray.Menu(
            pystray.MenuItem("双击 Ctrl 开始/停止录音", None, enabled=False),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("编辑设置...", self._open_config),
            pystray.MenuItem("查看运行日志", self._open_log),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("退出说话", self._quit),
        )

        self._icon = pystray.Icon(
            name="shuohua",
            icon=_ICON_LOADING,
            title="说话 — 加载模型中...",
            menu=menu,
        )
        self._icon.run()

    def stop(self) -> None:
        if self._icon is not None:
            self._icon.stop()

    def _open_config(self, icon: pystray.Icon, item: pystray.MenuItem) -> None:
        path = get_config_path()
        slog(f"打开配置文件: {path}")
        editor = os.environ.get("EDITOR", "xdg-open")
        try:
            subprocess.Popen([editor, path])
        except Exception as e:
            slog(f"打开编辑器失败: {e}")
            try:
                subprocess.Popen(["xdg-open", path])
            except Exception as e2:
                slog(f"xdg-open 也失败: {e2}")

    def _open_log(self, icon: pystray.Icon, item: pystray.MenuItem) -> None:
        path = get_log_path()
        slog(f"打开日志文件: {path}")
        try:
            subprocess.Popen(["xdg-open", path])
        except Exception as e:
            slog(f"打开日志失败: {e}")

    def _quit(self, icon: pystray.Icon, item: pystray.MenuItem) -> None:
        slog("用户退出")
        if self._quit_callback:
            self._quit_callback()
        self.stop()
