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
    val normalized = noTags.replaceAll("\r", "").replaceAll("\\s+", " ")

    // Truncate at footer marker to exclude blog footers, archives, scripts, etc.
    val footerStart = normalized.indexOf("Post a Comment")
    val cleanText = if (footerStart > -1) normalized.substring(0, footerStart).trim else normalized.trim

    // Pattern for all entries (2025 and non-2025, including XXX/???)
    case class Entry(number: String, date: String, month: Int, hasCamera: Boolean, isClosed: Boolean, description: String)

    val pattern: Regex = """(\d{3}|XXX|\?\?\?)\s+(\d{2}/\d{2}/\d{2})\b""".r
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
      if (date.endsWith("/25")) {
        val mm = date.split("/")(0).toInt
        val description = line.substring(m.matched.length).trim
        val hasCam = cameraRe.findFirstIn(line).isDefined
        val isClosed = closedRe.findFirstIn(line).isDefined
        Some(Entry(number, date, mm, hasCam, isClosed, description))
      } else {
        None
      }
    }

    val outputOpt = if (args.nonEmpty && args(0).startsWith("--output=")) {
      Some(args(0).split("=")(1).toLowerCase)
    } else None

    // Compute aggregates for questions
    val months = Array("January","February","March","April","May","June","July","August","September","October","November","December")
    val byMonth = entries.groupBy(_.month).view.mapValues(_.length).toMap
    val monthlyCounts = (1 to 12).map { m =>
      val count = byMonth.getOrElse(m, 0)
      (months(m-1), count)
    }

    val total = entries.length
    val withCam = entries.count(_.hasCamera)
    val withoutCam = total - withCam
    val closedWith = entries.count(e => e.hasCamera && e.isClosed)
    val closedWithout = entries.count(e => !e.hasCamera && e.isClosed)

    def pct(n: Int, d: Int): String = if (d == 0) "0%" else f"${(n.toDouble/d*100)}%.1f%%"

    val closureStats = Map(
      "total_incidents" -> total,
      "with_cameras" -> withCam,
      "closed_with_cameras" -> closedWith,
      "closed_with_cameras_pct" -> pct(closedWith, withCam),
      "without_cameras" -> withoutCam,
      "closed_without_cameras" -> closedWithout,
      "closed_without_cameras_pct" -> pct(closedWithout, withoutCam)
    )

    def csvQuote(s: String): String = "\"" + s.replace("\"", "\"\"") + "\""

    outputOpt match {
      case Some("csv") =>
        val pw = new PrintWriter(new File("/app/output/data.csv"))
        pw.println("Question 1: How many homicides occurred in each month of 2025?")
        pw.println("month,count")
        monthlyCounts.foreach { case (month, count) =>
          pw.println(s"${csvQuote(month)},$count")
        }
        pw.println("")
        pw.println("Question 2: What is the closure rate for incidents with and without surveillance cameras in 2025?")
        pw.println("metric,value")
        closureStats.foreach { case (metric, value) =>
          pw.println(s"${csvQuote(metric)},${csvQuote(value.toString)}")
        }
        pw.close()

      case Some("json") =>
        def jsonEscape(s: String): String = s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")
        val monthlyJson = monthlyCounts.map { case (month, count) =>
          s"""{"month":"${jsonEscape(month)}","count":$count}"""
        }.mkString("[", ",", "]")
        val closureJson = closureStats.map { case (metric, value) =>
          s""""${jsonEscape(metric)}":"${jsonEscape(value.toString)}""""
        }.mkString("{", ",", "}")
        val json = s"""{"question1":$monthlyJson,"question2":$closureJson}"""
        val pw = new PrintWriter(new File("/app/output/data.json"))
        pw.write(json)
        pw.close()

      case _ =>
        // ---------- Question 1 ----------
        println("Question 1: How many homicides occurred in each month of 2025?")
        monthlyCounts.foreach { case (month, count) =>
          println(s"$month: $count")
        }

        // ---------- Question 2 ----------
        println("\nQuestion 2: What is the closure rate for incidents with and without surveillance cameras in 2025?")
        println(s"Total parsed incidents: $total")
        println(s"With cameras: $withCam, Closed with cameras: $closedWith (${pct(closedWith, withCam)})")
        println(s"Without cameras: $withoutCam, Closed without cameras: $closedWithout (${pct(closedWithout, withoutCam)})")
    }
  }
}