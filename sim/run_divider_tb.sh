#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
# divider unit test with nvc (https://github.com/nickg/nvc)
#   brew install nvc && sim/run_divider_tb.sh
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

WORK=sim/nvc_work
mkdir -p "$WORK"

nvc --work="$WORK/work" -a \
   rtl/divider.vhd \
   sim/tb_divider.vhd

nvc --work="$WORK/work" -e tb_divider
nvc --work="$WORK/work" -r tb_divider --stop-time=100us --exit-severity=failure
