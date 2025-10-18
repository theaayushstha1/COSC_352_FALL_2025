import org.jsoup.Jsoup
import scala.util.matching.Regex
import scala.jdk.CollectionConverters._

object BmoreHomicideStats {

  case class HomicideData(year: Int, victimAge: Option[Int], surveillance: Boolean)

  def main(args: Array[String]): Unit = {
    val url = "https://chamspage.blogspot.com/"
    val data = fetchData(url)

    val homicides = parseHomicideData(data)

    // Q1: What is the average age of victims in 2025?
    val avgAge2025 = averageAgeInYear(homicides, 2025)
    println(s"Question 1: What is the average age of victims in 2025?")
    println(avgAge2025)

    // Q2: How many cases in 2025 had surveillance cameras present?
    val surveillanceCases2025 = countSurveillanceCasesInYear(homicides, 2025)
    println(s"\nQuestion 2: How many of the cases in 2025 had surveillance cameras present?")
    println(surveillanceCases2025)
  }

  // Fetch URL data
  def fetchData(url: String): String = {
    // Fetch HTML content from the provided URL
    val document = Jsoup.connect(url).get()
    val body = document.body()
   
    println(document.body().text())

    // Extract URL data
    val tableRows = document.body().select("table tr") 
    tableRows.eachText().asScala.mkString("\n")  
  }

  // Parse HTML data 
  def parseHomicideData(data: String): List[HomicideData] = {
    // Extract relevant data from the HTML content (assuming CSV-like format in each row)
    val dataRegex = new Regex("""(\d{4}),(\d{1,3}),\s*(yes|no)""", "year", "age", "surveillance")
    
    // Match data 
    dataRegex.findAllMatchIn(data).collect {
      case m if m.group("year").nonEmpty && m.group("age").nonEmpty =>
        val year = m.group("year").toInt
        val age = if (m.group("age").nonEmpty) Some(m.group("age").toInt) else None
        val surveillance = m.group("surveillance").toLowerCase == "yes"
        HomicideData(year, age, surveillance)
    }.toList
  }

  // Calculate average age of victims in a given year
  def averageAgeInYear(homicides: List[HomicideData], year: Int): Double = {
    val victims = homicides.filter(h => h.year == year && h.victimAge.isDefined)
    if (victims.nonEmpty) {
      val totalAge = victims.flatMap(_.victimAge).sum
      totalAge.toDouble / victims.size
    } else {
      0.0
    }
  }

  // Count how many homicide cases had surveillance cameras present in a given year
  def countSurveillanceCasesInYear(homicides: List[HomicideData], year: Int): Int = {
    homicides.count(h => h.year == year && h.surveillance)
  }
}