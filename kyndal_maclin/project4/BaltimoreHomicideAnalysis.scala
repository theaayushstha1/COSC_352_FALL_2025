//> using scala "3.7.3"
//> using dep "org.jsoup:jsoup:1.21.2"

import org.jsoup.Jsoup
import scala.util.Try

object BaltimoreHomicideAnalysis {
  val years = List(2020, 2021, 2022, 2023, 2024, 2025)

  case class Incident(
      year: Int,
      number: Int,
      address: String,
      dateStr: String,
      name: String,
      age: Option[Int],
      raw: String,
      hasCCTV: Boolean,
      closed: Boolean
  )

  def main(args: Array[String]): Unit = {
    val incidents = years.flatMap(fetchYear)

    println("=============================================================")
    println("Question 1: Which neighborhoods have the lowest solve rates?")
    println("=============================================================\n")

    // --- Group by neighborhood and compute closure rate ---
    val byNeighborhood = incidents
      .groupBy(getNeighborhood)
      .mapValues(rows => {
        val total = rows.size
        val closed = rows.count(_.closed)
        val rate = if (total == 0) 0.0 else closed.toDouble / total * 100
        (closed, total, rate)
      })
      .toSeq
      .filter(_._1.nonEmpty)
      .sortBy(_._2._3)

    println(f"${"Neighborhood"}%-35s${"Closed"}%-10s${"Total"}%-10s${"Closure Rate"}")
    byNeighborhood.take(10).foreach { case (hood, (closed, total, rate)) =>
      println(f"${hood}%-35s$closed%-10d$total%-10d${rate}%.1f%%")
    }

    println("\n")
    println("===================================================================")
    println("Question 2: What's the relationship between victim demographics and case outcomes?")
    println("===================================================================\n")

    // --- Demographic analysis ---
    val groups = Seq(
      "Under 25" -> ((i: Incident) => i.age.exists(_ < 25)),
      "25–39" -> ((i: Incident) => i.age.exists(a => a >= 25 && a <= 39)),
      "40–59" -> ((i: Incident) => i.age.exists(a => a >= 40 && a <= 59)),
      "60+" -> ((i: Incident) => i.age.exists(_ >= 60))
    )

    println("Closure rates by victim age group:")
    println(f"${"Age Group"}%-12s${"Closed"}%-10s${"Total"}%-10s${"Closure Rate"}")
    groups.foreach { case (label, pred) =>
      val subset = incidents.filter(pred)
      val total = subset.size
      val closed = subset.count(_.closed)
      val rate = if (total == 0) 0.0 else closed.toDouble / total * 100
      println(f"${label}%-12s$closed%-10d$total%-10d${rate}%.1f%%")
    }

    println("\nClosure rates by CCTV presence:")
    val withCCTV = incidents.filter(_.hasCCTV)
    val withoutCCTV = incidents.filter(!_.hasCCTV)
    def closureRate(list: Seq[Incident]) =
      if (list.isEmpty) 0.0 else list.count(_.closed).toDouble / list.size * 100

    println(f"With CCTV:    ${withCCTV.count(_.closed)} closed / ${withCCTV.size} total = ${closureRate(withCCTV)}%.1f%%")
    println(f"Without CCTV: ${withoutCCTV.count(_.closed)} closed / ${withoutCCTV.size} total = ${closureRate(withoutCCTV)}%.1f%%\n")

    println("Closure rates by victim gender (inferred):")
    val gendered = incidents.map(i => (inferGender(i.name), i))
    val byGender = gendered.groupBy(_._1).mapValues(_.map(_._2))
    println(f"${"Gender"}%-10s${"Closed"}%-10s${"Total"}%-10s${"Closure Rate"}")
    byGender.foreach { case (g, list) =>
      val closed = list.count(_.closed)
      val total = list.size
      val rate = if (total == 0) 0.0 else closed.toDouble / total * 100
      println(f"${g}%-10s$closed%-10d$total%-10d${rate}%.1f%%")
    }

    println("\nDone.")
  }

  // ------------------- HELPER FUNCTIONS -------------------

  /** Rough heuristic to extract a neighborhood name */
  def getNeighborhood(i: Incident): String = {
    val text = i.address.toLowerCase
    val hoodRegex = "(?i)([A-Za-z\\s]+)(neighborhood|area|heights|hill|park|village|terrace|place|avenue|street|block)".r
    hoodRegex.findFirstIn(text)
      .map(_.trim.capitalize)
      .getOrElse {
        val parts = text.split("\\s+")
        if (parts.length >= 2) parts.take(2).mkString(" ").capitalize
        else text.capitalize
      }
  }

  /** Infer likely gender from name keywords */
  def inferGender(name: String): String = {
    val n = name.toLowerCase
    if (n.contains("female")) "Female"
    else if (n.contains("male")) "Male"
    else if (n.endsWith("a") || n.endsWith("e")) "Female" // heuristic
    else "Male"
  }

  def fetchYear(year: Int): List[Incident] = {
    val url = year match {
      case 2025 => "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
      case 2024 => "https://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html"
      case 2023 => "https://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html"
      case 2022 => "https://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html"
      case 2021 => "https://chamspage.blogspot.com/2021/01/2021-baltimore-city-homicides-list.html"
      case 2020 => "https://chamspage.blogspot.com/2020/01/2020-baltimore-city-homicides-list.html"
      case _    => s"https://chamspage.blogspot.com/$year/"
    }

    val doc = Jsoup.connect(url).userAgent("Mozilla/5.0").get()
    val text = doc.body().text()

    val rowRegex =
      """(?:(?<=\s)|^)(\d{3})\s(\d{2}/\d{2}/\d{2})\s([A-Za-z'.\-\s]+?)\s(\d{1,3})(?!\s*block)\s(.*?)(?=\s\d{3}\s\d{2}/\d{2}/\d{2}\s|$)""".r

    rowRegex.findAllMatchIn(text).map { m =>
      val number = Try(m.group(1).toInt).getOrElse(0)
      val dateStr = m.group(2)
      val name = m.group(3).trim
      val age = Try(m.group(4).toInt).toOption
      val raw = m.group(5).trim
      val hasCCTV =
        "(?i)\\b\\d+\\s*camera".r.findFirstIn(raw).isDefined ||
          "(?i)surveillance camera".r.findFirstIn(raw).isDefined
      val closed = "(?i)\\bclosed\\b".r.findFirstIn(raw).isDefined
      val address = raw.split("\\s{2,}").headOption.getOrElse(raw.split("\\s+").take(6).mkString(" "))
      Incident(year, number, address, dateStr, name, age, raw, hasCCTV, closed)
    }.toList
  }
}

