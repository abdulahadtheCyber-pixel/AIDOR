#!/bin/bash

# AIDOR Pro - Advanced IDOR Vulnerability Scanner
# For Authorized Penetration Testing & Educational Use Only

# Colors
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m'
BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' NC='\033[0m'

# Professional Banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "      ▄████████  ▄█  ████████▄   ▄██████▄     ▄████████ "
    echo "     ███    ███ ███  ███    ███ ███    ███   ███    ███ "
    echo "     ███    ███ ███▌ ███    ███ ███    ███   ███    ███ "
    echo "     ███    ███ ███▌ ███    ███ ███    ███  ▄███▄▄▄▄██▀ "
    echo "   ▀███████████ ███▌ ███    ███ ███    ███ ▀▀███▀▀▀▀▀   "
    echo "     ███    ███ ███  ███    ███ ███    ███ ▀███████████ "
    echo "     ███    ███ ███  ███    ███ ███    ███   ███    ███ "
    echo "     ███    █▀  █▀   ████████▀   ▀██████▀    ███    ███ "
    echo -e "${RED}             [ Advanced IDOR Scanning Suite ]${NC}"
    echo -e "${YELLOW}       Authorized Pentest Context - Use Responsibly${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
}

check_deps() {
    for cmd in curl grep sed find; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}[!] Error: $cmd is not installed.${NC}"
            exit 1
        fi
    done
}

# Advanced testing logic
test_endpoint() {
    local target="$1"
    local endpoint="$2"
    local param="$3"
    
    # IDs to test: Small, Large, Negative, Sequential
    local payloads=("0" "1" "2" "-1" "999" "1000" "0001" "admin" "null" "undefined")
    
    echo -e "${BLUE}[*] Testing: ${NC}${endpoint}?${param}=VAL"
    
    for val in "${payloads[@]}"; do
        url="${target}${endpoint}?${param}=${val}"
        
        # Capture response code and content length
        res=$(curl -s -o /tmp/aidor_res -w "%{http_code}:%{size_download}" "$url")
        code=$(echo $res | cut -d':' -f1)
        size=$(echo $res | cut -d':' -f2)
        
        # Analyze Response
        # Vulnerability Indicators: 200 OK with sensitive keys in body, or size spikes
        if [[ "$code" == "200" ]]; then
            if grep -qiE "(user|email|password|token|api|key|account|address)" /tmp/aidor_res; then
                echo -e "  ${RED}[🚨 VULNERABLE]${NC} ID:$val | URL:$url | Size:$size"
                echo "    Found sensitive patterns in response body."
            else
                echo -e "  ${YELLOW}[?] Accessible${NC} ID:$val (No sensitive keys found)"
            fi
        fi
    done
}

# Main Scanner Logic
run_advanced_scan() {
    local base_url="$1"
    # Ensure URL ends correctly
    [[ "$base_url" != */ ]] && base_url="$base_url/"

    echo -e "${GREEN}[+] Target Set:${NC} $base_url"
    
    # Advanced Endpoint Map
    local endpoints=(
        "api/v1/user" "api/v2/customer" "api/accounts" "profiles"
        "dashboard/settings" "get_user" "view_invoice" "download"
        "orders" "api/messages" "api/v1/billing" "user/edit"
    )
    
    # Advanced Parameter Map
    local params=("id" "uid" "uuid" "user_id" "account" "order_id" "doc_id" "key")

    echo -e "${PURPLE}[*] Fuzzing for IDOR vulnerabilities...${NC}"
    
    for ep in "${endpoints[@]}"; do
        # Check if endpoint exists before heavy fuzzing
        status=$(curl -s -L -o /dev/null -w "%{http_code}" "${base_url}${ep}")
        if [[ "$status" != "404" ]]; then
            echo -e "${GREEN}[+] Endpoint Found:${NC} /$ep ($status)"
            for p in "${params[@]}"; do
                test_endpoint "$base_url" "$ep" "$p"
            done
        fi
    done
}

# Execution
show_banner
check_deps

read -p "🎯 Enter Domain or URL to Scan: " target
if [[ -z "$target" ]]; then
    echo -e "${RED}[!] Target required.${NC}"
    exit 1
fi

# Basic URL sanitization
[[ "$target" != http* ]] && target="https://$target"

run_advanced_scan "$target"

echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}[COMPLETE]${NC} Scan finished. Verify manual triggers using Burp Suite."
