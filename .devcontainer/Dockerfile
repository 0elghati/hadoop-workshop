FROM ubuntu:22.04

# ── Environment variables ──────────────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive \
    HADOOP_VERSION=3.3.6 \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 \
    HADOOP_HOME=/opt/hadoop \
    HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
    HADOOP_LOG_DIR=/opt/hadoop/logs \
    HADOOP_DATA_DIR=/hadoop

ENV PATH="${JAVA_HOME}/bin:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${PATH}"

# ── System packages ────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-11-jdk \
    openssh-server \
    openssh-client \
    rsync \
    wget \
    curl \
    vim \
    nano \
    net-tools \
    iputils-ping \
    sudo \
    less \
    procps \
    && rm -rf /var/lib/apt/lists/*

# ── Create hadoop user ─────────────────────────────────────────────────────────
RUN useradd -m -s /bin/bash hadoop \
    && echo "hadoop:hadoop" | chpasswd \
    && echo "hadoop ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# ── SSH – passwordless localhost for Hadoop daemons ───────────────────────────
USER hadoop
RUN mkdir -p ~/.ssh \
    && ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa \
    && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys \
    && chmod 700 ~/.ssh \
    && chmod 600 ~/.ssh/authorized_keys \
    && printf "Host localhost\n    StrictHostKeyChecking no\n    UserKnownHostsFile /dev/null\nHost 0.0.0.0\n    StrictHostKeyChecking no\n    UserKnownHostsFile /dev/null\n" > ~/.ssh/config \
    && chmod 600 ~/.ssh/config

# ── SSH server setup (root) ────────────────────────────────────────────────────
USER root
RUN mkdir -p /var/run/sshd \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# ── Download & install Hadoop ──────────────────────────────────────────────────
RUN wget -q \
    "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" \
    -O /tmp/hadoop.tar.gz \
    && tar -xzf /tmp/hadoop.tar.gz -C /opt/ \
    && mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
    && rm /tmp/hadoop.tar.gz \
    && chown -R hadoop:hadoop ${HADOOP_HOME}

# ── Copy Hadoop configuration ──────────────────────────────────────────────────
COPY --chown=hadoop:hadoop config/core-site.xml    ${HADOOP_CONF_DIR}/core-site.xml
COPY --chown=hadoop:hadoop config/hdfs-site.xml    ${HADOOP_CONF_DIR}/hdfs-site.xml
COPY --chown=hadoop:hadoop config/mapred-site.xml  ${HADOOP_CONF_DIR}/mapred-site.xml
COPY --chown=hadoop:hadoop config/yarn-site.xml    ${HADOOP_CONF_DIR}/yarn-site.xml
RUN sed -i 's/\r$//' ${HADOOP_CONF_DIR}/*.xml

# ── Configure hadoop-env.sh ────────────────────────────────────────────────────
RUN cat >> ${HADOOP_CONF_DIR}/hadoop-env.sh << 'EOF'

# Java & Hadoop paths
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export HADOOP_LOG_DIR=/opt/hadoop/logs

# Run daemons as the hadoop user (required in Hadoop 3.x)
export HDFS_NAMENODE_USER=hadoop
export HDFS_DATANODE_USER=hadoop
export HDFS_SECONDARYNAMENODE_USER=hadoop
export YARN_RESOURCEMANAGER_USER=hadoop
export YARN_NODEMANAGER_USER=hadoop
EOF
RUN sed -i 's/\r$//' ${HADOOP_CONF_DIR}/hadoop-env.sh

# ── Create HDFS data & log directories ────────────────────────────────────────
RUN mkdir -p \
    /hadoop/hdfs/namenode \
    /hadoop/hdfs/datanode \
    /hadoop/tmp \
    ${HADOOP_HOME}/logs \
    && chown -R hadoop:hadoop /hadoop ${HADOOP_HOME}/logs

# ── Copy management scripts ────────────────────────────────────────────────────
COPY --chown=hadoop:hadoop scripts/init-hadoop.sh  /usr/local/bin/init-hadoop.sh
COPY --chown=hadoop:hadoop scripts/start-hadoop.sh /usr/local/bin/start-hadoop.sh
RUN chmod +x /usr/local/bin/init-hadoop.sh /usr/local/bin/start-hadoop.sh
RUN sed -i 's/\r$//' /usr/local/bin/init-hadoop.sh /usr/local/bin/start-hadoop.sh

# ── Shell environment for the hadoop user ─────────────────────────────────────
USER hadoop
RUN cat >> ~/.bashrc << 'EOF'

# ── Hadoop Environment ─────────────────────────────────────────────
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$JAVA_HOME/bin:$PATH

# ── Handy aliases ──────────────────────────────────────────────────
alias hls='hdfs dfs -ls'
alias hcat='hdfs dfs -cat'
alias hmkdir='hdfs dfs -mkdir -p'
alias hput='hdfs dfs -put'
alias hget='hdfs dfs -get'
alias hdfs-status='hdfs dfsadmin -report'
alias yarn-status='yarn node -list'
alias jps-hadoop='jps | grep -E "NameNode|DataNode|ResourceManager|NodeManager|JobHistoryServer|SecondaryNameNode"'
alias start-hadoop='bash /usr/local/bin/start-hadoop.sh'
alias hadoop-logs='tail -f $HADOOP_HOME/logs/*.log 2>/dev/null || echo "No logs yet"'
EOF
RUN sed -i 's/\r$//' /home/hadoop/.bashrc

USER root

# ── Exposed ports ──────────────────────────────────────────────────────────────
# 9870  – HDFS NameNode Web UI
# 9864  – HDFS DataNode Web UI
# 8088  – YARN ResourceManager Web UI
# 8042  – YARN NodeManager Web UI
# 19888 – MapReduce Job History Server
# 9000  – HDFS RPC endpoint
EXPOSE 9870 9864 8088 8042 19888 9000

CMD ["/bin/bash"]
