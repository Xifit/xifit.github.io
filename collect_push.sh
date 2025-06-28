#!/bin/bash

export LC_ALL=C

HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# === CPU (% estimée à partir de loadavg)
CPU_LOAD=$(awk '{print $1}' /proc/loadavg)
CPU_CORES=$(nproc)
CPU_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($CPU_LOAD / $CPU_CORES) * 100}")

# === RAM via free -m (ligne Mem: + colonne "available")
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_AVAILABLE=$(free -m | awk '/Mem:/ {print $7}')
MEM_USED=$((MEM_TOTAL - MEM_AVAILABLE))

RAM_TOTAL_GB=$(awk "BEGIN {printf \"%.2f\", $MEM_TOTAL / 1024}")
RAM_USED_GB=$(awk "BEGIN {printf \"%.2f\", $MEM_USED / 1024}")
RAM_FREE_GB=$(awk "BEGIN {printf \"%.2f\", $MEM_AVAILABLE / 1024}")
RAM_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($MEM_USED / $MEM_TOTAL) * 100}")

# === Disques
DISKS=$(df -BM --output=source,used,avail,size,target -x tmpfs -x devtmpfs | tail -n +2 | awk '{
    gsub("M", "", $2); gsub("M", "", $3); gsub("M", "", $4);
    used=$2; free=$3; total=$4;
    percent_free=(total > 0) ? (free / total * 100) : 0;
    printf "{\"name\":\"%s\",\"used_gb\":%.2f,\"free_gb\":%.2f,\"total_gb\":%.2f,\"percent_free\":%.2f},",
        $1, used/1024, free/1024, total/1024, percent_free;
}' | sed 's/,$//')

# === JSON complet
JSON=$(cat <<EOF
{
  "hostname": "$HOSTNAME",
  "timestamp": "$TIMESTAMP",
  "cpu_percent": $CPU_PERCENT,
  "ram_total_gb": $RAM_TOTAL_GB,
  "ram_used_gb": $RAM_USED_GB,
  "ram_free_gb": $RAM_FREE_GB,
  "ram_percent": $RAM_PERCENT,
  "disks": [$DISKS]
}
EOF
)

# === Envoi HTTP
curl -s -X POST -H "Content-Type: application/json" \
     -H "x-api-key: cle-api-secrete" \
     -d "$JSON" http://192.168.100.40/api/store_stats.php
