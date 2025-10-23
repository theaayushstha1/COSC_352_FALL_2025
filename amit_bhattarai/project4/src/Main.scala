import java.net.URI
import java.net.http.{HttpClient, HttpRequest, HttpResponse}
import java.nio.charset.StandardCharsets
import scala.util.matching.Regex
import scala.util.Try

object Main {

  case class Record(year: Int, age: Option[Int])

  val http = HttpClient.newHttpClient()
  val years = List(2020, 2021, 2022, 2023, 2024, 2025)

  def main(args: Array[String]): Unit = {
    val allRecords = years.flatMap(fetchYear)

    // ---------- Question 1 ----------
    println("Question 1: How many homicide victims were age 18 or younger in each year (2020–2025)?\n")
    val byYear = allRecords.groupBy(_.year).toSeq.sortBy(_._1)
    println("Year | ≤18 Victims")
    println("------------------")
    byYear.foreach { case (year, recs) =>
      val under18 = recs.count(r => r.age.exists(_ <= 18))
      println(f"$year%-5d| $under18%4d")
    }

    println("\n--------------------------------------------------\n")

    // ---------- Question 2 ----------
    println("Question 2: Total number of homicide victims in each year (2020–2025)?\n")
    println("Year | Total Victims")
    println("--------------------")
    byYear.foreach { case (year, recs) =>
      println(f"$year%-5d| ${recs.size}%4d")
    }
  }

  // fetch each year's homicide list from chamspage
  def fetchYear(year: Int): Seq[Record] = {
    val urls = Seq(
      s"https://chamspage.blogspot.com/$year/01/${year}-baltimore-city-homicides-list.html",
      s"https://chamspage.blogspot.com/$year/01/${year}-baltimore-city-homicide-list.html",
      s"https://chamspage.blogspot.com/$year/01/${year}-baltimore-city-homicides-list-and-map.html"
    )

    val htmlOpt = urls.view.map(fetch).collectFirst { case Some(h) => h }
    htmlOpt.map(parseYear(_, year)).getOrElse(Seq.empty)
  }

  def fetch(url: String): Option[String] = {
    try {
      val req = HttpRequest.newBuilder()
        .uri(URI.create(url))
        .GET()
        .build()
      val res = http.send(req, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8))
      if (res.statusCode() / 100 == 2) Some(res.body()) else None
    } catch {
      case _: Throwable => None
    }
  }

  def parseYear(html: String, year: Int): Seq[Record] = {
    val rowRe: Regex = "(?s)<tr[^>]*>(.*?)</tr>".r
    val cellRe: Regex = "(?s)<t[dh][^>]*>(.*?)</t[dh]>".r

    def clean(s: String): String =
      s.replaceAll("(?s)<[^>]+>", " ")
        .replace("&nbsp;", " ")
        .replace("&amp;", "&")
        .replaceAll("\\s+", " ")
        .trim

    rowRe.findAllMatchIn(html).toSeq.flatMap { rowMatch =>
      val cells = cellRe.findAllMatchIn(rowMatch.group(1)).map(m => clean(m.group(1))).toArray
      if (cells.length < 4) None
      else {
        val ageOpt = Try(cells(3).filter(_.isDigit).toInt).toOption
        Some(Record(year, ageOpt))
      }
    }.drop(1) // skip header
  }
}
