"""OpenAI-compatible HTTP client for LLM APIs."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

import httpx

from .config import Config
from .logger import slog

_TIMEOUT = 15.0


@dataclass
class LLMProvider:
    endpoint: str
    model: str
    api_key: str


def resolve(cfg: Config) -> Optional[LLMProvider]:
    """Resolve the configured LLM provider, or None if not configured."""
    provider = cfg.provider

    if provider == "dashscope":
        if not cfg.dashscope_api_key:
            return None
        return LLMProvider(
            endpoint="https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
            model="qwen-turbo",
            api_key=cfg.dashscope_api_key,
        )
    elif provider == "groq":
        if not cfg.groq_api_key:
            return None
        return LLMProvider(
            endpoint="https://api.groq.com/openai/v1/chat/completions",
            model=cfg.groq_model or "llama-3.3-70b-versatile",
            api_key=cfg.groq_api_key,
        )
    elif provider == "custom":
        if not all([cfg.custom_api_key, cfg.custom_endpoint, cfg.custom_model]):
            return None
        return LLMProvider(
            endpoint=cfg.custom_endpoint,
            model=cfg.custom_model,
            api_key=cfg.custom_api_key,
        )
    else:  # deepseek (default)
        if not cfg.deepseek_api_key:
            return None
        return LLMProvider(
            endpoint="https://api.deepseek.com/v1/chat/completions",
            model="deepseek-chat",
            api_key=cfg.deepseek_api_key,
        )


def chat_completion(
    provider: LLMProvider, system_prompt: str, user_message: str,
    proxy: str = "",
) -> Optional[str]:
    """Send a chat completion request. Returns the response content or None."""
    body = {
        "model": provider.model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_message},
        ],
        "temperature": 0.0,
    }

    try:
        resp = httpx.post(
            provider.endpoint,
            json=body,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {provider.api_key}",
            },
            timeout=_TIMEOUT,
            proxy=proxy or None,
        )
        resp.raise_for_status()
        data = resp.json()
        return data["choices"][0]["message"]["content"]
    except Exception as e:
        slog(f"LLM API 错误: {e}")
        return None
