su - hdfs -c 'ssh-keyscan -H `cat /opt/hadoop/etc/hadoop/masters ` '

for node in `cat /opt/hadoop/etc/hadoop/slaves`
do
  su -hdfs -c 'ssh-keyscan -H $node  >> ~/.ssh/known_hosts'
done
