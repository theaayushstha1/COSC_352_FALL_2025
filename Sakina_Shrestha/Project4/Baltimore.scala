import scala.io.Source

object Baltimore {

  // Data model aligned with visible columns on chamspage
  // |No.|Date Died|Name|Age|Address Block Found|Notes|Victim Has No Violent Criminal History *|Surveillance Camera At Intersection? **|Case Closed?|
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
      val digits = ageRaw.takeWhile(c => c.isDigit)
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
  }

  def main(args: Array[String]): Unit = {
    println()
    println("Baltimore Homicide Analytics — Project 4 (baltimore)")
    println("Data source: chamspage (public homicide list)")
    println()

    // Prefer the 2025 list page; if it fails, try root index
    val urls = List(
      "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html",
      "http://chamspage.blogspot.com"
    )

    val htmlOpt = urls.view.flatMap(u => fetch(u)).headOption
    htmlOpt match {
      case None =>
        println("Error: Unable to download homicide table from chamspage.")
      case Some(html) =>
        val homicides = parseTable(html)
        if (homicides.isEmpty) {
          println("No homicide rows were parsed; the source page structure may have changed.")
          return
        }

        println("=" * 80)
        question1_CamerasVsClosure(homicides)
        println("=" * 80)
        question2_CauseVsClosure(homicides)
        println("=" * 80)
    }
  }

  private def fetch(url: String): Option[String] = {
    try {
      Some(Source.fromURL(url, "UTF-8").mkString)
    } catch {
      case _: Throwable => None
    }
  }

  // Simple HTML table scraping using regex and cleanup with only standard library
  private def parseTable(html: String): List[Homicide] = {
    val rowRegex = """(?is)<tr[^>]*>(.*?)</tr>""".r
    val cellRegex = """(?is)<t[dh][^>]*>(.*?)</t[dh]>""".r

    // Try to find a header row that includes "Case Closed?" to lock onto the correct table
    val rows = rowRegex.findAllMatchIn(html).map(_.group(1)).toList
    val parsedRows = rows.map { r =>
      val cells = cellRegex.findAllMatchIn(r).map(_.group(1)).toList.map(cleanCell)
      cells
    }

    val headerIdx = parsedRows.indexWhere { cells =>
      val joined = cells.map(_.toLowerCase).mkString("|")
      joined.contains("date died") && joined.contains("case closed")
    }

    val dataRows =
      if (headerIdx >= 0) parsedRows.drop(headerIdx + 1)
      else parsedRows

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
    // Remove tags, decode a few basics, normalize whitespace
    val noTags = s.replaceAll("(?is)<[^>]+>", " ")
    val unescaped = noTags
      .replace("&nbsp;", " ")
      .replace("&amp;", "&")
      .replace("&lt;", "<")
      .replace("&gt;", ">")
    unescaped.replaceAll("\\s+", " ").trim
  }

  // Q1: Do cases with at least one surveillance camera at the intersection close more often?
  private def question1_CamerasVsClosure(data: List[Homicide]): Unit = {
    val withCam = data.filter(_.hasCamera)
    val withoutCam = data.filterNot(_.hasCamera)

    val closedWithCam = withCam.count(_.isClosed)
    val closedWithout = withoutCam.count(_.isClosed)

    val rateWith = pct(closedWithCam, withCam.size)
    val rateWithout = pct(closedWithout, withoutCam.size)

    val avgAgeWith = avgAge(withCam)
    val avgAgeWithout = avgAge(withoutCam)

    println("Question 1: How do case closure rates differ when a surveillance camera is present versus absent at the intersection? (and what are the average victim ages)")
    println()
    println(f"- WITH camera: count=${withCam.size} closed=$closedWithCam rate=$rateWith%.2f%% avgAge=${avgAgeWith.getOrElse("n/a")}")
    println(f"- WITHOUT camera: count=${withoutCam.size} closed=$closedWithout rate=$rateWithout%.2f%% avgAge=${avgAgeWithout.getOrElse("n/a")}")
    println(f"- Insight: Presence of cameras corresponds to a ${math.abs(rateWith - rateWithout)}%.2f%% absolute difference in closure rate.")
    println()
  }

  // Q2: How do closure rates differ by likely cause inferred from Notes (Shooting, Stabbing, Other)?
  private def question2_CauseVsClosure(data: List[Homicide]): Unit = {
    val byCause = data.groupBy(_.cause).toSeq.sortBy(_._1)
    println("Question 2: What are closure rates by likely cause inferred from Notes (Shooting vs Stabbing vs Other)?")
    println()
    byCause.foreach { case (cause, rows) =>
      val closed = rows.count(_.isClosed)
      val rate = pct(closed, rows.size)
      val avg = avgAge(rows).getOrElse("n/a")
      println(f"- $cause: count=${rows.size} closed=$closed rate=$rate%.2f%% avgAge=$avg")
    }
    val rates = byCause.map { case (c, rs) => c -> pct(rs.count(_.isClosed), rs.size) }.toMap
    val max = rates.maxByOption(_._2)
    val min = rates.minByOption(_._2)
    (max, min) match {
      case (Some(mx), Some(mn)) =>
        println()
        println(f"- Insight: Highest closure rate category = ${mx._1} at ${mx._2}%.2f%%; lowest = ${mn._1} at ${mn._2}%.2f%%.")
      case _ => ()
    }
    println()
  }

  private def pct(num: Int, den: Int): Double =
    if (den == 0) 0.0 else (num.toDouble / den.toDouble) * 100.0

  private def avgAge(rows: List[Homicide]): Option[Double] = {
    val ages = rows.flatMap(_.ageOpt)
    if (ages.nonEmpty) Some(ages.sum.toDouble / ages.size.toDouble) else None
  }
}
