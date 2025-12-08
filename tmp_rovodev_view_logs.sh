#!/bin/bash

echo "==================================================================="
echo "📊 Favicon Provider Logs - Live View"
echo "==================================================================="
echo ""
echo "🔍 Watching logs for subsystem: ManagedFavsGenerator"
echo "📂 Category: Favicons"
echo ""
echo "Press Ctrl+C to stop"
echo "-------------------------------------------------------------------"
echo ""

# Live stream of logs
log stream --predicate 'subsystem == "ManagedFavsGenerator" AND category == "Favicons"' --level info --style compact
