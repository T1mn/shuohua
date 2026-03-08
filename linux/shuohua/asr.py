"""Qwen3-ASR speech recognition on CUDA via qwen-asr library."""

from __future__ import annotations

import os
import time
from typing import Callable, Optional, Tuple

import numpy as np

from .logger import slog

# Use cached model offline — skip HuggingFace connectivity checks
os.environ.setdefault("HF_HUB_OFFLINE", "1")
os.environ.setdefault("TRANSFORMERS_OFFLINE", "1")

_MAX_CHUNK_SECONDS = 25
_SAMPLE_RATE = 16000
_MAX_CHUNK_SAMPLES = _MAX_CHUNK_SECONDS * _SAMPLE_RATE
_MODEL_ID = "Qwen/Qwen3-ASR-0.6B"


class ASREngine:
    def __init__(self) -> None:
        self._model = None

    def load_model(
        self, progress: Optional[Callable[[str], None]] = None
    ) -> int:
        """Load Qwen3-ASR model. Returns load time in ms."""
        start = time.monotonic()
        if progress:
            progress("正在加载 Qwen3-ASR 模型...")

        from qwen_asr import Qwen3ASRModel

        self._model = Qwen3ASRModel.from_pretrained(
            _MODEL_ID, device_map="auto"
        )

        ms = int((time.monotonic() - start) * 1000)
        slog(f"ASR 模型加载完成 ({ms}ms)")
        return ms

    @property
    def is_loaded(self) -> bool:
        return self._model is not None

    def transcribe(
        self,
        samples: np.ndarray,
        sample_rate: int = _SAMPLE_RATE,
        on_chunk: Optional[Callable[[str], None]] = None,
    ) -> Tuple[str, int]:
        """Transcribe audio samples. Returns (text, duration_ms)."""
        if self._model is None:
            raise RuntimeError("ASR model not loaded")

        start = time.monotonic()
        full_text = ""

        # Split into chunks of max 25 seconds
        chunks = [
            samples[i : i + _MAX_CHUNK_SAMPLES]
            for i in range(0, len(samples), _MAX_CHUNK_SAMPLES)
        ]

        for chunk in chunks:
            # qwen-asr expects (ndarray, sample_rate) tuple
            results = self._model.transcribe((chunk, sample_rate))
            text = results[0].text if results else ""
            full_text += text
            if on_chunk:
                on_chunk(text)

        ms = int((time.monotonic() - start) * 1000)
        return full_text, ms
