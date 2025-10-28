import java.net.URI
import java.net.http.{HttpClient, HttpRequest, HttpResponse}
import java.nio.charset.StandardCharsets
import java.io.{FileWriter, PrintWriter}
import scala.util.matching.Regex
import scala.util.Try

object Main {

  case class Record(year: Int, age: Option[Int])

  val http = HttpClient.newHttpClient()
  val years = List(2020, 2021, 2022, 2023, 2024, 2025)

  def main(args: Array[String]): Unit = {
    val formatOpt = args.find(_.startsWith("--output=")).map(_.split("=").last.toLowerCase)
    val allRecords = years.flatMap(fetchYear)
    val byYear = allRecords.groupBy(_.year).toSeq.sortBy(_._1)

    val q1 = byYear.map { case (year, recs) => (year, recs.count(r => r.age.exists(_ <= 18))) }
    val q2 = byYear.map { case (year, recs) => (year, recs.size) }

    formatOpt match {
      case Some("csv")  => writeCSV(q1, q2)
      case Some("json") => writeJSON(q1, q2)
      case _            => printStdout(q1, q2)
    }
  }

  // ---------- OUTPUT ----------
  def printStdout(q1: Seq[(Int, Int)], q2: Seq[(Int, Int)]): Unit = {
    println("Question 1: Victims age 18 or younger per year (2020–2025)\n")
    println("Year | ≤18 Victims")
    println("------------------")
    q1.foreach { case (y, c) => println(f"$y%-5d| $c%4d") }

    println("\n--------------------------------------------------\n")

    println("Question 2: Total homicide victims per year (2020–2025)\n")
    println("Year | Total Victims")
    println("--------------------")
    q2.foreach { case (y, c) => println(f"$y%-5d| $c%4d") }
  }

  def writeCSV(q1: Seq[(Int, Int)], q2: Seq[(Int, Int)]): Unit = {
    val writer = new PrintWriter(new FileWriter("output.csv"))
    writer.println("year,under18,total")
    q1.foreach { case (year, under18) =>
      val total = q2.find(_._1 == year).map(_._2).getOrElse(0)
      writer.println(s"$year,$under18,$total")
    }
    writer.close()
    println("✅ Data written to output.csv")
  }

  def writeJSON(q1: Seq[(Int, Int)], q2: Seq[(Int, Int)]): Unit = {
    val items = q1.map { case (year, under18) =>
      val total = q2.find(_._1 == year).map(_._2).getOrElse(0)
      s"""{"year":$year,"under18":$under18,"total":$total}"""
    }
    val json = "[\n  " + items.mkString(",\n  ") + "\n]"
    val writer = new PrintWriter(new FileWriter("output.json"))
    writer.println(json)
    writer.close()
    println("✅ Data written to output.json")
  }

  // ---------- DATA FETCH ----------
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
      val req = HttpRequest.newBuilder().uri(URI.create(url)).GET().build()
      val res = http.send(req, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8))
      if (res.statusCode() / 100 == 2) Some(res.body()) else None
    } catch { case _: Throwable => None }
  }

  def parseYear(html: String, year: Int): Seq[Record] = {
    val rowRe: Regex = "(?s)<tr[^>]*>(.*?)</tr>".r
    val cellRe: Regex = "(?s)<t[dh][^>]*>(.*?)</t[dh]>".r
    def clean(s: String): String = s.replaceAll("(?s)<[^>]+>", " ").replace("&nbsp;", " ").replace("&amp;", "&").replaceAll("\\s+", " ").trim
    rowRe.findAllMatchIn(html).toSeq.flatMap { row =>
      val cells = cellRe.findAllMatchIn(row.group(1)).map(c => clean(c.group(1))).toArray
      if (cells.length < 4) None else {
        val ageOpt = Try(cells(3).filter(_.isDigit).toInt).toOption
        Some(Record(year, ageOpt))
      }
    }.drop(1)
  }
}
