import org.jsoup.Jsoup
import scala.jdk.CollectionConverters._

object Main extends App {

  val url = "https://chamspage.blogspot.com/"

  case class HomicideStat(year: String, total: String, details: String)

  try {
    val doc = Jsoup.connect(url).get()

    // Select all posts
    val posts = doc.select("div.post").asScala

    val homicideStats = posts.flatMap { post =>
      val title = post.select("h3.post-title").text()
      val content = post.select("div.post-body").text()

      if (title.toLowerCase.contains("homicide")) {
       
        val yearPattern = """\b(20\d{2})\b""".r
        val totalPattern = """Total:\s*(\d+)""".r

        val year = yearPattern.findFirstIn(content).getOrElse("N/A")
        val total = totalPattern.findFirstMatchIn(content).map(_.group(1)).getOrElse("N/A")

        Some(HomicideStat(year, total, content))
      } else None
    }

    if (homicideStats.isEmpty) {
      println("No homicide statistics found.")
    } else {
      println(f"${"Year"}%-6s | ${"Total Homicides"}%-15s | Details")
      println("-" * 80)
      homicideStats.foreach { stat =>
        println(f"${stat.year}%-6s | ${stat.total}%-15s | ${stat.details}")
      }
    }

  } catch {
    case e: Exception =>
      println(s"Failed to fetch data: ${e.getMessage}")
  }
}
