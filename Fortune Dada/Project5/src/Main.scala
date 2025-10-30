//> using scala "3.3.2"
//> using dep "org.jsoup:jsoup:1.16.1"
//> using dep "com.lihaoyi:ujson_3:4.0.2"

import org.jsoup.Jsoup
import scala.util.{Try, Success, Failure}
import java.nio.file.{Files, Paths}
import java.nio.charset.StandardCharsets

object Main {
  val years = List(2020, 2021, 2022, 2023, 2024, 2025)
  val cctvclosed = List(2024, 2025)

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

  private def write(path: String, s: String): Unit =
    Files.write(Paths.get(path), s.getBytes(StandardCharsets.UTF_8))

  private def argOutput(args: Array[String]): String = {
    val fmt = args.headOption.getOrElse("")
    if (fmt.startsWith("--output=")) fmt.drop(9).toLowerCase else "stdout"
  }

  def main(args: Array[String]): Unit = {
    val outMode = argOutput(args)
    val incidents = (years.toSet ++ cctvclosed.toSet).toList.sorted.flatMap(fetchYear)
    val byYear = incidents.filter(i => years.contains(i.year)).groupBy(_.year).toSeq.sortBy(_._1)
    case class Q1Row(year: Int, seniors: Int, total: Int, sharePct: Double)
    val q1Rows: Seq[Q1Row] = byYear.map { case (yr, rows) =>
      val seniors = rows.count(_.age.exists(_ >= 60))
      val total = rows.size
      val share = if (total == 0) 0.0 else seniors.toDouble / total * 100.0
      Q1Row(yr, seniors, total, math.round(share * 10.0) / 10.0)
    }

    val recent = incidents.filter(i => cctvclosed.contains(i.year))
    val a = recent.count(i => i.hasCCTV && i.closed)
    val b = recent.count(i => i.hasCCTV && !i.closed)
    val c = recent.count(i => !i.hasCCTV && i.closed)
    val d = recent.count(i => !i.hasCCTV && !i.closed)
    val camTotal = a + b
    val noCamTotal = c + d
    val camRate = if (camTotal == 0) 0.0 else a.toDouble / camTotal * 100.0
    val noCamRate = if (noCamTotal == 0) 0.0 else c.toDouble / noCamTotal * 100.0

    outMode match {
      case "stdout" =>
        println("Question 1: How many Baltimore City homicide victims aged 60 or older per year (2020–2025), and what share of that year’s total?\n")
        println(f"${"Year"}%-6s${"60+ Count"}%-12s${"Total"}%-8s${"Share 60+"}")
        q1Rows.foreach(r => println(f"${r.year}%-6d${r.seniors}%-12d${r.total}%-8d${r.sharePct}%.1f%%"))
        println("\nQuestion 2: For 2024–2025, what is the relationship between nearby CCTV (≤1 block) and case closure?\n")
        println(f"${" " * 20}Closed   Open    Total")
        println(f"With CCTV        $a%6d $b%7d $camTotal%7d")
        println(f"No CCTV          $c%6d $d%7d $noCamTotal%7d\n")
        println(f"Closure rate with CCTV:    ${camRate}%.1f%%")
        println(f"Closure rate without CCTV: ${noCamRate}%.1f%%\n")

      case "csv" =>
        Files.createDirectories(Paths.get("/out"))
        val q1Csv =
          "year,sixty_plus_count,total,share_pct\n" +
            q1Rows.map(r => s"${r.year},${r.seniors},${r.total},${r.sharePct}").mkString("\n")
        write("/out/q1.csv", q1Csv)
        val q2Csv =
          "group,closed,open,total,closure_rate_pct\n" +
            s"with_cctv,$a,$b,$camTotal,${"%.1f".format(camRate)}\n" +
            s"no_cctv,$c,$d,$noCamTotal,${"%.1f".format(noCamRate)}\n"
        write("/out/q2.csv", q2Csv)
        println("Wrote /out/q1.csv and /out/q2.csv")

      case "json" =>
        Files.createDirectories(Paths.get("/out"))
        val q1Json = ujson.Arr.from(
          q1Rows.map(r => ujson.Obj(
            "year" -> r.year,
            "sixty_plus_count" -> r.seniors,
            "total" -> r.total,
            "share_pct" -> r.sharePct
          ))
        )
        write("/out/q1.json", ujson.write(q1Json, indent = 2))
        val q2Json = ujson.Obj(
          "with_cctv" -> ujson.Obj(
            "closed" -> a, "open" -> b, "total" -> camTotal,
            "closure_rate_pct" -> BigDecimal(camRate).setScale(1, BigDecimal.RoundingMode.HALF_UP).toDouble
          ),
          "no_cctv" -> ujson.Obj(
            "closed" -> c, "open" -> d, "total" -> noCamTotal,
            "closure_rate_pct" -> BigDecimal(noCamRate).setScale(1, BigDecimal.RoundingMode.HALF_UP).toDouble
          )
        )
        write("/out/q2.json", ujson.write(q2Json, indent = 2))
        println("Wrote /out/q1.json and /out/q2.json")

      case other =>
        System.err.println(s"Unknown output mode '$other'. Use --output=csv | --output=json or omit for stdout.")
        sys.exit(2)
    }
  }

  private def urlFor(year: Int): String = year match {
    case 2025 => "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
    case 2024 => "https://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html"
    case 2023 => "https://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html"
    case 2022 => "https://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html"
    case 2021 => "https://chamspage.blogspot.com/2021/01/2021-baltimore-city-homicides-list.html"
    case 2020 => "https://chamspage.blogspot.com/2020/01/2020-baltimore-city-homicides-list.html"
    case y    => s"https://chamspage.blogspot.com/$y/"
  }

  private def fetchYear(year: Int): List[Incident] = {
    val url = urlFor(year)

    def tryFetch(attempt: Int): Try[String] = Try {
      Jsoup
        .connect(url)
        .userAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome Safari")
        .referrer("https://www.google.com/")
        .timeout(30000)
        .followRedirects(true)
        .get()
        .body()
        .text()
    } recoverWith {
      case e if attempt < 3 =>
        Thread.sleep(1000L * attempt)
        tryFetch(attempt + 1)
    }

    val text = tryFetch(1) match {
      case Success(t) => t
      case Failure(e) =>
        System.err.println(s"[WARN] Failed to fetch $year from $url: ${e.getClass.getSimpleName}: ${e.getMessage}")
        ""
    }

    val rowRegex = "(?:(?<=\\s)|^)(\\d{3})\\s(\\d{2}/\\d{2}/\\d{2})\\s([^\\d][^\\s].*?)\\s(\\d{1,3})\\s(.*?)(?=\\s\\d{3}\\s\\d{2}/\\d{2}/\\d{2}\\s|$)".r

    rowRegex.findAllMatchIn(text).map { m =>
      val number = m.group(1).toIntOption.getOrElse(0)
      val dateStr = m.group(2)
      val name = m.group(3).trim
      val age = m.group(4).toIntOption
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
