#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Analyze every VHDL file of the core with nvc (https://github.com/nickg/nvc)
# in files.qip order - a fast syntax/type check without Quartus.
#   brew install nvc && sim/run_analyze_all.sh
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

WORK=sim/nvc_work
mkdir -p "$WORK"

# functional altsyncram model into a library named altera_mf
nvc --work="$WORK/altera_mf" -L "$WORK" -a sim/nvc/altera_mf_sim.vhd

# all VHDL files in files.qip order (dependency order)
FILES=$(sed -n 's/^set_global_assignment -name VHDL_FILE //p' files.qip)
# shellcheck disable=SC2086
nvc --work="$WORK/work" -L "$WORK" -a $FILES

echo "OK: all core VHDL analyzed"
