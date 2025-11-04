#!/bin/bash
# Benchmark stable test performance across multiple runs

set -euo pipefail

echo "🏃 Benchmarking stable test performance..."
echo "Platform: $(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"')"
echo "Date: $(date)"
echo ""

# Warm up
echo "🔥 Warming up Nix store..."
make test > /dev/null 2>&1 || true

# Benchmark runs
runs=5
total_time=0

for i in $(seq 1 $runs); do
    echo "🧪 Run $i/$runs..."
    start_time=$(date +%s)
    make test
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    total_time=$((total_time + duration))
    echo "⏱️  Run $i completed in ${duration}s"
    echo ""
done

avg_time=$((total_time / runs))
echo "📊 Results:"
echo "Total runs: $runs"
echo "Total time: ${total_time}s"
echo "Average time: ${avg_time}s"

if [ $avg_time -le 30 ]; then
    echo "✅ Performance target met (<30s)"
    exit 0
else
    echo "❌ Performance target missed (>30s)"
    exit 1
fi
