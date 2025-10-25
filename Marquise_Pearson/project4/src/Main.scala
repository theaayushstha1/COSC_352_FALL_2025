import java.time._
import java.util.Locale
import scala.io.Source
import java.net.{HttpURLConnection, URL}
import scala.util.Try
import scala.util.matching.Regex

object Main {
  // Provide Ordering for LocalDate (needed for sortBy on older Scala)
  implicit val localDateOrdering: Ordering[LocalDate] =
    Ordering.by[LocalDate, Long](_.toEpochDay)

  // -----------------------------
  // Config
  // -----------------------------
  val Root = "https://chamspage.blogspot.com/"
  val TargetYear = 2025

  // -----------------------------
  // HTTP (stdlib only)
  // -----------------------------
  def fetch(url: String, connectTimeoutMs: Int = 15000, readTimeoutMs: Int = 20000): String = {
    val conn = new URL(url).openConnection().asInstanceOf[HttpURLConnection]
    conn.setRequestMethod("GET")
    conn.setConnectTimeout(connectTimeoutMs)
    conn.setReadTimeout(readTimeoutMs)
    conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Project4-Scala/2.0)")
    val in = conn.getInputStream
    val body = try {
      val src = Source.fromInputStream(in, "UTF-8")
      try src.mkString
      finally src.close()
    } finally in.close()
    body
  }

  // -----------------------------
  // HTML helpers
  // -----------------------------
  private val tagRe: Regex = "(?s)<[^>]+>".r
  private val linkRe: Regex = """(?is)<a\s+[^>]*href=["']([^"']+)["'][^>]*>(.*?)</a>""".r

  def stripHtml(s: String): String =
    tagRe.replaceAllIn(s, " ").replaceAll("[\\s\\u00A0]+", " ").trim

  // Find the specific year page (anchor text contains homicide + year)
  def findYearPageUrl(rootHtml: String, year: Int): Option[String] = {
    val items = linkRe.findAllMatchIn(rootHtml).flatMap { m =>
      val href = m.group(1)
      val text = stripHtml(m.group(2)).toLowerCase(Locale.US)
      val hasYear = text.contains(year.toString)
      val hasHomicide = text.contains("homicide")
      if (hasYear && hasHomicide) {
        val abs = if (href.startsWith("http")) href
        else (Root.stripSuffix("/") + "/" + href.stripPrefix("/"))
        Some(abs)
      } else None
    }.toList
    items.headOption
  }

  // -----------------------------
  // Parsing homicide entries
  // -----------------------------
  private val monthNames = List(
    "January","February","March","April","May","June",
    "July","August","September","October","November","December"
  )
  private val monthWord = monthNames.mkString("|")
  private val longDateRe: Regex = (s"(?i)\\b($monthWord)\\s+([0-3]?\\d),\\s*(20\\d{2})\\b").r
  private val shortDateRe: Regex = """\b([01]?\d)/([0-3]?\d)/(20\d{2})\b""".r

  private val ageRe: Regex =
    """(?i)\b(?:age\s*:?|)(\d{1,2})\s*(?:years?\s*old|yo|y/o|year-?old)?\b""".r

  private val genderRe: Regex = """(?i)\b(male|female|man|woman|boy|girl)\b""".r

  case class Homicide(date: LocalDate, age: Option[Int], gender: String) // M/F/U

  def normalizeGender(text: String): String = {
    val t = text.toLowerCase(Locale.US)
    if (t.contains("female") || t.contains("woman") || t.contains("girl")) "F"
    else if (t.contains("male") || t.contains("man") || t.contains("boy")) "M"
    else "U"
  }

  def detectDate(line: String): Option[LocalDate] = {
    longDateRe.findFirstMatchIn(line) match {
      case Some(m) =>
        val month = monthNames.indexWhere(_.equalsIgnoreCase(m.group(1))) + 1
        val day   = m.group(2).toInt
        val year  = m.group(3).toInt
        Try(LocalDate.of(year, month, day)).toOption
      case None =>
        shortDateRe.findFirstMatchIn(line).flatMap { m =>
          val month = m.group(1).toInt
          val day   = m.group(2).toInt
          val year  = m.group(3).toInt
          Try(LocalDate.of(year, month, day)).toOption
        }
    }
  }

  def parseYearPage(html: String, year: Int): Seq[Homicide] = {
    val text = stripHtml(html)
    val indices = (longDateRe.findAllMatchIn(text).map(_.start) ++
                   shortDateRe.findAllMatchIn(text).map(_.start)).toList.sorted
    val blocks: Seq[String] =
      if (indices.isEmpty) Seq(text)
      else indices.zip(indices.drop(1) :+ text.length).map { case (s,e) => text.substring(s, e) }

    blocks.flatMap { block =>
      val dateOpt = detectDate(block)
      dateOpt.filter(_.getYear == year).map { d =>
        val ageOpt = ageRe.findFirstMatchIn(block).flatMap(m => Try(m.group(1).toInt).toOption)
        val gGuess = genderRe.findAllIn(block).mkString(" ")
        val gender = if (gGuess.nonEmpty) normalizeGender(gGuess) else "U"
        Homicide(d, ageOpt, gender)
      }
    }.sortBy(_.date) // uses the implicit ordering above
  }

  // -----------------------------
  // MAIN
  // -----------------------------
  def main(args: Array[String]): Unit = {
    // 1) Find the 2025 archive page
    val rootHtml = fetch(Root)
    val yearUrl = findYearPageUrl(rootHtml, TargetYear).getOrElse {
      System.err.println(s"Could not find a homicide archive link for $TargetYear on $Root")
      System.exit(2); ""
    }

    // 2) Fetch & parse 2025 records
    val html2025 = fetch(yearUrl)
    val records = parseYearPage(html2025, TargetYear)
    if (records.isEmpty) {
      System.err.println(s"No homicide entries parsed for $TargetYear. Site format may have changed.")
      System.exit(3)
    }

    // ================
    // QUESTION 1 (A):
    // ================
    // For 2025, monthly counts and deviation from cumulative average up to that month.
    // (Avoid .view/.mapValues to stay compatible with older Scala)
    val byMonthCounts: Map[Int, Int] =
      records.groupBy(_.date.getMonthValue).map { case (m, recs) => m -> recs.size }

    val monthsPresent = byMonthCounts.keys.toList.sorted
    var runningTotal = 0
    val cumulativeRows = monthsPresent.map { m =>
      val count = byMonthCounts.getOrElse(m, 0)
      runningTotal += count
      val monthsSoFar = monthsPresent.count(_ <= m)
      val avgToDate = if (monthsSoFar > 0) runningTotal.toDouble / monthsSoFar else 0.0
      val diff = count - avgToDate
      val pctDiff =
        if (avgToDate == 0.0) "NA"
        else f"${(count/avgToDate - 1.0) * 100.0}%.1f%%"
      (f"$TargetYear%04d-$m%02d", count, avgToDate, diff, pctDiff)
    }

    // ================
    // QUESTION 2 (B):
    // ================
    // 18–24 share by gender among records with KNOWN age and gender (M/F).
    val known = records.filter(r => r.age.isDefined && (r.gender == "M" || r.gender == "F"))
    case class AG(gender: String, total: Int, youngCount: Int) {
      def pct: Double = if (total == 0) 0.0 else youngCount.toDouble / total.toDouble * 100.0
    }

    val grouped: Map[String, AG] = known.groupBy(_.gender).map { case (g, recs) =>
      val tot = recs.size
      val young = recs.count(r => r.age.exists(a => a >= 18 && a <= 24))
      g -> AG(g, tot, young)
    }

    val male = grouped.getOrElse("M", AG("M", 0, 0))
    val female = grouped.getOrElse("F", AG("F", 0, 0))

    val ratioTxt =
      if (female.pct == 0.0 && male.pct > 0.0) "Infinity"
      else if (female.pct == 0.0 && male.pct == 0.0) "N/A"
      else f"${male.pct / math.max(female.pct, 1e-9)}%.2f×"

    // -----------------------
    // PRINT ANSWERS
    // -----------------------
    println(s"Question 1: For $TargetYear, how many homicide victims occurred in each month so far, and how much do they deviate (absolute & percentage) from the cumulative intra-year average up to that month?")
    println("Month\tCount\tAvgToDate\tDiff\tPercentDiff")
    cumulativeRows.foreach { case (label, count, avg, diff, pct) =>
      val avgStr = f"$avg%.2f"
      val diffStr = (if (diff >= 0) "+" else "") + f"$diff%.2f"
      println(s"$label\t$count\t$avgStr\t$diffStr\t$pct")
    }
    println()

    println(s"Question 2: Of $TargetYear homicide victims with known age & gender, what share are ages 18–24 in each gender group, and what is the male:female share ratio?")
    println("Gender\tTotalKnown\tAge18–24\tPercent18–24")
    println(f"Male\t${male.total}\t${male.youngCount}\t${male.pct}%.1f%%")
    println(f"Female\t${female.total}\t${female.youngCount}\t${female.pct}%.1f%%")
    println(s"Ratio (male:female) based on 18–24 share = $ratioTxt")
  }
}
