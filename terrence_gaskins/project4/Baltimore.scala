import scala.io.Source

object Baltimore {

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
        question1_StabbingsIn2024(homicides)
        println("=" * 80)
        question2_AvenueCases(homicides)
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
    val noTags = s.replaceAll("(?is)<[^>]+>", " ")
    val unescaped = noTags
      .replace("&nbsp;", " ")
      .replace("&amp;", "&")
      .replace("&lt;", "<")
      .replace("&gt;", ">")
    unescaped.replaceAll("\\s+", " ").trim
  }

  // Question 1: How many 2024 cases involved stabbing?
  private def question1_StabbingsIn2024(data: List[Homicide]): Unit = {
    val stabbingCases = data.filter { h =>
      h.dateDied.contains("2024") && h.cause == "Stabbing"
    }
    println("Question 1: How many 2024 cases involved stabbing?")
    println()
    stabbingCases.foreach { h =>
      println(f"- ${h.dateDied} | ${h.name} | ${h.notes}")
    }
    println(f"- Total stabbing cases in 2024: ${stabbingCases.size}")
    println()
  }

  // Question 2: Which cases have 'Avenue' in the street name?
  private def question2_AvenueCases(data: List[Homicide]): Unit = {
    val avenueCases = data.filter(_.address.toLowerCase.contains("avenue"))
    println("Question 2: Which cases have 'Avenue' in the street name?")
    println()
    avenueCases.foreach { h =>
      println(f"- ${h.dateDied} | ${h.name} | ${h.address}")
    }
    println(f"- Total cases with 'Avenue': ${avenueCases.size}")
    println()
  }
}
