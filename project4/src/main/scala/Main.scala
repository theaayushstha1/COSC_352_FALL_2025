import java.net.http._
import java.net.URI
import scala.util.{Try, Success, Failure}
import scala.util.matching.Regex
import java.time.LocalDate

case class Homicide(year: Int, district: String, age: Option[Int], date: Option[LocalDate])

object Main extends App {
  println("============================================================")
  println("Baltimore City Homicide Analysis: Insights for the Mayor's Office")
  println("============================================================\n")

  val client = HttpClient.newHttpClient()
  val years = Seq(2025, 2024) // Only 2025 and 2024 for valid data

  var allRecords = List[Homicide]()

  years.foreach { year =>
    val url = s"https://chamspage.blogspot.com/$year/01/$year-baltimore-city-homicide-list.html"
    println(s"Fetching data for $year from: $url\n")

    fetch(url) match {
      case Success(html) =>
        val parsed = parseHomicides(html, year)
        println(s"  → Found ${parsed.size} homicide entries for $year\n")
        allRecords ++= parsed
      case Failure(ex) =>
        println(s"  [!] Failed to fetch data for $year: ${ex.getMessage}")
    }
  }

  println(s"Total records parsed across ${years.size} years: ${allRecords.size}\n")

  if (allRecords.isEmpty) {
    println("[!] Live data unavailable — using sample dataset for demonstration.\n")
    allRecords = List(
      Homicide(2025, "Southeast", Some(32), Some(LocalDate.parse("2025-03-21"))),
      Homicide(2025, "Northeast", Some(40), Some(LocalDate.parse("2025-06-10"))),
      Homicide(2024, "Western", Some(29), Some(LocalDate.parse("2024-09-12"))),
      Homicide(2024, "Southeast", Some(45), Some(LocalDate.parse("2024-02-11")))
    )
  }

  // ----------------------------
  // Question 1: District Spike/Drop between 2024–2025
  // ----------------------------
  println("------------------------------------------------------------")
  println("Question 1: Which Baltimore district had the largest spike or drop in homicides between 2024 and 2025?")
  println("------------------------------------------------------------")

  val byYearAndDistrict = allRecords.groupBy(r => (r.year, r.district)).view.mapValues(_.size).toMap
  val districts = allRecords.map(_.district).distinct

  val deltas = districts.flatMap { d =>
    val y24 = byYearAndDistrict.getOrElse((2024, d), 0)
    val y25 = byYearAndDistrict.getOrElse((2025, d), 0)
    if (y24 + y25 > 0) Some((d, y25 - y24, y24, y25)) else None
  }.sortBy(t => -math.abs(t._2))

  if (deltas.nonEmpty) {
    println("\n%-20s %-8s %-8s %-8s".format("District", "Δ(25-24)", "2024", "2025"))
    deltas.foreach { case (d, diff, y24, y25) =>
      println("%-20s %-8d %-8d %-8d".format(d, diff, y24, y25))
    }
  } else println("No comparative data available for 2024–2025.")

  // ----------------------------
  // Question 2: Average Victim Age per District
  // ----------------------------
  println("\n------------------------------------------------------------")
  println("Question 2: What was the average victim age per district in 2024–2025, and which district had the highest average age?")
  println("------------------------------------------------------------")

  val byDistrictAge = allRecords
    .filter(_.age.isDefined)
    .groupBy(_.district)
    .view
    .mapValues(vs => vs.flatMap(_.age).sum.toDouble / vs.size)
    .toList
    .sortBy(-_._2)

  if (byDistrictAge.nonEmpty) {
    println("\n%-20s %-10s".format("District", "Avg Age"))
    byDistrictAge.foreach { case (d, avg) =>
      println("%-20s %-10.1f".format(d, avg))
    }
    val (topDistrict, topAvg) = byDistrictAge.head
    println(f"\nThe district with the highest average victim age is $topDistrict, with an average of $topAvg%.1f years.")
  } else println("No age data found in the records.")

  println("\n============================================================")
  println("Analysis complete — data prepared for Mayor’s Office briefing.")
  println("============================================================")

  // ----------------------------
  // Utility Methods
  // ----------------------------
  def fetch(url: String): Try[String] = Try {
    val req = HttpRequest.newBuilder()
      .uri(URI.create(url))
      .header("User-Agent", "Mozilla/5.0 (Project4Bot)")
      .GET().build()
    val res = client.send(req, HttpResponse.BodyHandlers.ofString())
    if (res.statusCode() / 100 == 2) res.body()
    else throw new RuntimeException(s"HTTP ${res.statusCode()} for $url")
  }

  def parseHomicides(html: String, year: Int): List[Homicide] = {
    val rowRegex = new Regex("""<tr>(.*?)</tr>""", "row")
    val districtRegex = new Regex("""([A-Z][A-Za-z ]+District)""")
    val ageRegex = new Regex("""[MF]/(\d{1,2})""")
    val dateRegex = new Regex("""(\w+ \d{1,2}, \d{4})""")

    rowRegex.findAllMatchIn(html).flatMap { m =>
      val row = m.group("row")
      val district = districtRegex.findFirstIn(row).getOrElse("Unknown")
      val ageOpt = ageRegex.findFirstMatchIn(row).map(_.group(1).toInt)
      val dateOpt = dateRegex.findFirstIn(row).flatMap(parseDate)
      Some(Homicide(year, district, ageOpt, dateOpt))
    }.toList
  }

  def parseDate(s: String): Option[LocalDate] =
    Try(LocalDate.parse(s, java.time.format.DateTimeFormatter.ofPattern("MMMM d, yyyy"))).toOption
}
