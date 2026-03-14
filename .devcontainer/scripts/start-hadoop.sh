#!/bin/bash
# start-hadoop.sh
# Runs on EVERY container start (postStartCommand).
# Starts (or restarts) all Hadoop daemons.

set -e

# ── Helper: check if a Java process is running ────────────────────────────────
is_running() {
    jps 2>/dev/null | grep -q "$1"
}

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Hadoop – Starting Services                 ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 1. SSH daemon (required for Hadoop start scripts) ─────────────────────────
echo "[1/4] SSH daemon..."
sudo service ssh start
echo "      ✓ SSH running."

# ── 2. Format check (safety net for first run) ────────────────────────────────
if [ ! -d /hadoop/hdfs/namenode/current ]; then
    echo "      NameNode not formatted — running format now..."
    hdfs namenode -format -force -nonInteractive
fi

# ── 3. HDFS ──────────────────────────────────────────────────────────────────
echo "[2/4] HDFS (NameNode + DataNode)..."
if is_running "NameNode" && is_running "DataNode"; then
    echo "      Already running — skipping."
else
    start-dfs.sh
fi
echo "      ✓ HDFS ready."

# ── 4. YARN ───────────────────────────────────────────────────────────────────
echo "[3/4] YARN (ResourceManager + NodeManager)..."
if is_running "ResourceManager" && is_running "NodeManager"; then
    echo "      Already running — skipping."
else
    start-yarn.sh
fi
echo "      ✓ YARN ready."

# ── 5. MapReduce Job History Server ───────────────────────────────────────────
echo "[4/4] MapReduce History Server..."
if is_running "JobHistoryServer"; then
    echo "      Already running — skipping."
else
    mapred --daemon start historyserver
fi
echo "      ✓ History Server ready."

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  All services started – Web UIs                              ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  HDFS NameNode        →  http://localhost:9870               ║"
echo "║  HDFS DataNode        →  http://localhost:9864               ║"
echo "║  YARN ResourceManager →  http://localhost:8088               ║"
echo "║  YARN NodeManager     →  http://localhost:8042               ║"
echo "║  MapReduce History    →  http://localhost:19888              ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Quick checks                                                ║"
echo "║    jps-hadoop           list running daemons                 ║"
echo "║    hdfs dfs -ls /       browse HDFS root                     ║"
echo "║    hdfs dfsadmin -report  HDFS storage report                ║"
echo "║    yarn node -list      list YARN nodes                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
