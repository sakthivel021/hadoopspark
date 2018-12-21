package com.ericsson.datamigration.bss;

import java.io.BufferedInputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URI;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataOutputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IOUtils;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.ericsson.somig.workflow.data.MessageData;

public class Test {

	public static void main(String[] args) throws JSONException {
		
		String hdfsuri = "hdfs://10.184.40.112:8020/";
		String path="/user/hdfs/example/hdfs1/";
		//String fileName="hello.csv";		
		
		Configuration conf = new Configuration();
		conf.set("fs.defaultFS", hdfsuri);
		conf.set("fs.hdfs.impl", org.apache.hadoop.hdfs.DistributedFileSystem.class.getName());
		conf.set("fs.file.impl", org.apache.hadoop.fs.LocalFileSystem.class.getName());
		
		System.setProperty("HADOOP_USER_NAME", "hdfs");
		System.setProperty("hadoop.home.dir", "/");
		InputStream is = null;
		
		try {
			FileSystem fs = FileSystem.get(URI.create(hdfsuri), conf);
			//Path workingDir = fs.getWorkingDirectory();
			Path newFolderPath = new Path(path);
			if (fs.exists(newFolderPath)) {
				fs.delete(newFolderPath, true);
			}
			// Create new Directory
			fs.mkdirs(newFolderPath);
			System.out.println("Path " + path + " created.");

			// Create a path
			//Path hdfswritepath = new Path(newFolderPath);
			// Init output stream
			OutputStream outputStream = fs.create(newFolderPath);
			is = new BufferedInputStream(new FileInputStream("c:\\n\\java8File.txt1"));
	        IOUtils.copyBytes(is, outputStream, 4096, false);
	        
			// Cassical output stream usage
			//outputStream.writeBytes("hello world");
			outputStream.close();
			fs.close();

		} catch (IOException e) {			
			e.printStackTrace();
		}finally{
            IOUtils.closeStream(is);
        }
	
	
	}

}

