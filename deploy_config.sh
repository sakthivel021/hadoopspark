for node in `cat /opt/hadoop/etc/hadoop/slaves`
do
  ssh-keyscan -H $node  >> ~/.ssh/known_hosts
done
