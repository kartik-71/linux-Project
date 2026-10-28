#!/usr/bin/env bash
#
# audit_accounts.sh - Audit accounts against the provided list
# Usage: sudo ./audit_accounts.sh approved_users.txt
#

set -euo pipefail

# --- Root Check ---
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root (or with sudo) to inspect shadow password states." >&2
    exit 1
fi

# --- Input Validation ---
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <path_to_approved_users_file>" >&2
    exit 1
fi

APPROVED_FILE="$1"

if [[ ! -f "$APPROVED_FILE" ]]; then
    echo "Error: Input file '$APPROVED_FILE' not found." >&2
    exit 1
fi

# --- File Paths & Variables ---
DATE_STR="$(date +%F)"
DETAILED_REPORT="account_audit_report_${DATE_STR}.txt"
SUMMARY_REPORT="account_audit_summary_${DATE_STR}.txt"

declare -A approved_set
declare -A server_set

total_approved_input=0
total_approved_present=0
total_missing_from_server=0
total_unapproved_on_server=0

# --- Helper Functions ---

get_account_status() {
    local user="$1"
    local status="Active"

    # Check lock status via passwd -S
    if passwd_status=$(passwd -S "$user" 2>/dev/null); then
        local code
        code=$(awk '{print $2}' <<< "$passwd_status")
        if [[ "$code" == "L" ]]; then
            status="Locked"
        fi
    fi

    # Check expiration via chage
    if chage_info=$(chage -l "$user" 2>/dev/null); then
        local exp_date
        exp_date=$(grep "^Password expires" <<< "$chage_info" | cut -d: -f2 | xargs)
        if [[ "$exp_date" != "never" && -n "$exp_date" ]]; then
            local exp_epoch now_epoch
            exp_epoch=$(date -d "$exp_date" +%s 2>/dev/null || echo 0)
            now_epoch=$(date +%s)
            if [[ $exp_epoch -gt 0 && $exp_epoch -lt $now_epoch ]]; then
                [[ "$status" == "Locked" ]] && status="Locked/Expired" || status="Expired"
            fi
        fi
    fi

    echo "$status"
}

is_wheel_member() {
    local user="$1"
    if id -nG "$user" 2>/dev/null | grep -qw "wheel"; then
        echo "Yes (wheel)"
    else
        echo "No"
    fi
}

get_primary_group() {
    local user="$1"
    id -gn "$user" 2>/dev/null || echo "N/A"
}

# --- Step 1: Read Input List ---
while IFS= read -r line || [[ -n "$line" ]]; do
    clean_user="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [[ -z "$clean_user" || "$clean_user" =~ ^# ]] && continue

    approved_set["$clean_user"]=1
    ((total_approved_input++))
done < "$APPROVED_FILE"

# --- Step 2: Read All Server Accounts from /etc/passwd ---
while IFS=: read -r username _; do
    server_set["$username"]=1
done < /etc/passwd

# --- Step 3: Generate Detailed Report ---
{
    printf "%-22s | %-16s | %-16s | %-14s | %-24s\n" \
        "USERNAME" "STATUS" "PRIMARY GROUP" "WHEEL ADMIN" "AUDIT FINDING"
    printf -- "-----------------------+------------------+------------------+----------------+-------------------------\n"

    # 1. Process Approved Accounts
    for user in $(printf '%s\n' "${!approved_set[@]}" | sort); do
        if id "$user" &>/dev/null; then
            ((total_approved_present++))
            status=$(get_account_status "$user")
            group=$(get_primary_group "$user")
            wheel=$(is_wheel_member "$user")
            finding="Approved"

            if [[ "$status" =~ (Locked|Expired) ]]; then
                finding="Approved (${status})"
            fi

            printf "%-22s | %-16s | %-16s | %-14s | %-24s\n" \
                "$user" "$status" "$group" "$wheel" "$finding"
        else
            ((total_missing_from_server++))
            printf "%-22s | %-16s | %-16s | %-14s | %-24s\n" \
                "$user" "Missing" "N/A" "N/A" "Missing From Server"
        fi
    done

    # 2. Process Unapproved Server Accounts
    for user in $(printf '%s\n' "${!server_set[@]}" | sort); do
        if [[ -z "${approved_set[$user]:-}" ]]; then
            ((total_unapproved_on_server++))
            status=$(get_account_status "$user")
            group=$(get_primary_group "$user")
            wheel=$(is_wheel_member "$user")
            finding="UNAPPROVED ACCOUNT"

            printf "%-22s | %-16s | %-16s | %-14s | %-24s\n" \
                "$user" "$status" "$group" "$wheel" "$finding"
        fi
    done
} > "$DETAILED_REPORT"

# --- Step 4: Generate Summary Report ---
{
    echo "=========================================================="
    echo "             USER ACCOUNT AUDIT SUMMARY                   "
    echo "=========================================================="
    echo "Audit Date                      : ${DATE_STR}"
    echo "Approved User Source File       : ${APPROVED_FILE}"
    echo "----------------------------------------------------------"
    echo "Total Approved Users in List    : ${total_approved_input}"
    echo "  - Present on Server           : ${total_approved_present}"
    echo "  - Missing from Server         : ${total_missing_from_server}"
    echo "Total Unapproved Server Accounts: ${total_unapproved_on_server}"
    echo "=========================================================="
} > "$SUMMARY_REPORT"

# Display Summary on Screen
cat "$SUMMARY_REPORT"
echo ""
echo "Full audit report:   ${DETAILED_REPORT}"
echo "Summary file:        ${SUMMARY_REPORT}"
