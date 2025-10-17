import scala.io.Source
import scala.util.matching.Regex

object Project4 {
  def main(args: Array[String]): Unit = {
    val url = "https://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html"
    val html = Source.fromURL(url).mkString
    val cleanText = """<[^>]+>""".r.replaceAllIn(html, "")  // Remove HTML tags
    val lines = cleanText.split("\n").map(_.trim).filter(_.nonEmpty).filter(l => l.matches("^\\d{3}.*"))

    case class Entry(month: Int, hasCamera: Boolean, isClosed: Boolean)

    val pattern = new Regex("""^(\d{3}) (\d{2})/\d{2}/\d{2} (.*?) (\d+) (.*)$""")

    val entries = lines.flatMap { line =>
      pattern.findFirstMatchIn(line) match {
        case Some(m) =>
          val month = m.group(2).toInt
          val rest = m.group(5)
          val hasCamera = rest.matches(".*\\d+ cameras?.*")
          val isClosed = rest.contains("Closed")
          Some(Entry(month, hasCamera, isClosed))
        case None => None
      }
    }

    // Question 1
    println("Question 1: How many homicides occurred in each month of 2024?")
    val months = Array("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")
    val countByMonth = entries.groupBy(_.month).map { case (m, es) => (m, es.size) }
    for (m <- 1 to 12) {
      val count = countByMonth.getOrElse(m, 0)
      println(s"${months(m-1)}: $count")
    }

    // Question 2
    println("\nQuestion 2: What is the impact of surveillance cameras on case closure rates in 2024 homicides?")
    val total = entries.size
    val withCamera = entries.count(_.hasCamera)
    val withoutCamera = total - withCamera
    val closedWith = entries.count(e => e.hasCamera && e.isClosed)
    val closedWithout = entries.count(e => !e.hasCamera && e.isClosed)
    println(s"Total homicides: $total")
    println(s"Homicides with surveillance cameras: $withCamera (${(withCamera.toDouble / total * 100).round}%)")
    println(s"Closed cases with cameras: $closedWith / $withCamera (${if (withCamera > 0) (closedWith.toDouble / withCamera * 100).round else 0}%)")
    println(s"Closed cases without cameras: $closedWithout / $withoutCamera (${if (withoutCamera > 0) (closedWithout.toDouble / withoutCamera * 100).round else 0}%)")
  }
}

