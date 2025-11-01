import org.jsoup.Jsoup
import org.jsoup.nodes.Element

import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Path, Paths}
import scala.jdk.CollectionConverters._

object Main {
  private val Url = "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
  private val OutputArg = "--output="

  private case class QA(question: String, answer: String)

  def main(args: Array[String]): Unit = {
    println("Fetching Baltimore homicide data...")
    val doc = Jsoup.connect(Url).userAgent("Mozilla/5.0").get()
    val rows = doc.select("tr").asScala.toSeq

    val results = Seq(
      QA("How old is Richie Briggs?", buildAgeAnswer(rows, "Richie Briggs")),
      QA("Where does Edward Johnson live?", buildAddressAnswer(rows, "Edward Johnson"))
    )

    val format = determineOutputFormat(args).getOrElse("stdout")

    format match {
      case "stdout" | "text" =>
        renderStdout(results)
      case "csv" =>
        val csvPath = resolveOutputPath("baltimore_homicide_answers.csv")
        writeCsv(csvPath, results)
        println(s"Wrote CSV output to ${csvPath.toAbsolutePath}")
      case "json" =>
        val jsonPath = resolveOutputPath("baltimore_homicide_answers.json")
        writeJson(jsonPath, results)
        println(s"Wrote JSON output to ${jsonPath.toAbsolutePath}")
      case other =>
        println(s"Unrecognized output format '$other'; falling back to stdout.")
        renderStdout(results)
    }
  }

  private def renderStdout(results: Seq[QA]): Unit = {
    println()
    println("Question 1: " + results.head.question)
    println(results.head.answer)
    println()
    println("Question 2: " + results(1).question)
    println(results(1).answer)
  }

  private def buildAgeAnswer(rows: Seq[Element], displayName: String): String = {
    val searchName = displayName.toLowerCase
    rows.collectFirst {
      case row if hasVictimInColumn(row, 2, searchName) && row.select("td").size() >= 4 =>
        val age = row.select("td").get(3).text().trim
        if (age.isEmpty) {
          s"$displayName was Unknown years old."
        } else {
          s"$displayName was $age years old."
        }
    }.getOrElse(s"$displayName not found.")
  }

  private def buildAddressAnswer(rows: Seq[Element], displayName: String): String = {
    val searchName = displayName.toLowerCase
    rows.collectFirst {
      case row if hasVictimInColumn(row, 2, searchName) && row.select("td").size() >= 5 =>
        val address = row.select("td").get(4).text().trim
        if (address.isEmpty) {
          s"$displayName lived at: Address not found, Baltimore City."
        } else {
          s"$displayName lived at: $address, Baltimore City."
        }
    }.getOrElse(s"$displayName not found.")
  }

  private def hasVictimInColumn(row: Element, columnIndex: Int, target: String): Boolean = {
    val cells = row.select("td")
    cells.size() > columnIndex && cells.get(columnIndex).text().toLowerCase.contains(target)
  }

  private def determineOutputFormat(args: Array[String]): Option[String] = {
    val eqFormat = args.collectFirst {
      case arg if arg.startsWith(OutputArg) && arg.length > OutputArg.length =>
        arg.substring(OutputArg.length)
    }

    val separateFormat = args.sliding(2, 1).collectFirst {
      case Array("--output", value) => value
    }

    eqFormat.orElse(separateFormat).map(_.trim.toLowerCase).filter(_.nonEmpty)
  }

  private def resolveOutputPath(fileName: String): Path = {
    val base = sys.env.get("OUTPUT_DIR").filter(_.nonEmpty).map(Paths.get(_)).getOrElse(Paths.get("."))
    base.resolve(fileName)
  }

  private def writeCsv(path: Path, results: Seq[QA]): Unit = {
    val header = "question,answer"
    val body = results.map(r => s"${escapeCsv(r.question)},${escapeCsv(r.answer)}")
    val content = (header +: body).mkString("\n")
    writeToFile(path, content)
  }

  private def writeJson(path: Path, results: Seq[QA]): Unit = {
    val items = results.map { r =>
      s"""  {"question": "${escapeJson(r.question)}", "answer": "${escapeJson(r.answer)}"}"""
    }
    val content =
      if (items.isEmpty) "[]"
      else items.mkString("[\n", ",\n", "\n]")
    writeToFile(path, content)
  }

  private def writeToFile(path: Path, content: String): Unit = {
    Option(path.getParent).foreach(parent => Files.createDirectories(parent))
    Files.write(path, content.getBytes(StandardCharsets.UTF_8))
  }

  private def escapeCsv(value: String): String = {
    val escaped = value.replace("\"", "\"\"")
    if (escaped.exists(ch => ch == ',' || ch == '"' || ch == '\n' || ch == '\r')) s"\"$escaped\"" else escaped
  }

  private def escapeJson(value: String): String = {
    value.flatMap {
      case '"'  => "\\\""
      case '\\' => "\\\\"
      case '\b' => "\\b"
      case '\f' => "\\f"
      case '\n' => "\\n"
      case '\r' => "\\r"
      case '\t' => "\\t"
      case ch   => ch.toString
    }
  }
}
