import java.net.http.{HttpClient, HttpRequest, HttpResponse}
import java.net.URI
import scala.util.matching.Regex
import scala.util.{Try, Success, Failure}

case class Victim(name: String, age: Option[Int], district: Option[String], year: Int)

object Main {
  def main(args: Array[String]): Unit = {
    println("============================================================")
    println("Baltimore City Homicide Analysis: Insights for the Mayor's Office")
    println("============================================================\n")

    val years = Seq(2025, 2024)
    val baseUrl = "https://chamspage.blogspot.com"
    val urls = years.map(y => y -> s"$baseUrl/$y/01/${y}-baltimore-city-homicide-list.html").toMap

    val data = years.flatMap { year =>
      println(s"Fetching data for $year from: ${urls(year)}\n")
      fetchPage(urls(year)) match {
        case Some(html) =>
          val entries = parseVictims(html, year)
          println(s"  → Found ${entries.size} homicide entries for $year\n")
          entries
        case None =>
          println(s"  [!] Failed to fetch data for $year: HTTP 404 for ${urls(year)}")
          Nil
      }
    }

    println(s"Total records parsed across ${years.size} years: ${data.size}\n")

    if (data.isEmpty) {
      println("[!] No data fetched — analysis cannot proceed.")
      return
    }

    // Question 1: District with largest change 2024 → 2025
    println("------------------------------------------------------------")
    println("Question 1: Which Baltimore district had the largest spike or drop in homicides between 2024 and 2025?")
    println("------------------------------------------------------------\n")
    val byYear = data.groupBy(_.year)
    val districts2024 = byYear.getOrElse(2024, Seq()).groupBy(_.district.getOrElse("Unknown")).mapValues(_.size)
    val districts2025 = byYear.getOrElse(2025, Seq()).groupBy(_.district.getOrElse("Unknown")).mapValues(_.size)

    val merged = (districts2024.keySet ++ districts2025.keySet).map { d =>
      val y24 = districts2024.getOrElse(d, 0)
      val y25 = districts2025.getOrElse(d, 0)
      (d, y25 - y24, y24, y25)
    }

    if (merged.nonEmpty) {
      println("\n%-20s %-8s %-8s %-8s".format("District", "Δ(25-24)", "2024", "2025"))
      merged.toSeq.sortBy(-_._2).foreach { case (d, diff, y24, y25) =>
        println("%-20s %-8d %-8d %-8d".format(d, diff, y24, y25))
      }
    } else println("No comparative data available for 2024–2025.\n")

    // Question 2: Which age group is most affected?
    println("\n------------------------------------------------------------")
    println("Question 2: Which age group (0–17, 18–30, 31–50, 50+) had the most victims across 2024–2025?")
    println("------------------------------------------------------------\n")
    val grouped = data.flatMap(_.age).groupBy {
      case a if a <= 17 => "Youth (0–17)"
      case a if a <= 30 => "Young Adult (18–30)"
      case a if a <= 50 => "Adult (31–50)"
      case _            => "Senior (50+)"
    }.mapValues(_.size)

    if (grouped.nonEmpty) {
      println("%-20s %-10s".format("Age Group", "Victims"))
      grouped.toSeq.sortBy(-_._2).foreach { case (grp, count) =>
        println("%-20s %-10d".format(grp, count))
      }
      val top = grouped.maxBy(_._2)
      println(s"\nThe most affected group is: ${top._1} with ${top._2} victims.\n")
    } else println("No age data found in the records.\n")

    println("============================================================")
    println("Analysis complete — data prepared for Mayor’s Office briefing.")
    println("============================================================")
  }

  def fetchPage(url: String): Option[String] = {
    val client = HttpClient.newHttpClient()
    val request = HttpRequest.newBuilder()
      .uri(URI.create(url))
      .GET()
      .build()
    Try(client.send(request, HttpResponse.BodyHandlers.ofString())) match {
      case Success(resp) if resp.statusCode() == 200 => Some(resp.body())
      case _ => None
    }
  }

  def parseVictims(html: String, year: Int): Seq[Victim] = {
    val rowPattern: Regex = """<tr>(.*?)</tr>""".r
    val cellPattern: Regex = """<td.*?>(.*?)</td>""".r

    rowPattern.findAllMatchIn(html).flatMap { row =>
      val cells = cellPattern.findAllMatchIn(row.group(1)).map(_.group(1).trim).toList
      if (cells.nonEmpty) {
        val name = cells.headOption.getOrElse("Unknown")
        val age = cells.find(_.matches(".*\\d+.*")).flatMap(s => Try(s.replaceAll("\\D", "").toInt).toOption)
        val district = cells.find(_.toLowerCase.contains("district")).orElse(Some("Unknown"))
        Some(Victim(name, age, district, year))
      } else None
    }.toSeq
  }
}
