#!/usr/bin/env bash
set -e

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

clear

echo -e "${CYAN}"
echo "════════════════════════════════════════════════"
echo "        🩺  LOG DOCTOR – Server Log Analyzer"
echo "════════════════════════════════════════════════"
echo -e "${RESET}"

if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}Run as root!${RESET}"
  exit 1
fi

# Detect distro
if [ -f /etc/debian_version ]; then
  DISTRO="debian"
elif [ -f /etc/redhat-release ]; then
  DISTRO="redhat"
else
  DISTRO="unknown"
fi

echo -e "${BLUE}OS detected:${RESET} $DISTRO"

echo
echo -e "${YELLOW}Scanning /var/log...${RESET}"
TOTAL_LOG=$(du -sh /var/log | awk '{print $1}')
JOURNAL_SIZE=$(journalctl --disk-usage 2>/dev/null | awk '{print $4$5}')
BIGFILES=$(find /var/log -type f -size +50M 2>/dev/null | wc -l)

echo -e "📁 /var/log total:   ${GREEN}$TOTAL_LOG${RESET}"
echo -e "📚 Journal size:    ${GREEN}${JOURNAL_SIZE:-N/A}${RESET}"
echo -e "📄 Big files (>50M): ${GREEN}$BIGFILES${RESET}"

echo
echo -e "${YELLOW}Top 10 biggest log files:${RESET}"
find /var/log -type f -exec du -h {} \; 2>/dev/null | sort -rh | head -10

echo
echo -e "${YELLOW}Top log spammer (from syslog):${RESET}"
grep -oE "^[^ ]+" /var/log/syslog 2>/dev/null | sort | uniq -c | sort -nr | head -5 || echo "No syslog"

echo
echo -e "${CYAN}Recommended actions:${RESET}"
echo "1) Vacuum journal to 200MB"
echo "2) Truncate active logs"
echo "3) Delete rotated logs"
echo "4) Apply journald disk limits"
echo "5) Do ALL (recommended)"
echo "0) Exit"

echo
read -p "Select: " CHOICE

case "$CHOICE" in

1)
  journalctl --vacuum-size=200M
;;

2)
  echo -e "${YELLOW}Truncating active logs...${RESET}"
  find /var/log -type f ! -name "*.gz" ! -name "*.xz" -exec truncate -s 0 {} \;
;;

3)
  echo -e "${YELLOW}Removing rotated logs...${RESET}"
  rm -f /var/log/*.gz /var/log/*.[0-9] /var/log/*.[0-9].gz
;;

4)
  CONF="/etc/systemd/journald.conf"
  echo -e "${YELLOW}Applying journald limits...${RESET}"
  sed -i '/SystemMaxUse/d;/SystemKeepFree/d;/MaxRetentionSec/d' $CONF
  echo "SystemMaxUse=200M" >> $CONF
  echo "SystemKeepFree=1G" >> $CONF
  echo "MaxRetentionSec=7day" >> $CONF
  systemctl restart systemd-journald
;;

5)
  journalctl --vacuum-size=200M
  find /var/log -type f ! -name "*.gz" ! -name "*.xz" -exec truncate -s 0 {} \;
  rm -f /var/log/*.gz /var/log/*.[0-9] /var/log/*.[0-9].gz
  CONF="/etc/systemd/journald.conf"
  sed -i '/SystemMaxUse/d;/SystemKeepFree/d;/MaxRetentionSec/d' $CONF
  echo "SystemMaxUse=200M" >> $CONF
  echo "SystemKeepFree=1G" >> $CONF
  echo "MaxRetentionSec=7day" >> $CONF
  systemctl restart systemd-journald
;;

0)
  exit
;;

*)
  echo "Invalid option"
;;

esac

echo
echo -e "${GREEN}Cleanup complete.${RESET}"
echo "New /var/log usage:"
du -sh /var/log
echo
journalctl --disk-usage 2>/dev/null || true
