#!/usr/bin/env python3
"""Check Ubuntu Security Tracker status for selected CVEs and linux-aws-6.8/Jammy."""

from __future__ import annotations

import argparse
import os
import re
import sys
import urllib.error
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

PACKAGE = "linux-aws-6.8"
RELEASE = "22.04 LTS jammy"
CVES = [
    "CVE-2026-63825",
    "CVE-2026-64523",
    "CVE-2026-68426",
    "CVE-2026-90162",
    "CVE-2026-93221",
]
BASE_URL = "https://ubuntu.com/security/"


class TableRows(HTMLParser):
    """Extract table rows/cells while ignoring markup inside each cell."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.rows: list[list[str]] = []
        self._row: list[str] | None = None
        self._cell: list[str] | None = None

    def handle_starttag(self, tag: str, attrs) -> None:
        tag = tag.lower()
        if tag == "tr":
            self._row = []
        elif tag in {"td", "th"} and self._row is not None:
            self._cell = []

    def handle_data(self, data: str) -> None:
        if self._cell is not None:
            self._cell.append(data)

    def handle_endtag(self, tag: str) -> None:
        tag = tag.lower()
        if tag in {"td", "th"} and self._cell is not None and self._row is not None:
            value = re.sub(r"\s+", " ", "".join(self._cell)).strip()
            self._row.append(value)
            self._cell = None
        elif tag == "tr" and self._row is not None:
            if self._row:
                self.rows.append(self._row)
            self._row = None
            self._cell = None


def extract_package_release_status(html: str) -> str:
    parser = TableRows()
    parser.feed(html)

    active_package = None
    for row in parser.rows:
        cells = [re.sub(r"\s+", " ", c).strip() for c in row if c.strip()]
        if not cells:
            continue

        # Ubuntu's tracker table groups release rows under a source-package row.
        # Also support a single row containing package, release and status.
        package_cells = [c for c in cells if c == PACKAGE]
        if package_cells:
            active_package = PACKAGE
        elif cells[0].startswith("linux-"):
            active_package = cells[0] if cells[0] == PACKAGE else None

        if active_package != PACKAGE:
            continue

        for index, cell in enumerate(cells):
            if RELEASE in cell:
                if index + 1 < len(cells):
                    return cells[index + 1]
                # Some table layouts combine release and status in one cell.
                remainder = cell.split(RELEASE, 1)[-1].strip(" |:-")
                if remainder:
                    return remainder

    raise ValueError(f"Could not find {PACKAGE} / {RELEASE} row in Ubuntu tracker HTML")


def fetch_status(cve: str) -> str:
    request = urllib.request.Request(
        BASE_URL + cve,
        headers={"User-Agent": "GoldenImageFactory-CVE-Monitor/1.0"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        html = response.read().decode("utf-8", errors="replace")
    return extract_package_release_status(html)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--output", default="")
    args = parser.parse_args()

    if args.self_test:
        fixture = """
        <table>
          <tr><td>linux-aws-6.5</td><td>22.04 LTS jammy</td><td>Ignored superseded</td></tr>
          <tr><td>linux-aws-6.8</td><td>26.10 stonking</td><td>Not in release</td></tr>
          <tr><td>24.04 LTS noble</td><td>Vulnerable</td></tr>
          <tr><td>22.04 LTS jammy</td><td>Vulnerable</td></tr>
          <tr><td>linux-aws-7.0</td><td>22.04 LTS jammy</td><td>Not in release</td></tr>
        </table>
        """
        assert extract_package_release_status(fixture) == "Vulnerable"
        print("Self-test passed.")
        return 0

    rows: list[tuple[str, str]] = []
    failures: list[str] = []
    for cve in CVES:
        try:
            status = fetch_status(cve)
            rows.append((cve, status))
        except (urllib.error.URLError, TimeoutError, UnicodeError, ValueError) as exc:
            failures.append(f"{cve}: {exc}")

    report = [
        "# Ubuntu 22.04 AWS kernel CVE monitor",
        "",
        f"- Package row: `{PACKAGE}`",
        f"- Ubuntu release: `{RELEASE}`",
        "- Expected baseline: `Vulnerable`",
        "",
        "| CVE | Current Ubuntu tracker status | Result |",
        "|---|---|---|",
    ]

    changed = []
    for cve, status in rows:
        expected_vulnerable = status.lower().startswith("vulnerable")
        result = "Still open" if expected_vulnerable else "STATUS CHANGED — review"
        report.append(f"| {cve} | {status} | {result} |")
        if not expected_vulnerable:
            changed.append(f"{cve}: expected Vulnerable, now {status}")

    if failures:
        report.extend(["", "## Check errors", ""])
        report.extend(f"- {item}" for item in failures)

    if changed:
        report.extend(["", "## Status changes requiring review", ""])
        report.extend(f"- {item}" for item in changed)

    report_text = "\n".join(report) + "\n"
    print(report_text)

    summary_path = os.environ.get("GITHUB_STEP_SUMMARY", "")
    if summary_path:
        with open(summary_path, "a", encoding="utf-8") as handle:
            handle.write(report_text)
    output_path = args.output or os.path.join(os.environ.get("RUNNER_TEMP", "/tmp"), "ubuntu-cve-status.md")
    Path(output_path).write_text(report_text, encoding="utf-8")

    if failures:
        print("One or more tracker checks failed; status is unknown, not fixed.", file=sys.stderr)
        return 3
    if changed:
        print("Ubuntu tracker status changed; review the CVEs before modifying the image.", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
