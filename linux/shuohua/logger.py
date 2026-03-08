"""Logging to /tmp/shuohua.log + console."""

import logging
import sys

_LOG_PATH = "/tmp/shuohua.log"

_logger = logging.getLogger("shuohua")
_logger.setLevel(logging.DEBUG)
_logger.propagate = False

_fmt = logging.Formatter("[shuohua] %(message)s")

_sh = logging.StreamHandler(sys.stdout)
_sh.setFormatter(_fmt)
_logger.addHandler(_sh)

_fh = logging.FileHandler(_LOG_PATH, mode="a", encoding="utf-8")
_fh.setFormatter(_fmt)
_logger.addHandler(_fh)


def slog(msg: str) -> None:
    _logger.info(msg)


def get_log_path() -> str:
    return _LOG_PATH
