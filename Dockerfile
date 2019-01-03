FROM local/c7-systemd
ENV SPARK_VERSION 2.4.0
ENV HADOOP_VERSION 2.7.4
ENV HADOOP_PACKAGE hadoop-$HADOOP_VERSION
ENV HADOOP_HOME /opt/hadoop
ENV SPARK_HOME /opt/spark
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-hadoop2.7
ENV ZOOKEEPER_PACKAGE zookeeper-3.4.6
run yum install -y openssh-server wget java openssh-clients vim java-1.8.0-openjdk-devel; systemctl enable sshd;
#run systemctl restart sshd.service \
run echo 'root:$1$NFUWV7nM$L2G0.R82dulmo1m7Szobn/' | chpasswd -e \
    && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
# SSH login fix. Otherwise user is kicked off after login
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
     && ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key \
     && ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key \
     && ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key  \
     && ls -al /etc/ssh/ssh*key \
     && rm -f /var/run/nologin \
    && echo "export VISIBLE=now" >> /etc/profile 
#Create Users
run groupadd hadoop \
    && useradd -g hadoop yarn \
    && useradd -g hadoop hdfs \
    && useradd -g hadoop mapred \
    && mkdir -p /var/data/hadoop/hdfs/nn \
    && mkdir -p /var/data/hadoop/hdfs/snn \
    && mkdir /var/data/hadoop/hdfs/dn \
    && mkdir /var/data/hadoop/zookeeper \
    && mkdir -p /opt/$HADOOP_PACKAGE \
    && ln -s /opt/$HADOOP_PACKAGE /opt/hadoop \
    && mkdir -p $HADOOP_HOME/logs \
    && chmod 777 /tmp \
    && mkdir -p /var/log/hadoop/logs \
    && mkdir -p /var/log/spark/logs \
    && chmod 755 /var/log/hadoop/logs \
    && chown hdfs:hadoop /var/log/hadoop/logs -R \
    && chown hdfs:hadoop /var/log/spark/logs \
    && echo 'hdfs:$1$HMPEwAI3$.ToAzPVH2ijXi8weK8aJM0' | chpasswd -e \
    && echo 'yarn:$1$P9N9Q59u$ikIL28z4.y0fmP8D5qiCM1' | chpasswd -e \
    && echo 'mapred:$1$lEviz/bJ$fASeVRD7tcsFeVLyF0HN21' | chpasswd -e 

run chown -R hdfs:hadoop /opt/hadoop \
    && chown -R hdfs:hadoop /opt/ \
    && chown -R hdfs:hadoop /var/data/ \
    #&& chown -R hdfs:hadoop /opt/$SPARK_PACKAGE \
    #&& chown -R hdfs:hadoop /opt/spark \
    && chown -R hdfs:hadoop /var/log/spark 
    #&& chown -R hdfs:hadoop /opt/$HADOOP_PACKAGE

USER hdfs
RUN ssh-keygen -q -N "" -t rsa -f /home/hdfs/.ssh/id_rsa \
    && cp /home/hdfs/.ssh/id_rsa.pub /home/hdfs/.ssh/authorized_keys
#Install Hadoop Software 
run ls -lh /opt/ 
run wget -O /opt/hadoop.tar.gz https://archive.apache.org/dist/hadoop/common/hadoop-2.7.4/hadoop-2.7.4.tar.gz \ 
    && tar -xzf /opt/hadoop.tar.gz -C /opt/  && rm /opt/hadoop.tar.gz 
    #&& ln -s /opt/$HADOOP_PACKAGE /opt/hadoop 
#Install Spark
RUN wget -O /opt/spark.tar.gz http://apache.volia.net/spark/spark-2.4.0/spark-2.4.0-bin-hadoop2.7.tgz \ 
    ## && mkdir -p /opt/spark \
    && tar xzf /opt/spark.tar.gz -C /opt 
RUN ln -sf /opt/$SPARK_PACKAGE /opt/spark \
                    #&& mkdir /etc/spark/ \
                        #&& mv /opt/spark/conf/* /etc/spark/ \
                        && ln -s /etc/spark /opt/spark/conf 
# Install Zookeeper
RUN wget -O /opt/zookeeper.tar.gz https://archive.apache.org/dist/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz  \
    && tar -xvf /opt/zookeeper.tar.gz -C /opt/ \ 
    && rm /opt/zookeeper.tar.gz

RUN ln -sf /opt/$ZOOKEEPER_PACKAGE /opt/zookeeper \
    && cp /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg
