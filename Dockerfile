FROM centos:6
volume opt-vol:/opt

ENV SPARK_VERSION 2.4.0
ENV HADOOP_VERSION 2.7.4
ENV HADOOP_PACKAGE hadoop-$HADOOP_VERSION

ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-hadoop2.7

run yum install -y openssh-server wget \
    && cat /etc/redhat-release \
    && service sshd start \
    && chkconfig sshd on \
    && echo 'root:$1$NFUWV7nM$L2G0.R82dulmo1m7Szobn/' | chpasswd -e \
    && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config 
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
#    && systemctl enable sshd \
#    && systemctl start  sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile 

#install Java,Pdsh 

run yum install -y java-1.8.0-openjdk-devel \
    && java -version \ 
    && rpm -qa | grep jdk \ 
    && wget https://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm \ 
    && rpm -Uvh epel-release*rpm \
    && yum install -y pdsh 


#install Hadoop,Spark

RUN mkdir -p /opt/yarn \ 
    && wget -O hadoop.tar.gz https://archive.apache.org/dist/hadoop/core/hadoop-2.7.4/hadoop-2.7.4.tar.gz \ 
    && tar -xzf hadoop.tar.gz -C /opt/yarn  && rm hadoop.tar.gz \
    && ln -s /opt/yarn/$HADOOP_PACKAGE /opt/hadoop


RUN groupadd hadoop \
    && useradd -g hadoop yarn \ 
    && useradd -g hadoop hdfs \
    && useradd -g hadoop mapred \
    && mkdir -p /var/data/hadoop/hdfs/nn \
    && mkdir -p /var/data/hadoop/hdfs/snn \
    && mkdir /var/data/hadoop/hdfs/dn \
    && chown hdfs:hadoop /var/data/hadoop/hdfs \
    && mkdir -p /var/log/hadoop/logs \
    && chmod 755 /var/log/hadoop/logs \
    && chown yarn:hadoop /var/log/hadoop/logs -R 

RUN yum install -y wget \ 
    && yum install -y java openssh-server vim \
    && wget -O spark.tar.gz http://apache.volia.net/spark/spark-2.4.0/spark-2.4.0-bin-hadoop2.7.tgz

RUN mkdir -p /opt/ \
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
WORKDIR /opt/spark

#SETTING ENVIRONMENT VARIABLES
RUN echo "export SPARK_HOME=/opt/spark" >> /etc/profile \
    && echo "export  HADOOP_HOME=/opt/hadoop" >> /etc/profile \
    && echo "export  JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk.x86_64 " >> /etc/profile

ADD core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
ADD hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
ADD mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
ADD yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml
ADD slaves $HADOOP_HOME/etc/hadoop/slaves

EXPOSE 10022:22
CMD ["/usr/sbin/sshd", "-D"]




