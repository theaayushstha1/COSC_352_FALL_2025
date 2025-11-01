import scala.io.Source
import scala.util.{Try, Success, Failure}
import java.io._

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
    // Default output is stdout
    val outputType = if (args.length > 0) args(0) else "stdout"

    println("=" * 80)
    println("Baltimore City Homicide Statistics Analysis - 2025 Data")
    println("=" * 80)
    println()

    val url = "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"

    fetchAndAnalyzeData(url) match {
      case Success(records) =>
        val records2025 = filterYear(records, "2025")

        val closedCases = countClosedCases(records2025)
        val shootingVictims = countShootingVictims(records2025)

        // Collect summary results
        val summary =
          s"""Total records analyzed for 2025: ${records2025.length}
             |Closed cases: $closedCases
             |Shooting victims: $shootingVictims""".stripMargin

        outputType match {
          case "csv" =>
            writeToCSV(records2025)
            println("✅ Output written to output.csv")

          case "json" =>
            writeToJSON(records2025)
            println("✅ Output written to output.json")

          case _ =>
            println(summary)
            println("=" * 80)
            println("Analysis complete.")
            println("=" * 80)
        }

      case Failure(exception) =>
        println(s"Error fetching data: ${exception.getMessage}")
    }
  }

  // Fetch webpage and parse HTML crudely
  def fetchAndAnalyzeData(urlString: String): Try[List[HomicideRecord]] = Try {
    val html = Source.fromURL(urlString, "UTF-8").mkString
    parseHtmlTable(html)
  }

  // Updated HTML parser
  def parseHtmlTable(html: String): List[HomicideRecord] = {
    val rows = html.split("(?i)<tr")
    val records = scala.collection.mutable.ListBuffer[HomicideRecord]()

    for (row <- rows) {
      val cells = """(?i)<td[^>]*>(.*?)</td>""".r
        .findAllMatchIn(row)
        .map(_.group(1))
        .toList

      if (cells.nonEmpty && cells.head.trim.matches("\\d+.*")) {
        val padded = cells.padTo(8, "")
        val record = HomicideRecord(
          number = clean(padded(0)),
          dateDied = clean(padded(1)),
          name = clean(padded(2)),
          age = clean(padded(3)),
          address = clean(padded(4)),
          notes = clean(padded(5)),
          caseClosed = clean(padded.last)
        )
        records += record
      }
    }
    records.toList
  }

  // Clean up text
  def clean(text: String): String =
    text
      .replaceAll("<[^>]+>", " ")
      .replaceAll("&nbsp;", " ")
      .replaceAll("&amp;", "&")
      .replaceAll("&#x27;", "'")
      .replaceAll("\\s+", " ")
      .trim

  def filterYear(records: List[HomicideRecord], year: String): List[HomicideRecord] = {
    val shortYear = year.takeRight(2)
    records.filter(r =>
      r.dateDied.contains(year) || r.dateDied.matches(s".*\\b$shortYear\\b.*")
    )
  }

  def countClosedCases(records: List[HomicideRecord]): Int =
    records.count(_.caseClosed.toLowerCase.contains("closed"))

  def countShootingVictims(records: List[HomicideRecord]): Int =
    records.count(r => {
      val notes = r.notes.toLowerCase
      notes.contains("shoot") || notes.contains("gunshot")
    })

  // Write CSV
  def writeToCSV(records: List[HomicideRecord]): Unit = {
    val header = "Number,DateDied,Name,Age,Address,Notes,CaseClosed"
    val rows = records.map(r =>
      s"${r.number},${r.dateDied},${r.name},${r.age},${r.address},${r.notes},${r.caseClosed}"
    )
    val csvData = (header +: rows).mkString("\n")
    val writer = new PrintWriter(new File("output.csv"))
    writer.write(csvData)
    writer.close()
  }

  // Write JSON
  def writeToJSON(records: List[HomicideRecord]): Unit = {
    val jsonData = records
      .map(r =>
        s"""{
           |  "number": "${r.number}",
           |  "dateDied": "${r.dateDied}",
           |  "name": "${r.name}",
           |  "age": "${r.age}",
           |  "address": "${r.address}",
           |  "notes": "${r.notes}",
           |  "caseClosed": "${r.caseClosed}"
           |}""".stripMargin
      )
      .mkString("[\n", ",\n", "\n]")
    val writer = new PrintWriter(new File("output.json"))
    writer.write(jsonData)
    writer.close()
  }
}
