import java.io.File
import java.nio.file.{Paths, Files}

import org.apache.spark.SparkContext
import org.apache.spark.mllib.recommendation.{ALS, MatrixFactorizationModel, Rating}
import org.apache.spark.rdd.RDD
import play.libs.Json

import scala.io.Source
import scalaj.http.{Http, HttpOptions}

object Recommendation {
    def recommend(sc: SparkContext) {
      // load personal ratings

      val myRatings = loadRatingsFromFile("src/main/resources/personalRating.txt")
      val myRatingsRDD = sc.parallelize(myRatings, 1)
      var ALSmodel: Option[MatrixFactorizationModel] = null
      // load ratings and movie titles

      val musichomedirectory = "music/"

      val ratings = sc.textFile(new File(musichomedirectory, "sample.txt").toString).map { line =>
        val fields = line.split(",")
        // format: (timestamp % 10, Rating(userId, artistID, plays))
        (fields(2).toLong % 10, Rating(fields(0).toInt, fields(1).toInt, fields(2).toDouble))
      }

      val movies = sc.textFile(new File(musichomedirectory, "userartistplay.csv").toString).map { line =>
        val fields = line.split("::")
        // format: (movieId, movieName)
        (fields(0).toInt, fields(1))
      }.collect().toMap

      val numRatings = ratings.count()
      val numUsers = ratings.map(_._2.user).distinct().count()
      val numArtists = ratings.map(_._2.product).distinct().count()

      println("Got " + numRatings + " ratings from "
        + numUsers + " users on " + numArtists + " musics.")

      if (!Files.exists(Paths.get("movieLens/model/ALS"))) {

        // split ratings into train (60%), validation (20%), and test (20%) based on the
        // last digit of the timestamp, add myRatings to train, and cache them

        val numPartitions = 4
        val training = ratings.filter(x => x._1 < 6)
          .values
          .union(myRatingsRDD)
          .repartition(numPartitions)
          .cache()
        val validation = ratings.filter(x => x._1 >= 6 && x._1 < 8)
          .values
          .repartition(numPartitions)
          .cache()
        val test = ratings.filter(x => x._1 >= 8).values.cache()

        val numTraining = training.count()
        val numValidation = validation.count()
        val numTest = test.count()

        println("Training: " + numTraining + ", validation: " + numValidation + ", test: " + numTest)

        // train models and evaluate them on the validation set
        val ranks = List(8, 12)
        val lambdas = List(0.1, 10.0)
        val numIters = List(10, 20)
        var bestModel: Option[MatrixFactorizationModel] = None
        var bestValidationRmse = Double.MaxValue
        var bestRank = 0
        var bestLambda = -1.0
        var bestNumIter = -1
        for (rank <- ranks; lambda <- lambdas; numIter <- numIters) {
          val model = ALS.train(training, rank, numIter, lambda)
          val validationRmse = computeRmse(model, validation, numValidation)
          println("RMSE (validation) = " + validationRmse + " for the model trained with rank = "
            + rank + ", lambda = " + lambda + ", and numIter = " + numIter + ".")
          if (validationRmse < bestValidationRmse) {
            bestModel = Some(model)
            bestValidationRmse = validationRmse
            bestRank = rank
            bestLambda = lambda
            bestNumIter = numIter
          }
        }

        // evaluate the best model on the test set

        val testRmse = computeRmse(bestModel.get, test, numTest)

        println("The best model was trained with rank = " + bestRank + " and lambda = " + bestLambda
          + ", and numIter = " + bestNumIter + ", and its RMSE on the test set is " + testRmse + ".")

        // create a naive baseline and compare it with the best model

        val meanRating = training.union(validation).map(_.rating).mean
        val baselineRmse =
          math.sqrt(test.map(x => (meanRating - x.rating) * (meanRating - x.rating)).mean)
        val improvement = (baselineRmse - testRmse) / baselineRmse * 100
        println("The best model improves the baseline by " + "%1.2f".format(improvement) + "%.")

        ALSmodel = bestModel;
      }
      else {
        ALSmodel = Option(MatrixFactorizationModel.load(sc, "musichomedirectory/model/ALS"))
      }
      // make personalized recommendations

      val myRatedMovieIds = myRatings.map(_.product).toSet
      val candidates = sc.parallelize(movies.keys.filter(!myRatedMovieIds.contains(_)).toSeq)
      val recommendations = ALSmodel.get
        .predict(candidates.map((0, _)))
        .collect()
        .sortBy(-_.rating)
        .take(5)

      var i = 1
      println("Music recommended for you:")
      recommendations.foreach { r =>
        println("%2d".format(i) + ": " + movies(r.product))
        i += 1
      }

      // clean up
    }

  /** Compute RMSE (Root Mean Squared Error). */
  def computeRmse(model: MatrixFactorizationModel, data: RDD[Rating], n: Long): Double = {
    val predictions: RDD[Rating] = model.predict(data.map(x => (x.user, x.product)))
    val predictionsAndRatings = predictions.map(x => ((x.user, x.product), x.rating))
      .join(data.map(x => ((x.user, x.product), x.rating)))
      .values
    math.sqrt(predictionsAndRatings.map(x => (x._1 - x._2) * (x._1 - x._2)).reduce(_ + _) / n)
  }

  /** Load ratings from file. */
  def loadRatings(): Seq[Rating] = {
    //  Rating(fields(0).toInt, fields(1).toInt, fields(2).toDouble)
    val url = "https://api.mongolab.com/api/1/databases/rtbd/collections/userratings?apiKey=VH-BdhSnipYJ5AtkUcdvpnZRs2cKoWLN"
    val result = scala.io.Source.fromURL(url).mkString
    println(result)
    //.responseCode -- the same error

    val jsonArray = Json.parse(result)

    var ratingsArray = List[Rating]()

    for (i <- 0 until jsonArray.size()) {
      val jsvalue = jsonArray.get(i)
      println(jsvalue.toString)

      val r = new Rating(
        jsvalue.get("UserId").asInt(),
        jsvalue.get("artistid").asInt(),
        jsvalue.get("Plays").asInt()
      )

      ratingsArray = ratingsArray :+ r
    }

    println(ratingsArray.size)

    ratingsArray.toSeq
  }

  def pushDataToMongo: Unit = {
    val lines = Source.fromFile("personalRating.txt").getLines()
    val ratings = lines.foreach(line => {
      val fields = line.split("::")
      val jsonHeaders = "{\"UserId\":\""+ fields(0) + "\",\"artistid\" :\"" + fields(1) + "\", \"Plays\" :\"" + fields(2) + "\", \"artistname\" :\"" + fields(3) + "\"}"
      //  print(jsonHeaders)
      val result = Http("https://api.mongolab.com/api/1/databases/rtbd/collections/userratings?apiKey=VH-BdhSnipYJ5AtkUcdvpnZRs2cKoWLN")
        .postData(jsonHeaders)
        .header("content-type", "application/json")
        .option(HttpOptions.readTimeout(10000))
        .asString
      println(result)
    })
  }

  def loadRatingsFromFile(path: String): Seq[Rating] = {
    val lines = Source.fromFile(path).getLines()
    val ratings = lines.map { line =>
      val fields = line.split("::")
      Rating(fields(0).toInt, fields(1).toInt, fields(2).toDouble)
    }.filter(_.rating > 0.0)
    if (ratings.isEmpty) {
      sys.error("No ratings provided.")
    } else {
      ratings.toSeq
    }
  }
}
