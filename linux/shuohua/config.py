"""Configuration loaded from ~/.config/shuohua/config.yaml."""

from __future__ import annotations

import os
from dataclasses import dataclass, field, fields, asdict
from pathlib import Path

import yaml

_CONFIG_DIR = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "shuohua"
_CONFIG_FILE = _CONFIG_DIR / "config.yaml"


@dataclass
class Config:
    # Text correction
    correction_enabled: bool = True

    # Provider: "deepseek" | "groq" | "custom"
    provider: str = "deepseek"

    # DeepSeek
    deepseek_api_key: str = ""

    # Groq
    groq_api_key: str = ""
    groq_model: str = "llama-3.3-70b-versatile"

    # Custom (OpenAI-compatible)
    custom_endpoint: str = ""
    custom_model: str = ""
    custom_api_key: str = ""


def load() -> Config:
    """Load config from YAML file, creating defaults if missing."""
    if not _CONFIG_FILE.exists():
        cfg = Config()
        save(cfg)
        return cfg

    with open(_CONFIG_FILE, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}

    valid_keys = {fld.name for fld in fields(Config)}
    filtered = {k: v for k, v in data.items() if k in valid_keys}
    return Config(**filtered)


def save(cfg: Config) -> None:
    """Save config to YAML file."""
    _CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    with open(_CONFIG_FILE, "w", encoding="utf-8") as f:
        yaml.dump(asdict(cfg), f, default_flow_style=False, allow_unicode=True)


def get_config_path() -> str:
    return str(_CONFIG_FILE)
