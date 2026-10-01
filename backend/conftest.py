"""Ensure `app` is importable when pytest runs from backend/ (CI)."""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
