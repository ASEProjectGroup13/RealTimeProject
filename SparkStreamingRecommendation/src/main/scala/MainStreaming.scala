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
      .set("spark.executor.memory", "2g").setMaster("local[*]")
    val ssc= new StreamingContext(sparkConf,Seconds(2))
    val sc=ssc.sparkContext
    val ip=InetAddress.getByName("10.205.0.10").getHostName
   // val ip = InetAddress.getByName("192.168.0.8").getHostName
    val lines=ssc.socketTextStream(ip,1234)

   val command= lines.map(x=>{
      val y=x.toUpperCase()
      y
    })
    command.foreachRDD(
    rdd=>
      {
        if(rdd.collect().contains("RECOMMEND"))
        {

          println("connected to data")
         // Recommendation.recommend(sc)
          var data= "recommendedsongs::"+ Recommendation.recommendedSongsBasedOnGenres("BLUES::YEN LEE")
          iOSConnector.sendCommandToRobot(data)
          println("sendingSongs to robot"+data)
        }else if(rdd.collect().contains("CLASSIFY")){

          println("Inside classification")

          var filename = rdd.collect().toString.split("::")

         // println("filename"+filename(1).trim().toLowerCase)
          //var classify = ServerToReceiveAudioData.genreClassify(filename(1).trim().toLowerCase);

          var classify = ServerToReceiveAudioData.genreClassify("blues.00000.au");
          var data=  Recommendation.recommendedSongsBasedOnGenres(classify.toUpperCase+"::YIGENS")

          iOSConnector.sendCommandToRobot("RECOMMEND::"+data)

          println("sendingSongs to robot for classification")
        }
      }
    )
    lines.print()
    ssc.start()
    ssc.awaitTermination()
  }
}
