import org.jsoup.Jsoup
import scala.jdk.CollectionConverters._
import scala.util.Try

object Main extends App {

  val url = "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"

  case class HomicideCase(date: String, name: String, age: Int, address: String, caseClosed: String)

  try {
    println("Fetching Baltimore Homicide Statistics...\n")

    // Fetch and parse the website
    val doc = Jsoup.connect(url).get()
    val rows = doc.select("table tr").asScala.tail // skip header

    // Echo all raw data in the terminal
    println("---- RAW HOMICIDE DATA ----")
    rows.foreach { row =>
      val cells = row.select("td").asScala.map(_.text().trim)
      println(cells.mkString(" | "))
    }
    println("----------------------------\n")

    // Parse into structured records
    val homicideCases = rows.flatMap { row =>
      val cells = row.select("td").asScala.map(_.text().trim)
      if (cells.size >= 5) {
        val date = cells.lift(1).getOrElse("")
        val name = cells.lift(2).getOrElse("")
        val age = Try(cells.lift(3).getOrElse("0").toInt).getOrElse(0)
        val address = cells.lift(4).getOrElse("")
        val caseClosed = cells.lastOption.getOrElse("")
        Some(HomicideCase(date, name, age, address, caseClosed))
      } else None
    }.toSeq

    // --------------------------
    // Compute results
    // --------------------------

    // Question 1: Street with most homicide cases
    val streetCounts = homicideCases
      .flatMap { h =>
        val street = h.address
          .replaceAll("""(?i)\b(block|blk|unit)\b""", "")
          .replaceAll("""\d+""", "")
          .replaceAll("""\s+""", " ")
          .trim
        if (street.nonEmpty) Some(street) else None
      }
      .groupBy(identity)
      .view
      .mapValues(_.size)
      .toSeq
      .sortBy(-_._2)

    val topStreet = streetCounts.headOption

    // Question 2: Total closed cases
    val closedCases = homicideCases.count(_.caseClosed.equalsIgnoreCase("Closed"))

    // --------------------------
    // Print questions and results
    // --------------------------
    println("\n===== Baltimore Homicide Analysis =====\n")

    println("Question 1: Name one street with one of the highest number of homicide cases?")
    topStreet match {
      case Some((street, count)) => println(s"$street : $count cases")
      case None => println("No street data found.")
    }

    println()
    println("Question 2: What is total number of homicide cases that have been closed:")
    println(closedCases)

    println("\n=======================================\n")

  } catch {
    case e: Exception =>
      println(s"Failed to fetch or parse data: ${e.getMessage}")
  }
}
