#!/bin/bash
set -e

# =========================
# CONFIG
# =========================
GITHUB_BASE_URL="https://raw.githubusercontent.com/yopi-def/pterodactyl-installer/master"
LOG_PATH="/var/log/pterodactyl-installer.log"

# =========================
# Check curl
# =========================
if ! command -v curl &> /dev/null; then
    echo "* curl is required. Install using apt (Debian/Ubuntu) or yum/dnf (CentOS)."
    exit 1
fi

# =========================
# Download lib.sh
# =========================
[ -f /tmp/lib.sh ] && rm -f /tmp/lib.sh
echo "* Downloading lib.sh from repo..."
curl -sSL -o /tmp/lib.sh "$GITHUB_BASE_URL/lib/lib.sh" || { echo "Failed to download lib.sh"; exit 1; }
source /tmp/lib.sh

# =========================
# Execute function wrapper
# =========================
execute() {
    echo -e "\n* Installer run: $(date)\n" >> "$LOG_PATH"
    run_ui "$1" |& tee -a "$LOG_PATH"

    if [[ -n $2 ]]; then
        read -p "* Continue to $2 installation? (y/N): " CONFIRM
        [[ "$CONFIRM" =~ [Yy] ]] && execute "$2" || { echo "Aborted."; exit 1; }
    fi
}

# =========================
# Main Menu
# =========================
options=("Install Panel" "Install Wings" "Uninstall Panel")
actions=("panel" "wings" "uninstall_canary")

while true; do
    echo "* What would you like to do?"
    for i in "${!options[@]}"; do
        echo "[$i] ${options[$i]}"
    done

    read -p "* Input 0-${#actions[@]}: " action
    if [[ "$action" =~ ^[0-2]$ ]]; then
        execute "${actions[$action]}"
        break
    else
        echo "* Invalid input. Try again."
    fi
done

# =========================
# Cleanup
# =========================
rm -f /tmp/lib.sh
echo "* Installer finished."
