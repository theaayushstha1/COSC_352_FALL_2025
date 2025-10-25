import java.net.{URL, HttpURLConnection}
import scala.io.Source
import scala.util.matching.Regex
import scala.util.matching.Regex.Match
import java.io.{File, PrintWriter}

object Project5 {
  // Simple HTTP fetch with a UA header to avoid 403s
  def fetch(url: String): String = {
    val conn = new URL(url).openConnection().asInstanceOf[HttpURLConnection]
    conn.setRequestMethod("GET")
    conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Project5-Scala)")
    conn.setConnectTimeout(15000)
    conn.setReadTimeout(20000)
    val stream = conn.getInputStream
    try Source.fromInputStream(stream, "UTF-8").mkString
    finally stream.close()
  }

  def main(args: Array[String]): Unit = {
    val url = "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
    val html = fetch(url)

    // Strip tags and normalize whitespace
    val noTags = "<[^>]+>".r.replaceAllIn(html, "")
    val cleanText = noTags.replaceAll("\r", "").replaceAll("\\s+", " ")

    // Pattern for 2025 entries
    case class Entry(number: String, date: String, month: Int, hasCamera: Boolean, isClosed: Boolean, description: String)

    val pattern: Regex = """(\d{3})\s+(\d{2}/\d{2}/25)\b""".r
    val cameraRe: Regex = """(?i)\b\d+\s*cameras?\b""".r
    val closedRe: Regex = """(?i)\bclosed\b""".r

    val matches: List[Match] = pattern.findAllMatchIn(cleanText).toList

    val entries = (0 until matches.length).flatMap { i =>
      val m = matches(i)
      val start = m.start
      val end = if (i + 1 < matches.length) matches(i + 1).start else cleanText.length
      val line = cleanText.substring(start, end).trim
      val number = m.group(1)
      val date = m.group(2)
      val mm = date.split("/")(0).toInt
      val description = line.substring(m.matched.length).trim
      val hasCam = cameraRe.findFirstIn(line).isDefined
      val isClosed = closedRe.findFirstIn(line).isDefined
      Some(Entry(number, date, mm, hasCam, isClosed, description))
    }

    val outputOpt = if (args.nonEmpty && args(0).startsWith("--output=")) {
      Some(args(0).split("=")(1).toLowerCase)
    } else None

    def csvQuote(s: String): String = "\"" + s.replace("\"", "\"\"") + "\""

    outputOpt match {
      case Some("csv") =>
        val header = "number,date,month,hasCamera,isClosed,description"
        val rows = entries.map { e =>
          Seq(e.number, e.date, e.month.toString, e.hasCamera.toString, e.isClosed.toString, e.description).map(csvQuote).mkString(",")
        }
        val csv = header + "\n" + rows.mkString("\n")
        val pw = new PrintWriter(new File("/app/output/data.csv"))
        pw.write(csv)
        pw.close()

      case Some("json") =>
        def jsonEscape(s: String): String = s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")
        val jsonEntries = entries.map { e =>
          s"""{"number":"${jsonEscape(e.number)}","date":"${jsonEscape(e.date)}","month":${e.month},"hasCamera":${e.hasCamera},"isClosed":${e.isClosed},"description":"${jsonEscape(e.description)}"}"""
        }
        val json = "[" + jsonEntries.mkString(",") + "]"
        val pw = new PrintWriter(new File("/app/output/data.json"))
        pw.write(json)
        pw.close()

      case _ =>
        // ---------- Question 1 ----------
        println("Question 1: How many homicides occurred in each month of 2025?")
        val months = Array("January","February","March","April","May","June","July","August","September","October","November","December")
        val byMonth = entries.groupBy(_.month).view.mapValues(_.length).toMap
        (1 to 12).foreach { m =>
          val count = byMonth.getOrElse(m, 0)
          println(s"${months(m-1)}: $count")
        }

        // ---------- Question 2 ----------
        println("\nQuestion 2: What is the closure rate for incidents with and without surveillance cameras in 2025?")
        val total = entries.length
        val withCam = entries.count(_.hasCamera)
        val withoutCam = total - withCam
        val closedWith = entries.count(e => e.hasCamera && e.isClosed)
        val closedWithout = entries.count(e => !e.hasCamera && e.isClosed)

        def pct(n: Int, d: Int): String = if (d == 0) "0%" else f"${(n.toDouble/d*100)}%.1f%%"

        println(s"Total parsed incidents: $total")
        println(s"With cameras: $withCam, Closed with cameras: $closedWith (${pct(closedWith, withCam)})")
        println(s"Without cameras: $withoutCam, Closed without cameras: $closedWithout (${pct(closedWithout, withoutCam)})")
    }
  }
}
