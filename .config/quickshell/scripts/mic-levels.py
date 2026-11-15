#!/usr/bin/env python3
"""Print one mic activity value (0-100) per ~40 ms. Runs until killed.

Levels are relative to a rolling noise floor, so a hot or noisy mic still
shows speech as movement instead of a pinned bar.
"""
import array
import collections
import math
import subprocess
import sys

RATE = 8000
CHUNK = RATE * 2 // 25  # 40 ms of s16 mono
HISTORY = 75  # ~3 s

proc = subprocess.Popen(
    ["pw-record", "--target", "@DEFAULT_SOURCE@", "--rate", str(RATE), "--channels", "1", "--format", "s16", "-"],
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL,
)
recent = collections.deque(maxlen=HISTORY)
try:
    while True:
        data = proc.stdout.read(CHUNK)
        if not data:
            break
        samples = array.array("h", data[: len(data) // 2 * 2])
        if not samples:
            continue
        mean = sum(samples) / len(samples)
        rms = math.sqrt(sum((s - mean) ** 2 for s in samples) / len(samples)) / 32768
        recent.append(rms)
        floor = min(recent)
        span = max(max(recent) - floor, floor * 1.0, 1e-4)
        print(max(0, min(100, int(math.sqrt(max(0.0, rms - floor) / span) * 100))), flush=True)
except BrokenPipeError:
    pass
finally:
    proc.kill()
