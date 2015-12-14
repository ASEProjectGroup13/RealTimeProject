/**
 * Created by Venu on 12/6/15.
 */

import org.apache.spark.{SparkContext, SparkConf}

object StartingSpark {

  def main(args: Array[String]) {

    val conf = new SparkConf().setAppName("Spark Streaming").setMaster("local")

    val sc = new SparkContext(conf)

    //Recommendation.pushDataToMongo

   Recommendation.recommend(sc)
  }

}
