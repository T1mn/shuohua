"""LLM-based filler word cleaner for ASR output."""

from __future__ import annotations

import time
from typing import Optional

from .config import Config
from .logger import slog
from . import llm_client

_SYSTEM_PROMPT = "简短修正下述语音转文字结果，删除填充词（呃嗯啊哦那个就是说）和重复词，保持原意和语序。"

_USER_TEMPLATE = "{{{input}}}"


def is_configured(cfg: Config) -> bool:
    if not cfg.correction_enabled:
        return False
    return llm_client.resolve(cfg) is not None


def clean(cfg: Config, text: str) -> Optional[str]:
    """Clean filler words from text using LLM. Returns cleaned text or None."""
    if not text:
        return None

    if not cfg.correction_enabled:
        slog("FillerCleaner: 修正已关闭")
        return None

    provider = llm_client.resolve(cfg)
    if provider is None:
        slog("FillerCleaner: 未配置 API")
        return None

    user_message = _USER_TEMPLATE.replace("{input}", text)

    start = time.monotonic()
    result = llm_client.chat_completion(provider, _SYSTEM_PROMPT, user_message, proxy=cfg.proxy)
    if result is None:
        slog(f"FillerCleaner: API 调用失败 ({provider.model})")
        return None

    ms = int((time.monotonic() - start) * 1000)
    cleaned = result.strip()
    slog(f"FillerCleaner: {cleaned} ({ms}ms, {provider.model})")
    return cleaned if cleaned else None
