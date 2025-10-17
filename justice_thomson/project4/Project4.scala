import java.net.{URL, HttpURLConnection}
import java.nio.charset.StandardCharsets
import scala.io.Source
import scala.util.matching.Regex

object Project4 {
  // Simple HTTP fetch with a UA header to avoid 403s
  def fetch(url: String): String = {
    val conn = new URL(url).openConnection().asInstanceOf[HttpURLConnection]
    conn.setRequestMethod("GET")
    conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Project4-Scala)")
    conn.setConnectTimeout(15000)
    conn.setReadTimeout(20000)
    val stream = conn.getInputStream
    try Source.fromInputStream(stream, "UTF-8").mkString
    finally stream.close()
  }

  def main(args: Array[String]): Unit = {
    val url = "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
    val html = fetch(url)

    // Remove HTML tags and normalize whitespace
    val noTags = "<[^>]+>".r.replaceAllIn(html, "")
    val cleanText = noTags.replaceAll("\r", "")
    val lines = cleanText.split("\n").map(_.trim).filter(_.nonEmpty)

    // The blog lists rows that typically begin with a 3-digit incident counter like "001 01/01/25 ..."
    // We'll parse (month, hasCamera, isClosed) from such lines.
    case class Entry(month: Int, hasCamera: Boolean, isClosed: Boolean)

    // Example-ish pattern: "123 02/05/25 Victim Name 25 M ... 2 cameras ... Closed"
    // We capture: (counter) (MM)/(DD)/(YY) then leave the rest loose for simple keyword checks.
    val pattern: Regex = """^(\d{3})\s+(\d{2})/(\d{2})/(\d{2})\b.*$""".r

    val entries = lines.flatMap { line =>
      line match {
        case pattern(_, mm, _, _) =>
          val month = mm.toInt
          val hasCam = "(?i)\b\d+\s*cameras?\b".r.findFirstIn(line).isDefined
          val isClosed = "(?i)\bclosed\b".r.findFirstIn(line).isDefined
          Some(Entry(month, hasCam, isClosed))
        case _ => None
      }
    }

    // ---------- Question 1 ----------
    println("Question 1: How many homicides occurred in each month of 2025?")
    val months = Array("January","February","March","April","May","June","July","August","September","October","November","December")
    val byMonth = entries.groupBy(_.month).view.mapValues(_.length).toMap
    (1 to 12).foreach { m =>
      val count = byMonth.getOrElse(m, 0)
      println(s"${months(m-1)}: ${count}")
    }

    // ---------- Question 2 ----------
    println("\nQuestion 2: What is the closure rate for incidents with and without surveillance cameras in 2025?")
    val total = entries.length
    val withCam = entries.count(_.hasCamera)
    val withoutCam = total - withCam
    val closedWith = entries.count(e => e.hasCamera && e.isClosed)
    val closedWithout = entries.count(e => !e.hasCamera && e.isClosed)

    def pct(n: Int, d: Int): String = if (d == 0) "0%" else f"${(n.toDouble/d*100)}%.1f%%"

    println(s"Total parsed incidents: ${total}")
    println(s"With cameras: ${withCam}, Closed with cameras: ${closedWith} (${pct(closedWith, withCam)})")
    println(s"Without cameras: ${withoutCam}, Closed without cameras: ${closedWithout} (${pct(closedWithout, withoutCam)})")
  }
}
