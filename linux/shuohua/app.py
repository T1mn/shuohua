"""Main controller that orchestrates all modules."""

from __future__ import annotations

import threading
import sys

from . import config
from .logger import slog
from .recorder import Recorder
from .asr import ASREngine
from . import filler_cleaner
from . import text_inserter
from .hotkey import HotkeyManager
from .tray import TrayIcon
from . import notifier


class App:
    def __init__(self) -> None:
        self.cfg = config.load()
        self.recorder = Recorder()
        self.asr = ASREngine()
        self.hotkey = HotkeyManager()
        self.tray = TrayIcon()

        self._is_recording = False
        self._lock = threading.Lock()

    def run(self) -> None:
        slog("应用启动")

        # Start hotkey listener
        self.hotkey.on_toggle = self._toggle
        self.hotkey.start()

        # Load ASR model in background
        threading.Thread(target=self._load_asr, daemon=True).start()

        # Run tray icon on main thread (blocks)
        self.tray.run(quit_callback=self._shutdown)

    def _load_asr(self) -> None:
        try:
            notifier.notify("说话", "正在加载语音识别模型...")
            ms = self.asr.load_model()
            self.tray.set_idle()
            notifier.notify("说话", f"模型加载完成 ({ms}ms)")
        except Exception as e:
            slog(f"ASR 模型加载失败: {e}")
            notifier.notify("说话 — 错误", f"模型加载失败: {e}", timeout_ms=5000)

    def _toggle(self) -> None:
        with self._lock:
            slog(f"toggle: is_recording={self._is_recording}")
            if self._is_recording:
                self._stop_and_transcribe()
            else:
                self._start_recording()

    def _start_recording(self) -> None:
        if not self.asr.is_loaded:
            slog("ASR 模型未加载，忽略录音请求")
            notifier.notify("说话", "模型尚未加载完成，请稍候")
            return

        try:
            self.recorder.start()
            self._is_recording = True
            self.tray.set_recording(True)
        except Exception as e:
            slog(f"录音启动失败: {e}")
            notifier.notify("说话 — 错误", f"录音失败: {e}")

    def _stop_and_transcribe(self) -> None:
        samples = self.recorder.stop()
        self._is_recording = False
        self.tray.set_recording(False)

        if len(samples) == 0:
            slog("录音为空，跳过转录")
            return

        slog("开始转录...")
        threading.Thread(
            target=self._transcribe_thread,
            args=(samples,),
            daemon=True,
        ).start()

    def _transcribe_thread(self, samples) -> None:
        # Reload config in case user edited it
        self.cfg = config.load()

        # Transcribe without streaming insertion
        text, ms = self.asr.transcribe(samples)
        slog(f"转录完成: {text} ({ms}ms)")

        # Correct text if configured
        final_text = text
        if filler_cleaner.is_configured(self.cfg):
            notifier.notify("说话", "修正中...")
            cleaned = filler_cleaner.clean(self.cfg, text)
            if cleaned and cleaned != text:
                slog(f"文本修正: {cleaned}")
                final_text = cleaned
            else:
                slog("文本无需修正")
        else:
            slog("跳过文本修正: 未设置 API Key")

        # Insert final text in one batch
        text_inserter.insert_delta(final_text)

    def _shutdown(self) -> None:
        slog("应用关闭")
        self.hotkey.stop()
        sys.exit(0)
