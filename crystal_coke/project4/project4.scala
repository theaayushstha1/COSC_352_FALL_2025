import scala.io.Source
import scala.util.{Try, Success, Failure}

object BaltimoreHomicideAnalyzer {

  // Case class for one homicide record
  case class HomicideRecord(
    number: String,
    dateDied: String,
    name: String,
    age: String,
    address: String,
    notes: String,
    caseClosed: String
  )

  def main(args: Array[String]): Unit = {
    println("=" * 80)
    println("Baltimore City Homicide Statistics Analysis - 2025 Data")
    println("=" * 80)
    println()

    // ✅ Use the real 2025 page URL
    val url = "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"

    fetchAndAnalyzeData(url) match {
      case Success(records) =>
        val records2025 = filterYear(records, "2025")

        println(s"Total records analyzed for 2025: ${records2025.length}")
        println()

        // Question 1
        val closedCases = countClosedCases(records2025)
        println("QUESTION 1:")
        println("How many Baltimore City homicide cases are closed from 2025?")
        println(s"ANSWER: $closedCases cases are closed.")
        println()

        // Question 2
        val shootingVictims = countShootingVictims(records2025)
        println("QUESTION 2:")
        println("How many were shooting victims in 2025?")
        println(s"ANSWER: $shootingVictims victims.")
        println()

        println("=" * 80)
        println("Analysis complete.")
        println("=" * 80)

      case Failure(exception) =>
        println(s"Error fetching data: ${exception.getMessage}")
    }
  }

  // Fetch webpage and parse HTML crudely
  def fetchAndAnalyzeData(urlString: String): Try[List[HomicideRecord]] = Try {
    val html = Source.fromURL(urlString, "UTF-8").mkString
    parseHtmlTable(html)
  }

  // ✅ Updated HTML parser that works with mixed tag cases and extra columns
  def parseHtmlTable(html: String): List[HomicideRecord] = {
    val rows = html.split("(?i)<tr") // case-insensitive split on <tr>
    val records = scala.collection.mutable.ListBuffer[HomicideRecord]()

    for (row <- rows) {
      val cells = """(?i)<td[^>]*>(.*?)</td>""".r
        .findAllMatchIn(row)
        .map(_.group(1))
        .toList

      // Each valid record starts with a number
      if (cells.nonEmpty && cells.head.trim.matches("\\d+.*")) {
        val padded = cells.padTo(8, "") // handle missing columns safely

        val record = HomicideRecord(
          number = clean(padded(0)),
          dateDied = clean(padded(1)),
          name = clean(padded(2)),
          age = clean(padded(3)),
          address = clean(padded(4)),
          notes = clean(padded(5)),
          caseClosed = clean(padded.last) // "Closed" usually in last cell
        )
        records += record
      }
    }

    records.toList
  }

  // Clean up text from HTML tags
  def clean(text: String): String =
    text
      .replaceAll("<[^>]+>", " ") // remove HTML tags
      .replaceAll("&nbsp;", " ")
      .replaceAll("&amp;", "&")
      .replaceAll("&#x27;", "'")
      .replaceAll("\\s+", " ")
      .trim

  // ✅ Improved year filter (handles both “01/09/25” and “01/09/2025”)
  def filterYear(records: List[HomicideRecord], year: String): List[HomicideRecord] = {
    val shortYear = year.takeRight(2)
    records.filter(r =>
      r.dateDied.contains(year) || r.dateDied.matches(s".*\\b$shortYear\\b.*")
    )
  }

  // Count cases marked “Closed”
  def countClosedCases(records: List[HomicideRecord]): Int =
    records.count(r => r.caseClosed.toLowerCase.contains("closed"))

  // Count records where the notes mention shooting
  def countShootingVictims(records: List[HomicideRecord]): Int =
    records.count { r =>
      val notes = r.notes.toLowerCase
      notes.contains("shoot") || notes.contains("gunshot")
    }
}

