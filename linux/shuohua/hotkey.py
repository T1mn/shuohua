"""Double-tap Ctrl hotkey detection using pynput."""

from __future__ import annotations

import time
import threading
from typing import Callable, Optional

from pynput import keyboard

from .logger import slog

_DOUBLE_TAP_INTERVAL = 0.3


class HotkeyManager:
    def __init__(self) -> None:
        self.on_toggle: Optional[Callable[[], None]] = None
        self._listener: Optional[keyboard.Listener] = None
        self._ctrl_was_down = False
        self._last_ctrl_up: Optional[float] = None
        self._lock = threading.Lock()

    def start(self) -> None:
        self._listener = keyboard.Listener(
            on_press=self._on_press,
            on_release=self._on_release,
        )
        self._listener.daemon = True
        self._listener.start()
        slog(f"热键监听已启动, listener={self._listener is not None}")

    def _on_press(self, key: Optional[keyboard.Key]) -> None:
        if key in (keyboard.Key.ctrl_l, keyboard.Key.ctrl_r):
            with self._lock:
                self._ctrl_was_down = True

    def _on_release(self, key: Optional[keyboard.Key]) -> None:
        if key not in (keyboard.Key.ctrl_l, keyboard.Key.ctrl_r):
            return

        with self._lock:
            if not self._ctrl_was_down:
                return
            self._ctrl_was_down = False

            now = time.monotonic()
            if (
                self._last_ctrl_up is not None
                and now - self._last_ctrl_up < _DOUBLE_TAP_INTERVAL
            ):
                self._last_ctrl_up = None
                slog("双击 Ctrl 触发")
                if self.on_toggle:
                    self.on_toggle()
            else:
                self._last_ctrl_up = now

    def stop(self) -> None:
        if self._listener is not None:
            self._listener.stop()
            self._listener = None
