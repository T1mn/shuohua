"""Configuration loaded from ~/.config/shuohua/config.yaml."""

from __future__ import annotations

import os
from dataclasses import dataclass, field, fields, asdict
from pathlib import Path

import yaml
from dotenv import load_dotenv

# Load .env file from project root
_PROJECT_ROOT = Path(__file__).parent.parent
load_dotenv(_PROJECT_ROOT / ".env")

_CONFIG_DIR = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "shuohua"
_CONFIG_FILE = _CONFIG_DIR / "config.yaml"


@dataclass
class Config:
    # Text correction
    correction_enabled: bool = True

    # Provider: "dashscope" | "deepseek" | "groq" | "custom"
    provider: str = "dashscope"

    # DashScope (Alibaba Cloud Qwen) - hardcoded endpoint & model
    dashscope_api_key: str = ""

    # DeepSeek
    deepseek_api_key: str = ""

    # Groq
    groq_api_key: str = ""
    groq_model: str = "llama-3.3-70b-versatile"

    # Custom (OpenAI-compatible)
    custom_endpoint: str = ""
    custom_model: str = ""
    custom_api_key: str = ""

    # HTTP proxy for LLM API calls
    proxy: str = ""


def load() -> Config:
    """Load config from .env and YAML file."""
    if not _CONFIG_FILE.exists():
        cfg = Config()
        save(cfg)
    else:
        with open(_CONFIG_FILE, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}
        valid_keys = {fld.name for fld in fields(Config)}
        filtered = {k: v for k, v in data.items() if k in valid_keys}
        cfg = Config(**filtered)

    # Override with environment variables from .env
    cfg.dashscope_api_key = os.getenv("DASHSCOPE_API_KEY", cfg.dashscope_api_key)
    cfg.deepseek_api_key = os.getenv("DEEPSEEK_API_KEY", cfg.deepseek_api_key)
    cfg.groq_api_key = os.getenv("GROQ_API_KEY", cfg.groq_api_key)
    cfg.proxy = os.getenv("HTTPS_PROXY") or os.getenv("https_proxy") or cfg.proxy

    return cfg


def save(cfg: Config) -> None:
    """Save config to YAML file."""
    _CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    with open(_CONFIG_FILE, "w", encoding="utf-8") as f:
        yaml.dump(asdict(cfg), f, default_flow_style=False, allow_unicode=True)


def get_config_path() -> str:
    return str(_CONFIG_FILE)
