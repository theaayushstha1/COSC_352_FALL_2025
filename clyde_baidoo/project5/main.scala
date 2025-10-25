import org.jsoup.Jsoup
import scala.jdk.CollectionConverters._
import scala.util.Try
import java.io.{File, PrintWriter}
import ujson._

object Main extends App {

  // ------------------------------------------
  // Parse command-line argument
  // ------------------------------------------
  val outputFormat: String = args.find(_.startsWith("--output=")) match {
    case Some(flag) => flag.split("=", 2).lift(1).getOrElse("stdout").toLowerCase
    case None       => "stdout"
  }

  val url = "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"

  // Case class to hold structured homicide data
  case class HomicideCase(date: String, name: String, age: Int, address: String, caseClosed: String)

  try {
    val doc = Jsoup.connect(url).get()
    val rows = doc.select("table tr").asScala.tail // skip header row

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
    // Compute analytics
    // --------------------------
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
    val closedCases = homicideCases.count(_.caseClosed.equalsIgnoreCase("Closed"))

    // --------------------------
    // Default: print raw data + analysis
    // --------------------------
    if (outputFormat == "stdout") {
      println("Fetching Baltimore Homicide Statistics...\n")
      println("---- RAW HOMICIDE DATA ----")
      rows.foreach { row =>
        val cells = row.select("td").asScala.map(_.text().trim)
        println(cells.mkString(" | "))
      }
      println("----------------------------\n")

      println("\n===== Baltimore Homicide Analysis =====\n")
      println("Question 1: Name one street with one of the highest number of homicide cases?")
      topStreet match {
        case Some((street, count)) => println(s"$street : $count cases")
        case None => println("No street data found.")
      }

      println("\nQuestion 2: What is total number of homicide cases that have been closed?")
      println(closedCases)
      println("\n=======================================\n")
    }
    // --------------------------
    // CSV Output
    // --------------------------
    else if (outputFormat == "csv") {
      val file = new File("output.csv")
      val pw = new PrintWriter(file)

      // Markdown-style header for tabular look
      pw.println("| Date | Name | Age | Address | CaseClosed |")
      pw.println("|------|------|-----|---------|------------|")

      homicideCases.foreach { h =>
        def escapePipe(s: String) = s.replace("|", "\\|")
        val line = Seq(h.date, h.name, h.age.toString, h.address, h.caseClosed)
          .map(escapePipe)
          .mkString("|", "|", "|")
        pw.println(line)
      }

      pw.close()
      println(s"\n✅ CSV data written to ${file.getAbsolutePath}")
    }
    // --------------------------
    // JSON Output
    // --------------------------
    else if (outputFormat == "json") {
      val jsonArray = homicideCases.map { h =>
        Obj(
          "date" -> h.date,
          "name" -> h.name,
          "age" -> h.age,
          "address" -> h.address,
          "caseClosed" -> h.caseClosed
        )
      }
      val jsonString = ujson.write(jsonArray, indent = 2)
      val file = new File("output.json")
      val pw = new PrintWriter(file)
      pw.write(jsonString)
      pw.close()
      println(s"\n✅ JSON data written to ${file.getAbsolutePath}")
    }
    // --------------------------
    // Unknown output format
    // --------------------------
    else {
      println(s"⚠️ Unknown output format '$outputFormat'. Defaulting to stdout.\n")
    }

  } catch {
    case e: Exception =>
      println(s"❌ Failed to fetch or parse data: ${e.getMessage}")
  }
}
