import sys

from pyspark import SparkContext, SparkConf

if __name__ == "__main__":
  # create Spark context with Spark configuration
  conf = SparkConf().setAppName("Word Count - Python")
  conf.setMaster('yarn')
  #conf.set("spark.hadoop.yarn.resourcemanager.address", "127.0.0.1:8031")
  conf.set("spark.shuffle.service.enabled", "false")
  conf.set("spark.dynamicAllocation.enabled", "false")
  conf.set("spark.cores.max", "1")
  #conf.set("spark.executor.instances","2")
  #conf.set("spark.executor.memory","20m")
  #conf.set("spark.executor.cores","1")
  #conf = SparkConf().setAppName("Word Count - Python").setMaster('spark://10.184.58.83')
  sc = SparkContext(conf=conf)
  # read in text file and split each document into words
  words = sc.textFile("/user/somig/data/alice.txt").flatMap(lambda line: line.split(" "))
  # count the occurrence of each word
  wordCounts = words.map(lambda word: (word, 1)).reduceByKey(lambda a,b:a +b)
  wordCounts.saveAsTextFile("/user/somig/output")
