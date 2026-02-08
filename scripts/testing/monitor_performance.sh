#!/bin/bash
# monitor_performance.sh - Performance monitoring script for MultiGame
# Usage: ./monitor_performance.sh [duration_in_seconds]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Package name (update after changing from com.example.multigame)
PACKAGE_NAME="com.example.multigame"

# Duration (default: 60 seconds)
DURATION=${1:-60}

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}  MultiGame Performance Monitor${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Check if device connected
if ! adb devices | grep -q "device$"; then
    echo -e "${RED}❌ No device connected!${NC}"
    exit 1
fi

# Check if app is running
if ! adb shell pidof $PACKAGE_NAME > /dev/null 2>&1; then
    echo -e "${RED}❌ App is not running!${NC}"
    echo -e "${YELLOW}Please launch the app first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ App is running${NC}"
echo -e "${BLUE}Monitoring for ${DURATION} seconds...${NC}"
echo ""

# Device info
echo -e "${BLUE}═══ DEVICE INFORMATION ═══${NC}"
DEVICE_MODEL=$(adb shell getprop ro.product.model)
ANDROID_VERSION=$(adb shell getprop ro.build.version.release)
API_LEVEL=$(adb shell getprop ro.build.version.sdk)
TOTAL_RAM=$(adb shell cat /proc/meminfo | grep MemTotal | awk '{print $2}')
TOTAL_RAM_MB=$((TOTAL_RAM / 1024))

echo "Device: $DEVICE_MODEL"
echo "Android: $ANDROID_VERSION (API $API_LEVEL)"
echo "Total RAM: ${TOTAL_RAM_MB}MB"
echo ""

# Initial memory snapshot
echo -e "${BLUE}═══ INITIAL MEMORY USAGE ═══${NC}"
adb shell dumpsys meminfo $PACKAGE_NAME | grep -E "TOTAL|Java Heap|Native Heap|Graphics|Private Dirty"
echo ""

# Monitor performance over time
echo -e "${BLUE}═══ PERFORMANCE MONITORING ═══${NC}"
echo "Timestamp | CPU % | Memory (MB) | Status"
echo "----------------------------------------------"

START_TIME=$(date +%s)
MAX_MEM=0
MIN_MEM=999999
TOTAL_MEM=0
SAMPLE_COUNT=0

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    if [ $ELAPSED -ge $DURATION ]; then
        break
    fi

    # CPU usage
    CPU=$(adb shell top -n 1 | grep $PACKAGE_NAME | awk '{print $9}' | head -1)
    if [ -z "$CPU" ]; then
        CPU="0"
    fi

    # Memory usage
    MEM_KB=$(adb shell dumpsys meminfo $PACKAGE_NAME | grep "TOTAL PSS" | awk '{print $3}' | tr -d ',')
    if [ -z "$MEM_KB" ]; then
        MEM_KB=0
    fi
    MEM_MB=$((MEM_KB / 1024))

    # Track min/max/avg
    if [ $MEM_MB -gt $MAX_MEM ]; then
        MAX_MEM=$MEM_MB
    fi
    if [ $MEM_MB -lt $MIN_MEM ] && [ $MEM_MB -gt 0 ]; then
        MIN_MEM=$MEM_MB
    fi
    TOTAL_MEM=$((TOTAL_MEM + MEM_MB))
    SAMPLE_COUNT=$((SAMPLE_COUNT + 1))

    # Status
    if [ $MEM_MB -gt 300 ]; then
        STATUS="${RED}HIGH${NC}"
    elif [ $MEM_MB -gt 200 ]; then
        STATUS="${YELLOW}MEDIUM${NC}"
    else
        STATUS="${GREEN}OK${NC}"
    fi

    # Print current metrics
    TIMESTAMP=$(date +%H:%M:%S)
    echo -e "$TIMESTAMP | ${CPU}% | ${MEM_MB}MB | $STATUS"

    sleep 5
done

echo ""

# Calculate average
if [ $SAMPLE_COUNT -gt 0 ]; then
    AVG_MEM=$((TOTAL_MEM / SAMPLE_COUNT))
else
    AVG_MEM=0
fi

# Final memory snapshot
echo -e "${BLUE}═══ FINAL MEMORY USAGE ═══${NC}"
adb shell dumpsys meminfo $PACKAGE_NAME | grep -E "TOTAL|Java Heap|Native Heap|Graphics|Private Dirty"
echo ""

# Summary
echo -e "${BLUE}═══ PERFORMANCE SUMMARY ═══${NC}"
echo "Duration: ${DURATION}s"
echo "Samples: $SAMPLE_COUNT"
echo ""
echo "Memory Usage:"
echo "  Average: ${AVG_MEM}MB"
echo "  Minimum: ${MIN_MEM}MB"
echo "  Maximum: ${MAX_MEM}MB"
echo ""

# Memory assessment
if [ $MAX_MEM -gt 300 ]; then
    echo -e "${RED}⚠️  HIGH MEMORY USAGE DETECTED!${NC}"
    echo "   Consider optimizing memory allocation"
elif [ $MAX_MEM -gt 200 ]; then
    echo -e "${YELLOW}⚠️  MODERATE MEMORY USAGE${NC}"
    echo "   Memory usage is acceptable but could be optimized"
else
    echo -e "${GREEN}✅ MEMORY USAGE OK${NC}"
    echo "   Memory usage is within acceptable limits"
fi
echo ""

# FPS check (if available)
echo -e "${BLUE}═══ FRAME STATS (Last 120 frames) ═══${NC}"
adb shell dumpsys gfxinfo $PACKAGE_NAME | grep -A 5 "Total frames"
echo ""

# Battery impact
echo -e "${BLUE}═══ BATTERY IMPACT ═══${NC}"
adb shell dumpsys batterystats | grep $PACKAGE_NAME | head -5
echo ""

# Check for memory leaks
MEM_INCREASE=$((MAX_MEM - MIN_MEM))
if [ $MEM_INCREASE -gt 100 ]; then
    echo -e "${RED}⚠️  POTENTIAL MEMORY LEAK DETECTED!${NC}"
    echo "   Memory increased by ${MEM_INCREASE}MB during monitoring"
    echo "   This could indicate a memory leak"
else
    echo -e "${GREEN}✅ NO SIGNIFICANT MEMORY LEAKS${NC}"
fi

echo ""
echo -e "${GREEN}Monitoring complete!${NC}"
echo ""
echo "Recommendations:"
echo "  • Keep average memory below 200MB for optimal performance"
echo "  • Monitor for memory leaks during extended gameplay (10+ minutes)"
echo "  • Test on low-end devices (2GB RAM) to ensure compatibility"
echo ""
