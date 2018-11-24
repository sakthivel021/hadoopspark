FROM centos:6
volume opt-vol:/opt

ENV SPARK_VERSION 2.4.0
ENV HADOOP_VERSION 2.7.4
ENV HADOOP_PACKAGE hadoop-$HADOOP_VERSION

ENV NOTVISIBLE "in users profile"
ENV HADOOP_HOME=/opt/hadoop/
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-hadoop2.7
run yum install -y openssh-server wget java openssh-clients vim \
    && cat /etc/redhat-release \
    && service sshd start \
    && chkconfig sshd on \
    && echo 'root:$1$NFUWV7nM$L2G0.R82dulmo1m7Szobn/' | chpasswd -e \
    && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
# SSH login fix. Otherwise user is kicked off after login
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
#    && systemctl enable sshd \
#    && systemctl start  sshd

    && echo "export VISIBLE=now" >> /etc/profile \
#install Java,Pdsh 
    && yum install -y java-1.8.0-openjdk-devel \
    && java -version \ 
    && rpm -qa | grep jdk  \
 #   && wget https://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm \ 
  #  && rpm -Uvh epel-release*rpm \
  #  && yum install -y pdsh 
#install Hadoop,Spark
    && mkdir -p /opt/yarn \ 
    && wget -O hadoop.tar.gz https://archive.apache.org/dist/hadoop/core/hadoop-2.7.4/hadoop-2.7.4.tar.gz \ 
    && tar -xzf hadoop.tar.gz -C /opt/yarn  && rm hadoop.tar.gz \
    && ln -s /opt/yarn/$HADOOP_PACKAGE /opt/hadoop \
    && groupadd hadoop \
    && useradd -g hadoop yarn \ 
    && useradd -g hadoop hdfs \
    && useradd -g hadoop mapred \
    && mkdir -p /var/data/hadoop/hdfs/nn \
    && mkdir -p /var/data/hadoop/hdfs/snn \
    && mkdir /var/data/hadoop/hdfs/dn \
    && mkdir $HADOOP_HOME/logs \
    && chown -R hdfs:hadoop /opt/hadoop \
    && chown -R hdfs:hadoop /opt/yarn \
    && chown -R hdfs:hadoop /var/data/ \
    && chmod 777 /tmp \
    && mkdir -p /var/log/hadoop/logs \
    && chmod 755 /var/log/hadoop/logs \
    && chown yarn:hadoop /var/log/hadoop/logs -R \
    && echo 'hdfs:$1$HMPEwAI3$.ToAzPVH2ijXi8weK8aJM0' | chpasswd -e \
    && echo 'yarn:$1$P9N9Q59u$ikIL28z4.y0fmP8D5qiCM1' | chpasswd -e \
    && echo 'mapred:$1$lEviz/bJ$fASeVRD7tcsFeVLyF0HN21' | chpasswd -e 

# configure passwordless SSH
#RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key \
 #   && ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key \
USER hdfs
RUN  ssh-keygen -q -N "" -t rsa -f /home/hdfs/.ssh/id_rsa \
    && cp /home/hdfs/.ssh/id_rsa.pub /home/hdfs/.ssh/authorized_keys
USER root
RUN yum install -y wget \ 
    && wget -O spark.tar.gz http://apache.volia.net/spark/spark-2.4.0/spark-2.4.0-bin-hadoop2.7.tgz \ 
    && mkdir -p /opt/ \
    && tar xvf spark.tar.gz -C /opt/ \
        && ln -s /opt/$SPARK_PACKAGE /opt/spark \
            &&mkdir /var/log/spark \
                && mkdir /tmp/spark \
                    && mkdir /etc/spark/ \
                        && mv /opt/spark/conf/* /etc/spark/ \
                        && ln -s /etc/spark /opt/spark/conf 
EXPOSE 4040 
EXPOSE 7077 
EXPOSE 8088
#WORKDIR /opt/spark

#SETTING ENVIRONMENT VARIABLES 

RUN  ln -s $HADOOP_HOME/etc/hadoop $HADOOP_HOME/conf \
    && echo "export SPARK_HOME=/opt/spark" >> /etc/profile \
    && echo "export  HADOOP_HOME=/opt/hadoop" >> /etc/profile \
    && echo "export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin" >> /etc/profile \
    && echo "export  JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk.x86_64 " >> /etc/profile \
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
#ADD hadoop-env.sh $HADOOP_HOME/etc/hadoop/hadoop-env.sh 

# update JAVA_HOME and HADOOP_CONF_DIR in hadoop-env.sh
#RUN sed -i "/^export JAVA_HOME/ s:.*:export JAVA_HOME=${JAVA_HOME}\nexport HADOOP_HOME=${HADOOP_HOME}\nexport HADOOP_PREFIX=${HADOOP_PREFIX}:"  /opt/hadoop/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop/:' /opt/hadoop/etc/hadoop/hadoop-env.sh

EXPOSE 10022:22
#ENTRYPOINT  [ sh /home/hdfs/deploy_config.sh]
USER root
CMD ["/usr/sbin/sshd", "-D"]




