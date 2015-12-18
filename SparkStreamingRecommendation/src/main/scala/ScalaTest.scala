import java.io.File
import java.util.Random

/**
 * Created by Venu on 12/14/15.
 */
object ScalaTest {

  def main(args: Array[String]) {
    var lists = new RecommendSongs();

    val outs = lists.recommendSongs("src/main/resources/CLASSIC")


  println(outs)



  }

}
