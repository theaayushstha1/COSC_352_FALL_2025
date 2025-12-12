<<<<<<< HEAD
<<<<<<< HEAD
import java.net.{URL, HttpURLConnection}
import scala.io.Source
import scala.util.matching.Regex
import scala.util.matching.Regex.Match

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

    // Strip tags and normalize whitespace
    val noTags = "<[^>]+>".r.replaceAllIn(html, "")
    val cleanText = noTags.replaceAll("\r", "").replaceAll("\\s+", " ")

    // Pattern for 2025 entries
    case class Entry(month: Int, hasCamera: Boolean, isClosed: Boolean)

    val pattern: Regex = """(\d{3})\s+(\d{2}/\d{2}/25)\b""".r
    val cameraRe: Regex = """(?i)\b\d+\s*cameras?\b""".r
    val closedRe: Regex = """(?i)\bclosed\b""".r

    val matches: List[Match] = pattern.findAllMatchIn(cleanText).toList

    val entries = (0 until matches.length).flatMap { i =>
      val m = matches(i)
      val start = m.start
      val end = if (i + 1 < matches.length) matches(i + 1).start else cleanText.length
      val line = cleanText.substring(start, end).trim
      val date = m.group(2)
      val mm = date.split("/")(0).toInt
      val hasCam = cameraRe.findFirstIn(line).isDefined
      val isClosed = closedRe.findFirstIn(line).isDefined
      Some(Entry(mm, hasCam, isClosed))
    }

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
=======
=======
>>>>>>> 660dec1f7d4c6a4d702f8b7b7acaa447af10de39
import java.net.{URL, HttpURLConnection}
import scala.io.Source
import scala.util.matching.Regex
import scala.util.matching.Regex.Match

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

    // Strip tags and normalize whitespace
    val noTags = "<[^>]+>".r.replaceAllIn(html, "")
    val cleanText = noTags.replaceAll("\r", "").replaceAll("\\s+", " ")

    // Pattern for 2025 entries
    case class Entry(month: Int, hasCamera: Boolean, isClosed: Boolean)

    val pattern: Regex = """(\d{3})\s+(\d{2}/\d{2}/25)\b""".r
    val cameraRe: Regex = """(?i)\b\d+\s*cameras?\b""".r
    val closedRe: Regex = """(?i)\bclosed\b""".r

    val matches: List[Match] = pattern.findAllMatchIn(cleanText).toList

    val entries = (0 until matches.length).flatMap { i =>
      val m = matches(i)
      val start = m.start
      val end = if (i + 1 < matches.length) matches(i + 1).start else cleanText.length
      val line = cleanText.substring(start, end).trim
      val date = m.group(2)
      val mm = date.split("/")(0).toInt
      val hasCam = cameraRe.findFirstIn(line).isDefined
      val isClosed = closedRe.findFirstIn(line).isDefined
      Some(Entry(mm, hasCam, isClosed))
    }

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
<<<<<<< HEAD
>>>>>>> de353982c64cd1bd49756511bdff292ffbbb1fd7
=======
=======
import java.net.{URL, HttpURLConnection}
import scala.io.Source
import scala.util.matching.Regex
import scala.util.matching.Regex.Match

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

    // Strip tags and normalize whitespace
    val noTags = "<[^>]+>".r.replaceAllIn(html, "")
    val cleanText = noTags.replaceAll("\r", "").replaceAll("\\s+", " ")

    // Pattern for 2025 entries
    case class Entry(month: Int, hasCamera: Boolean, isClosed: Boolean)

    val pattern: Regex = """(\d{3})\s+(\d{2}/\d{2}/25)\b""".r
    val cameraRe: Regex = """(?i)\b\d+\s*cameras?\b""".r
    val closedRe: Regex = """(?i)\bclosed\b""".r

    val matches: List[Match] = pattern.findAllMatchIn(cleanText).toList

    val entries = (0 until matches.length).flatMap { i =>
      val m = matches(i)
      val start = m.start
      val end = if (i + 1 < matches.length) matches(i + 1).start else cleanText.length
      val line = cleanText.substring(start, end).trim
      val date = m.group(2)
      val mm = date.split("/")(0).toInt
      val hasCam = cameraRe.findFirstIn(line).isDefined
      val isClosed = closedRe.findFirstIn(line).isDefined
      Some(Entry(mm, hasCam, isClosed))
    }

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
>>>>>>> recover-lost-work
>>>>>>> 660dec1f7d4c6a4d702f8b7b7acaa447af10de39
}