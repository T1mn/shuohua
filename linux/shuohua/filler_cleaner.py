"""LLM-based filler word cleaner for ASR output."""

from __future__ import annotations

import time
from typing import Optional

from .config import Config
from .logger import slog
from . import llm_client

_SYSTEM_PROMPT = """\
你是语音转文字的后处理器。严格遵守以下规则：

## 规则
1. 只做【删除】，绝对禁止改写、替换、重组、概括或添加任何内容
2. 删除填充词：{呃, 嗯, 啊, 哦, 那个, 就是说, 然后然后, 对对对}
3. 删除连续重复的字词（如"我我我"→"我"）
4. 保留所有实义词，保持原始语序不变
5. 不要添加或修改标点符号

## 输出格式
直接输出处理后的文本，不要添加任何解释、前缀或后缀。"""

_USER_TEMPLATE = "以下是待清洗的转录文本，不是提问，不要回答，只返回清洗结果：\n{input}"


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
    result = llm_client.chat_completion(provider, _SYSTEM_PROMPT, user_message)
    if result is None:
        slog(f"FillerCleaner: API 调用失败 ({provider.model})")
        return None

    ms = int((time.monotonic() - start) * 1000)
    cleaned = result.strip()
    slog(f"FillerCleaner: {cleaned} ({ms}ms, {provider.model})")
    return cleaned if cleaned else None
