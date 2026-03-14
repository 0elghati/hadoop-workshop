#!/bin/bash
# init-hadoop.sh
# Runs ONCE after the container is first created (postCreateCommand).
# Formats the HDFS NameNode and prepares the basic directory layout.

set -e

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Hadoop – One-time Initialisation           ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── Start SSH so the format step can connect locally ──────────────────────────
echo "[1/3] Starting SSH daemon..."
sudo service ssh start

# ── Format HDFS NameNode (only if not already done) ───────────────────────────
echo "[2/3] Checking HDFS NameNode..."
if [ ! -d /hadoop/hdfs/namenode/current ]; then
    echo "      Formatting NameNode for the first time..."
    hdfs namenode -format -force -nonInteractive
    echo "      ✓ NameNode formatted."
else
    echo "      NameNode already formatted — skipping."
fi

# ── Bootstrap HDFS directory layout for students ─────────────────────────────
echo "[3/3] Bootstrapping HDFS structure..."
# Start HDFS temporarily to create directories
start-dfs.sh > /dev/null 2>&1
sleep 4

hdfs dfs -mkdir -p /user/hadoop /tmp /data
hdfs dfs -chmod 1777 /tmp
hdfs dfs -chmod 755 /data /user/hadoop

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Initialisation complete ✓                  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
