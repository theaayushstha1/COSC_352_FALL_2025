import java.net.URL
import java.io.BufferedReader
import java.io.InputStreamReader
import scala.util.matching.Regex
import scala.collection.mutable

object Project4 {
  val sourceUrl = "https://chamspage.blogspot.com/"

  def main(args: Array[String]): Unit = {
    val text = fetchPlainText(sourceUrl)

    // Candidate row pattern (heuristic)
    val rowPattern = """(?m)^\s*((?:\d{3}|XXX|\?\?\?))\s+([0-9/]{3,10})\s+(.+)$""".r

    val rows = rowPattern.findAllMatchIn(text).map { m =>
      val id = m.group(1).trim
      val date = m.group(2).trim
      val rest = m.group(3).trim
      val agePattern = """\b(\d{1,3})\b""".r
      val ageOpt = agePattern.findFirstIn(rest)
      val age = ageOpt.getOrElse("")

      val addrRegex = """([0-9\w' ./#-]{1,60}\b(?:Street|St\.|Avenue|Ave\.|Road|Rd\.|Lane|Ln\.|Court|Ct\.|Terrace|Terr\.|Drive|Dr\.|Highway|Hwy\.|Place|Pl\.|Boulevard|Blvd\.|Way)\b[^.,]*)""".r
      val addr = addrRegex.findFirstMatchIn(rest).map(_.group(1).trim).getOrElse {
        ageOpt match {
          case Some(a) =>
            val afterAge = rest.substring(rest.indexOf(a) + a.length).trim
            afterAge.split("\\s+").take(4).mkString(" ")
          case None => rest.split("\\s+").take(6).mkString(" ")
        }
      }

      (id, date, age, addr, rest)
    }.toList

    // QUESTION 1: Top 5 street names
    val streetCounts = mutable.Map[String, Int]().withDefaultValue(0)
    rows.foreach { case (_, _, _, addr, _) =>
      val tokens = addr.split("\\s+").filter(_.nonEmpty)
      val norm = if (tokens.length >= 2) tokens.takeRight(2).mkString(" ") else addr
      val cleaned = norm.replaceAll("""[^\w\s]""", "").trim
      if (cleaned.nonEmpty) streetCounts(cleaned) += 1
    }
    val top5 = streetCounts.toList.sortBy(-_._2).take(5)

    println("Question 1: Which address blocks / street names have the most homicides? (Top 5)")
    println()
    println(f"${"Rank"}%4s  ${"Street (normalized)"}%-30s ${"Count"}")
    println("---------------------------------------------------------")
    top5.zipWithIndex.foreach { case ((street, count), idx) =>
      println(f"${idx+1}%4d  ${street}%-30s ${count}")
    }
    println()
    println("Raw rows that contributed to those top streets:")
    println("---------------------------------------------------------")
    val topStreetsSet = top5.map(_._1).toSet
    rows.filter { case (_, _, _, addr, _) =>
      val tokens = addr.split("\\s+").filter(_.nonEmpty)
      val norm = if (tokens.length >= 2) tokens.takeRight(2).mkString(" ") else addr
      topStreetsSet.contains(norm.replaceAll("""[^\w\s]""", "").trim)
    }.foreach { case (id, date, age, addr, rest) =>
      println(s"$id | date=$date | age=$age | addrBlock=$addr")
    }

    println("\n\n")

    // QUESTION 2: Monthly homicide counts for 2025
    val datePattern = """(\d{1,2})/(\d{1,2})/(\d{2,4})""".r
    val monthCounts = mutable.Map[String, Int]().withDefaultValue(0)
    rows.foreach { case (_, dateStr, _, _, _) =>
      dateStr match {
        case datePattern(month, day, yearStr) =>
          val year = if (yearStr.length == 2) "20" + yearStr else yearStr
          if (year == "2025") {
            val key = f"$year-${month.toInt}%02d"
            monthCounts(key) += 1
          }
        case _ =>
      }
    }
    val monthsSorted = monthCounts.toList.sortBy(_._1)

    println("Question 2: Monthly homicide counts for 2025 (year-month : count)")
    println("---------------------------------------------------------")
    if (monthsSorted.isEmpty) {
      println("No 2025 dates detected in the parsed rows.")
    } else {
      monthsSorted.foreach { case (ym, c) => println(f"$ym : $c") }
    }
  }

  def fetchPlainText(urlStr: String): String = {
    val url = new URL(urlStr)
    val conn = url.openConnection()
    conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Scala Project4)")
    val in = new BufferedReader(new InputStreamReader(conn.getInputStream))
    val sb = new StringBuilder
    var line: String = null
    while ({ line = in.readLine(); line != null }) {
      val cleaned = line.replaceAll("<[^>]+>", " ")
      sb.append(cleaned).append("\n")
    }
    in.close()
    sb.toString()
  }
}
