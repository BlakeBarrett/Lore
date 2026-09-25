#!/usr/bin/env python3
"""CI coverage gate for the Lore app.

Parses `coverage/lcov.info` (produced by `flutter test --coverage`) and fails
with exit code 1 when total line coverage across lib/ drops below the
threshold. Generated localization code is excluded: it is machine-produced
(`flutter gen-l10n`) and inflates the denominator without being app logic.

lcov semantics used here (per SF record):
  DA:<line>,<hits>  — hits > 0 means the line is covered (LF/LH summaries are
                      ignored in favour of counting DA records directly, so a
                      malformed summary can never mask a regression).

Usage: python3 tool/coverage_gate.py [path/to/lcov.info] [threshold]
"""

import os
import sys

DEFAULT_LCOV = os.path.join(os.path.dirname(os.path.dirname(__file__)),
                            "coverage", "lcov.info")
THRESHOLD = 80.0

# Exclusions (substring match on the SF path): generated localization code.
EXCLUDE_SUBSTRINGS = ("/l10n/", "app_localizations")


def is_excluded(path: str) -> bool:
    return any(s in path for s in EXCLUDE_SUBSTRINGS)


def parse_lcov(path: str):
    """Return {file_path: [covered, total]} counted from DA records."""
    files = {}
    current = None
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if line.startswith("SF:"):
                current = line[3:]
                files.setdefault(current, [0, 0])
            elif line.startswith("DA:") and current is not None:
                parts = line[3:].split(",")
                if len(parts) < 2:
                    continue  # DA:<line> with no hit count: not countable
                try:
                    hits = int(parts[1])
                except ValueError:
                    continue  # "DA:<line>,-" (non-executable): skip
                record = files.setdefault(current, [0, 0])
                record[1] += 1
                if hits > 0:
                    record[0] += 1
            elif line == "end_of_record":
                current = None
    return files


def main(argv):
    lcov_path = argv[1] if len(argv) > 1 else DEFAULT_LCOV
    threshold = float(argv[2]) if len(argv) > 2 else THRESHOLD

    if not os.path.exists(lcov_path):
        print(f"FAIL: {lcov_path} not found. Run `flutter test --coverage` "
              "first.")
        return 1

    files = parse_lcov(lcov_path)
    counted = {f: v for f, v in files.items() if not is_excluded(f)}
    skipped = sorted(set(files) - set(counted))

    if not counted:
        print(f"FAIL: no coverage records found in {lcov_path}")
        return 1

    total_covered = sum(v[0] for v in counted.values())
    total_lines = sum(v[1] for v in counted.values())
    total_pct = 100.0 * total_covered / total_lines if total_lines else 0.0

    print(f"Coverage gate — {lcov_path}")
    print(f"Excluded: {', '.join(EXCLUDE_SUBSTRINGS)} "
          f"(skipped {len(skipped)} file(s))")
    print("")
    print(f"{'PCT':>6}  {'COVERED':>9}  FILE")
    print("-" * 60)
    for path in sorted(counted, key=lambda p: counted[p][0] /
                       max(counted[p][1], 1)):
        covered, lines = counted[path]
        pct = 100.0 * covered / lines if lines else 0.0
        print(f"{pct:5.1f}%  {covered:4d}/{lines:<4d}  {path}")
    print("-" * 60)
    print(f"{total_pct:5.1f}%  {total_covered:4d}/{total_lines:<4d}  TOTAL")
    print("")

    if total_pct < threshold:
        print(f"FAIL: total coverage {total_pct:.2f}% < {threshold:.1f}%")
        return 1
    print(f"PASS: total coverage {total_pct:.2f}% >= {threshold:.1f}%")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
