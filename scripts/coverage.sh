#!/usr/bin/env bash
# MaraCore 코드 커버리지 리포트 + 플로어 게이트.
# `swift test --enable-code-coverage` 산출물(profdata + xctest 바이너리)을 읽어 Sources/의
# 라인 커버리지를 계산하고, COVERAGE_MIN 미만이면 CI를 실패시킨다.
#
# 자체 완결 — 외부 서비스(Codecov 등) 없이 llvm-cov만 사용. 리포트는 CI Step Summary에 남긴다.
# OS 어댑터(IOKit/NSWorkspace/Dispatch 래퍼)는 태생적으로 유닛테스트 불가라 총합을 끌어내리므로,
# 플로어는 "의미 있는 회귀만 잡되 어댑터 노이즈엔 여유"를 두고 정한다(기본 80%).
set -euo pipefail

MIN="${COVERAGE_MIN:-80}"
cd "$(dirname "$0")/../MaraCore"

BIN_PATH="$(swift build --show-bin-path)"
PROF="$BIN_PATH/codecov/default.profdata"
XCTEST="$(find "$BIN_PATH" -maxdepth 1 -name '*.xctest' | head -1)"
BIN="$XCTEST/Contents/MacOS/$(basename "$XCTEST" .xctest)"
if [ ! -f "$PROF" ] || [ ! -x "$BIN" ]; then
  echo "::error::coverage artifacts missing — run 'swift test --enable-code-coverage' first"
  exit 1
fi

REPORT="$(xcrun llvm-cov report "$BIN" -instr-profile "$PROF" Sources/)"
# 판정은 원시값(RAW_COV)으로, 표시만 반올림(COV) — 반올림값을 게이트에 쓰면 79.96%가
# 80.0%로 반올림돼 통과하는 fail-open 틈이 생긴다(표시 눈금 ≠ 판정값).
RAW_COV="$(xcrun llvm-cov export "$BIN" -instr-profile "$PROF" -summary-only Sources/ \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["data"][0]["totals"]["lines"]["percent"])')"
COV="$(python3 -c "print(round(float('${RAW_COV}'), 1))")"

# 리포트를 CI Step Summary(있으면)와 로그에 남긴다.
{
  echo "### MaraCore line coverage: ${COV}% (floor ${MIN}%)"
  echo ''
  echo '```'
  echo "$REPORT"
  echo '```'
} >> "${GITHUB_STEP_SUMMARY:-/dev/stdout}"

echo "MaraCore line coverage: ${COV}% (floor ${MIN}%)"
if python3 -c "import sys; sys.exit(0 if float('${RAW_COV}') >= float('${MIN}') else 1)"; then
  echo "✅ coverage OK"
else
  echo "::error::coverage ${COV}% is below floor ${MIN}% — add tests or adjust COVERAGE_MIN"
  exit 1
fi
