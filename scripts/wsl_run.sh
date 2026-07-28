#!/usr/bin/env bash
sed -i 's/\r$//' /mnt/c/Nagarro/ai-avengers/scripts/wsl_bootstrap_and_run.sh
exec bash /mnt/c/Nagarro/ai-avengers/scripts/wsl_bootstrap_and_run.sh
