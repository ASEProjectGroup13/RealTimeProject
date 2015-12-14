import java.net.InetAddress

import org.apache.spark.SparkConf
import org.apache.spark.streaming.{Seconds, StreamingContext}

/**
 * Created by Mayanka on 23-Jul-15.
 */
object MainStreaming {
  def main (args: Array[String]) {
    System.setProperty("hadoop.home.dir","F:\\winutils")
    val sparkConf=new SparkConf()
      .setAppName("SparkStreaming")
      .set("spark.executor.memory", "4g").setMaster("local[*]")
    val ssc= new StreamingContext(sparkConf,Seconds(2))
    val sc=ssc.sparkContext
    val ip=InetAddress.getByName("10.205.0.25").getHostName
    val lines=ssc.socketTextStream(ip,9999)

   val command= lines.map(x=>{
      val y=x.toUpperCase()
      y
    })
    command.foreachRDD(
    rdd=>
      {
        if(rdd.collect().contains("RECOMMEND"))
        {
          Recommendation.recommend(rdd.context)
        }
      }
    )
    lines.print()
    ssc.start()
    ssc.awaitTermination()
  }
}
