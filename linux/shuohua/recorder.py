"""Microphone recording using sounddevice, 16kHz mono float32."""

from __future__ import annotations

import threading
from typing import Optional

import numpy as np
import sounddevice as sd

from .logger import slog

_SAMPLE_RATE = 16000
_CHANNELS = 1
_BLOCK_SIZE = 4096


class Recorder:
    def __init__(self) -> None:
        self._buffer: list[np.ndarray] = []
        self._lock = threading.Lock()
        self._stream: Optional[sd.InputStream] = None

    def start(self) -> None:
        with self._lock:
            self._buffer.clear()
        self._stream = sd.InputStream(
            samplerate=_SAMPLE_RATE,
            channels=_CHANNELS,
            dtype="float32",
            blocksize=_BLOCK_SIZE,
            callback=self._callback,
        )
        self._stream.start()
        slog("录音开始")

    def _callback(
        self,
        indata: np.ndarray,
        frames: int,
        time_info: object,
        status: sd.CallbackFlags,
    ) -> None:
        if status:
            slog(f"录音状态: {status}")
        with self._lock:
            self._buffer.append(indata[:, 0].copy())

    def stop(self) -> np.ndarray:
        if self._stream is not None:
            self._stream.stop()
            self._stream.close()
            self._stream = None

        with self._lock:
            if not self._buffer:
                slog("录音停止, 采样数: 0")
                return np.array([], dtype=np.float32)
            samples = np.concatenate(self._buffer)
            self._buffer.clear()

        duration = len(samples) / _SAMPLE_RATE
        slog(f"录音停止, 采样数: {len(samples)}, 时长: {duration:.1f}s")
        return samples
