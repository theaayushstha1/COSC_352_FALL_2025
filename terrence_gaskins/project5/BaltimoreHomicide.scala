import scala.io.Source
import scala.util.{Try, Success, Failure}
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.io.{File, PrintWriter}
import java.nio.file.{Files, Paths}

object BaltimoreHomicide {

  final case class Homicide(
    number: String,
    dateDied: String,
    name: String,
    ageRaw: String,
    address: String,
    notes: String,
    noViolentHistory: String,
    surveillance: String,
    caseClosed: String
  ) {
    lazy val ageOpt: Option[Int] = {
      val digits = ageRaw.takeWhile(_.isDigit)
      if (digits.nonEmpty) Some(digits.toInt) else None
    }
    lazy val hasCamera: Boolean = {
      val s = surveillance.trim.toLowerCase
      s.nonEmpty && !s.contains("none")
    }
    lazy val isClosed: Boolean = caseClosed.trim.toLowerCase.contains("closed")
    lazy val cause: String = {
      val n = notes.toLowerCase
      if (n.contains("shoot")) "Shooting"
      else if (n.contains("stab")) "Stabbing"
      else if (n.contains("blunt") || n.contains("struck")) "Blunt Force"
      else "Other"
    }
    lazy val parsedDate: Option[LocalDate] = {
      val formatter = DateTimeFormatter.ofPattern("yyyy/MM/dd")
      Try(LocalDate.parse(dateDied, formatter)).toOption
    }
  }

  def main(args: Array[String]): Unit = {
    val format = args.headOption.getOrElse("stdout").toLowerCase

    println()
    println("Baltimore Homicide Analytics — Project 5")
    println("Data source: chamspage (public homicide list)")
    println()

    val urls = List(
      "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html",
      "http://chamspage.blogspot.com"
    )

    val htmlOpt = urls.view.flatMap(fetch).headOption
    htmlOpt match {
      case None =>
        println("Error: Unable to download homicide table from chamspage.")
      case Some(html) =>
        val homicides = parseTable(html)
        if (homicides.isEmpty) {
          println("No homicide rows were parsed; the source page structure may have changed.")
          return
        }

        val q1 = question1_StabbingsIn2024(homicides)
        val q2 = question2_AvenueCases(homicides)
        val allResults = q1 ++ q2

        format match {
          case "csv" =>
            writeCSV(allResults, "baltimore_homicide_analysis.csv")
            println("✅ CSV file written: baltimore_homicide_analysis.csv")
          case "json" =>
            writeJSON(allResults, "baltimore_homicide_analysis.json")
            println("✅ JSON file written: baltimore_homicide_analysis.json")
          case _ =>
            println("=" * 80)
            q1.foreach(println)
            println("=" * 80)
            q2.foreach(println)
            println("=" * 80)
        }
    }
  }

  private def fetch(url: String): Option[String] = {
    Try(Source.fromURL(url, "UTF-8").mkString) match {
      case Success(content) => Some(content)
      case Failure(_)       => None
    }
  }

  private def parseTable(html: String): List[Homicide] = {
    val rowRegex = """(?is)<tr[^>]*>(.*?)</tr>""".r
    val cellRegex = """(?is)<t[dh][^>]*>(.*?)</t[dh]>""".r

    val rows = rowRegex.findAllMatchIn(html).map(_.group(1)).toList
    val parsedRows = rows.map { r =>
      val cells = cellRegex.findAllMatchIn(r).map(_.group(1)).toList.map(cleanCell)
      cells
    }

    val headerIdx = parsedRows.indexWhere { cells =>
      val joined = cells.map(_.toLowerCase).mkString("|")
      joined.contains("date died") && joined.contains("case closed")
    }

    val dataRows = if (headerIdx >= 0) parsedRows.drop(headerIdx + 1) else parsedRows

    dataRows.flatMap { cells =>
      if (cells.length >= 9 && cells.headOption.exists(_.matches("""\d+"""))) {
        Some(Homicide(
          cells(0), cells(1), cells(2), cells(3),
          cells(4), cells(5), cells(6), cells(7), cells(8)
        ))
      } else None
    }
  }

  private def cleanCell(s: String): String = {
    val noTags = s.replaceAll("(?is)<[^>]+>", " ")
    val unescaped = noTags
      .replace("&nbsp;", " ")
      .replace("&amp;", "&")
      .replace("&lt;", "<")
      .replace("&gt;", ">")
    unescaped.replaceAll("\\s+", " ").trim
  }

  def question1_StabbingsIn2024(data: List[Homicide]): List[String] = {
    val stabbingCases = data.filter(h => h.dateDied.contains("2024") && h.cause == "Stabbing")
    val lines = stabbingCases.map(h => s"${h.dateDied},${h.name},${h.notes}")
    lines :+ s"Total stabbing cases in 2024: ${stabbingCases.size}"
  }

  def question2_AvenueCases(data: List[Homicide]): List[String] = {
    val avenueCases = data.filter(_.address.toLowerCase.contains("avenue"))
    val lines = avenueCases.map(h => s"${h.dateDied},${h.name},${h.address}")
    lines :+ s"Total cases with 'Avenue': ${avenueCases.size}"
  }

  def writeCSV(lines: List[String], filename: String): Unit = {
    val header = "Date,Name,Details"
    val content = (header +: lines).mkString("\n")
    val writer = new PrintWriter(new File(filename))
    writer.write(content)
    writer.close()
  }

  def writeJSON(lines: List[String], filename: String): Unit = {
    val json = lines.map { line =>
      val parts = line.split(",", 3)
      if (parts.length == 3)
        s"""{"date":"${parts(0)}","name":"${parts(1)}","details":"${parts(2)}"}"""
      else
        s"""{"summary":"$line"}"""
    }.mkString("[", ",", "]")
    val writer = new PrintWriter(new File(filename))
    writer.write(json)
    writer.close()
  }
}
