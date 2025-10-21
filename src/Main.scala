//> using scala "3.3.2"
//> using dep "org.jsoup:jsoup:1.16.1"

import org.jsoup.Jsoup
import scala.util.Try


object Main{
    val years = List(2020,2021,2022,2023,2024,2025)
    val cctvclosed = List(2024,2025)

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
        val incidents = (years.toSet ++ cctvclosed.toSet).toList.sorted.flatMap (fetchYear)
         println("Question 1: How many Baltimore City homicide victims aged 60 or older per year (2020–2025), and what share of that year’s total?\n")
        val byYear = incidents.filter(i => years.contains(i.year)).groupBy(_.year).toSeq.sortBy(_._1)
        println(f"${"Year"}%-6s${"60+ Count"}%-12s${"Total"}%-8s${"Share 60+"}")
        byYear.foreach { case (yr, rows) =>
        val seniors = rows.count(_.age.exists(_ >= 60))
        val total   = rows.size
        val share   = if (total == 0) 0.0 else seniors.toDouble / total * 100.0
        println(f"$yr%-6d$seniors%-12d$total%-8d${share}%.1f%%")
        }

        println("\nQuestion 2: For 2024–2025, what is the relationship between nearby CCTV (≤1 block) and case closure?\n")
        val recent = incidents.filter(i => cctvclosed.contains(i.year))
        val a = recent.count(i => i.hasCCTV && i.closed)
        val b = recent.count(i => i.hasCCTV && !i.closed)
        val c = recent.count(i => !i.hasCCTV && i.closed)
        val d = recent.count(i => !i.hasCCTV && !i.closed)


        val camTotal   = a + b
        val noCamTotal = c + d

        val camClosureRate   = if (camTotal == 0) 0.0 else a.toDouble / camTotal * 100
        val noCamClosureRate = if (noCamTotal == 0) 0.0 else c.toDouble / noCamTotal * 100

        println(f"${" " * 20}Closed   Open    Total")
        println(f"With CCTV        $a%6d $b%7d $camTotal%7d")
        println(f"No CCTV          $c%6d $d%7d $noCamTotal%7d\n")
        println(f"Closure rate with CCTV:    ${camClosureRate}%.1f%%")
        println(f"Closure rate without CCTV: ${noCamClosureRate}%.1f%%\n")
            
        }

    def fetchYear(year: Int): List[Incident] = {
        val url = year match{
            case 2025 => "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
            case 2024 => "https://chamspage.blogspot.com/2024/03/2024-baltimore-city-homicide-list.html"
            case 2023 => "https://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html"
            case 2022 => "https://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html"
            case 2021 => "https://chamspage.blogspot.com/2021/01/2021-baltimore-city-homicides-list.html"
            case 2020 => "https://chamspage.blogspot.com/2020/01/2020-baltimore-city-homicides-list.html"
            case _    => s"https://chamspage.blogspot.com/$year/"
        }

        val doc  = Jsoup.connect(url).userAgent("Mozilla/5.0").get()
        val text = doc.body().text()
        val rowRegex = "(?:(?<=\\s)|^)(\\d{3})\\s(\\d{2}/\\d{2}/\\d{2})\\s([^\\d][^\\s].*?)\\s(\\d{1,3})\\s(.*?)(?=\\s\\d{3}\\s\\d{2}/\\d{2}/\\d{2}\\s|$)".r

        val rows = rowRegex.findAllMatchIn(text).map { m =>
            val numberstr = m.group(1)
            val number  = Try(numberstr.toInt).getOrElse(0)
            val dateStr = m.group(2)
            val name    = m.group(3).trim
            val ageStr  = m.group(4)
            val raw    = m.group(5).trim
            val age     = Try(ageStr.toInt).toOption
            val hasCCTV  = "(?i)\\b\\d+\\s*camera".r.findFirstIn(raw).isDefined ||
                            "(?i)surveillance camera".r.findFirstIn(raw).isDefined
            val closed  = "(?i)\\bclosed\\b".r.findFirstIn(raw).isDefined
            val address    = raw.split("\\s{2,}").headOption

                .getOrElse(raw.split("\\s+").take(6).mkString(" "))
            Incident(year, number, address,dateStr,name, age, raw, hasCCTV, closed)
            }.toList
        rows
  }
}