run ls -lh /opt/ \
    && echo "$SPARK_PACKAGE" \
    && ls -lh /opt/spark \
                       && cp /opt/spark/conf/spark-defaults.conf.template /opt/spark/conf/spark-defaults.conf \
                        && echo "spark.master    yarn" >> /opt/spark/conf/spark-defaults.conf \ 
                        && echo "spark.driver.memory    512m" >> /opt/spark/conf/spark-defaults.conf \
                        && echo "spark.executor.memory          512m" >> /opt/spark/conf/spark-defaults.conf \
                        && echo "spark.eventLog.enabled  true" >> /opt/spark/conf/spark-defaults.conf \
                        && echo "spark.eventLog.dir /var/log/spark/" >> /opt/spark/conf/spark-defaults.conf \
                        && echo "spark.history.provider            org.apache.spark.deploy.history.FsHistoryProvider" >> /opt/spark/conf/spark-defaults.conf \
                        && echo "spark.history.fs.update.interval  10s" >> /opt/spark/conf/spark-defaults.conf \
                        && echo "spark.history.ui.port             18080" >> /opt/spark/conf/spark-defaults.conf 
			#&& mkdir -p /opt/conda \
			#&& export HOME=/opt/conda/ \
			#&& wget  https://repo.continuum.io/archive/Anaconda3-4.3.0-Linux-x86_64.sh \
			#&& cp Anaconda3-4.3.0-Linux-x86_64.sh /opt/conda/ \
			#&& bash /opt/conda/Anaconda3-4.3.0-Linux-x86_64.sh -b \
			#&& /opt/conda/anaconda3/bin/conda create -n pyspark_env python=3 \
			#&& echo "source activate pyspark_env" /home/hdfs/.bashrc 
		

EXPOSE 4040 
EXPOSE 7077 
EXPOSE 8088
EXPOSE 18080
#WORKDIR /opt/spark

#SETTING ENVIRONMENT VARIABLES 
user root
RUN  ln -s $HADOOP_HOME/etc/hadoop $HADOOP_HOME/conf \
    && echo "export SPARK_HOME=/opt/spark" >> /etc/profile \
    && echo "export  HADOOP_HOME=/opt/hadoop" >> /etc/profile \
    && echo "export PATH=$PATH:/opt/spark/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin" >> /etc/profile \
    && echo "export  JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk.x86_64 " >> /etc/profile \
    && echo "export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop" >> /etc/profile \
    && echo "export SPARK_HOME=/opt/spark" >> /etc/profile \
    && echo "export LD_LIBRARY_PATH=/opt/hadoop/lib/native:$LD_LIBRARY_PATH" >> /etc/profile \
    && echo "export HADOOP_HOME=/opt/hadoop/" >> /opt/hadoop/etc/hadoop/hadoop-env.sh \
    && echo "export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk.x86_64" >> /opt/hadoop/etc/hadoop/hadoop-env.sh \
    && echo "export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop" >> /opt/hadoop/etc/hadoop/hadoop-env.sh \
    && echo "export HADOOP_OPTS=-Djava.net.preferIPv4Stack=true" >> /opt/hadoop/etc/hadoop/hadoop-env.sh \
    && echo "hadoop-master" >> /opt/hadoop/etc/hadoop/masters 

ENV PATH $PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

ENV HADOOP_PREFIX $HADOOP_HOME
ENV HADOOP_COMMON_HOME $HADOOP_HOME
ENV HADOOP_HDFS_HOME $HADOOP_HOME
ENV HADOOP_MAPRED_HOME $HADOOP_HOME
ENV HADOOP_YARN_HOME $HADOOP_HOME
ENV HADOOP_CONF_DIR $HADOOP_HOME/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop

USER hdfs
COPY . /home/hdfs/

#RUN cp /home/hdfs/core-site.xml /opt/hadoop/etc/hadoop/core-site.xml 
#    && mv /home/hdfs/hdfs-site.xml /opt/hadoop/etc/hadoop/hdfs-site.xml \
#    && mv /home/hdfs/mapred-site.xml /opt/hadoop/etc/hadoop/mapred-site.xml \
#    && mv /home/hdfs/yarn-site.xml /opt/hadoop/etc/hadoop/yarn-site.xml \
#    && mv /home/hdfs/slaves /opt/hadoop/etc/hadoop/slaves

# add default config files which has one master and three slaves
ADD core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
ADD hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
ADD mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
ADD yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml
ADD slaves $HADOOP_HOME/etc/hadoop/slaves
ADD topology.sh $HADOO_HOME/etc/hadoop/topology.sh
#ADD hadoop-env.sh $HADOOP_HOME/etc/hadoop/hadoop-env.sh 

# update JAVA_HOME and HADOOP_CONF_DIR in hadoop-env.sh
#RUN sed -i "/^export JAVA_HOME/ s:.*:export JAVA_HOME=${JAVA_HOME}\nexport HADOOP_HOME=${HADOOP_HOME}\nexport HADOOP_PREFIX=${HADOOP_PREFIX}:"  /opt/hadoop/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop/:' /opt/hadoop/etc/hadoop/hadoop-env.sh 

EXPOSE 10022:22
#ENTRYPOINT  [ sh /home/hdfs/deploy_config.sh]
USER root
#CMD ["/usr/sbin/sshd", "-D"]
CMD ["/usr/sbin/init"]

