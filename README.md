# Big Data – Practical Sessions
## Hadoop Single-Node Environment

This repository holds the **Dev Container** configuration for the Big Data practical sessions.
Open the folder in VS Code and let the container build — Hadoop starts automatically.

---

## Requirements

| Tool | Version |
|------|---------|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | ≥ 4.x |
| [VS Code](https://code.visualstudio.com/) | latest |
| VS Code extension: **Dev Containers** | latest |

> **Recommended resources** — give Docker at least **4 GB RAM** and **2 CPUs** in Docker Desktop settings.

---

## Getting Started

1. Clone / open this folder in VS Code.
2. When prompted **"Reopen in Container"**, click it (or open the Command Palette → *Dev Containers: Reopen in Container*).
3. The first build takes a few minutes (downloads ~600 MB).
4. When the terminal is ready you will see the Hadoop service summary with all Web UI links.

---

## Web UIs (auto-forwarded by VS Code)

| Service | URL |
|---------|-----|
| HDFS NameNode | <http://localhost:9870> |
| HDFS DataNode | <http://localhost:9864> |
| YARN ResourceManager | <http://localhost:8088> |
| YARN NodeManager | <http://localhost:8042> |
| MapReduce History | <http://localhost:19888> |

---

## Useful Commands

### Check running daemons
```bash
jps-hadoop
# Expected: NameNode, DataNode, ResourceManager, NodeManager, JobHistoryServer
```

### HDFS basics
```bash
# List HDFS root
hdfs dfs -ls /

# Create a directory
hdfs dfs -mkdir -p /user/hadoop/input

# Upload a local file
hdfs dfs -put /etc/hosts /user/hadoop/input/

# Read a file
hdfs dfs -cat /user/hadoop/input/hosts

# Download a file
hdfs dfs -get /user/hadoop/input/hosts ~/hosts_from_hdfs

# Delete a file
hdfs dfs -rm /user/hadoop/input/hosts

# HDFS storage report
hdfs dfsadmin -report
```

### Run the built-in WordCount example
```bash
# 1. Prepare input
hdfs dfs -mkdir -p /user/hadoop/wordcount/input
echo "hello world hadoop hello" | hdfs dfs -put - /user/hadoop/wordcount/input/sample.txt

# 2. Run MapReduce job
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \
    wordcount /user/hadoop/wordcount/input /user/hadoop/wordcount/output

# 3. Read results
hdfs dfs -cat /user/hadoop/wordcount/output/part-r-00000
```

### YARN
```bash
# List nodes
yarn node -list

# List running applications
yarn application -list

# Kill an application
yarn application -kill <applicationId>
```

### Aliases available in every terminal
| Alias | Equivalent |
|-------|-----------|
| `hls` | `hdfs dfs -ls` |
| `hcat` | `hdfs dfs -cat` |
| `hmkdir` | `hdfs dfs -mkdir -p` |
| `hput` | `hdfs dfs -put` |
| `hget` | `hdfs dfs -get` |
| `hdfs-status` | `hdfs dfsadmin -report` |
| `yarn-status` | `yarn node -list` |
| `jps-hadoop` | lists only Hadoop JVM processes |
| `start-hadoop` | (re)starts all services |
| `hadoop-logs` | tail all Hadoop log files |

---

## Environment Variables (pre-set)

```bash
JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
HADOOP_HOME=/opt/hadoop
HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
```

---

## Cluster Configuration (Pseudo-distributed)

| Parameter | Value |
|-----------|-------|
| Mode | Pseudo-distributed (single node) |
| HDFS replication | 1 |
| NameNode RPC | `hdfs://localhost:9000` |
| YARN memory | 2 048 MB total |
| Java | OpenJDK 11 |
| Hadoop | 3.3.6 |

---

## Troubleshooting

**Services did not start?**
```bash
start-hadoop   # re-runs the startup script
```

**NameNode is in Safe Mode?**
```bash
hdfs dfsadmin -safemode leave
```

**Out of disk space on HDFS?**
```bash
hdfs dfs -du -h /   # check usage
```

**Check logs:**
```bash
hadoop-logs
# or directly:
ls $HADOOP_HOME/logs/
```
