import org.jsoup.Jsoup
import scala.jdk.CollectionConverters._

object BmoreHomicideStats {

  case class HomicideData(
    number: String,
    dateDied: String,
    name: String,
    age: String,
    addressBlock: String,
    notes: String,
    violentHistory: String,
    surveillance: String,
    caseClosed: String
  )

  def main(args: Array[String]): Unit = {
    val url = "https://chamspage.blogspot.com/"
    val homicides = fetchTableData(url)

    // Q1: Average age of victims in 2025
    val avgAge2025 = averageAgeInYear(homicides, 2025)
    println(s"Question 1: What is the average age of victims in 2025?")
    println(f"$avgAge2025%.1f")

    // Q2: How many cases in 2025 had surveillance cameras present?
    val surveillanceCases2025 = countSurveillanceCasesInYear(homicides, 2025)
    println(s"\nQuestion 2: How many of the cases in 2025 had surveillance cameras present at the location of the crime?")
    println(surveillanceCases2025)
  }

  // Fetch and parse homicide table data
  def fetchTableData(url: String): List[HomicideData] = {
    val document = Jsoup.connect(url).get()
    val rows = document.select("table tr").asScala

    val homicides = rows.flatMap { row =>
      val cells = row.select("td").asScala.map(_.text().trim)
      if (cells.length >= 9)
        Some(HomicideData(
          number = cells(0),
          dateDied = cells(1),
          name = cells(2),
          age = cells(3),
          addressBlock = cells(4),
          notes = cells(5),
          violentHistory = cells(6),
          surveillance = cells(7),
          caseClosed = cells(8)
        ))
      else None
    }.toList

    homicides
  }

  // Extract year from date
  def extractYear(dateStr: String): Int = {
    val dateRegex = """(\d{1,2})/(\d{1,2})/(\d{2})""".r
    dateStr match {
      case dateRegex(_, _, yy) =>
        val twoDigit = yy.toInt
        if (twoDigit >= 50) 1900 + twoDigit else 2000 + twoDigit
      case _ => 0
    }
  }

  // Calculate average age
  def averageAgeInYear(homicides: List[HomicideData], year: Int): Double = {
    val victims = homicides.filter(h =>
      extractYear(h.dateDied) == year && h.age.matches("\\d+")
    )

    if (victims.nonEmpty) {
      val totalAge = victims.map(_.age.toInt).sum
      totalAge.toDouble / victims.size
    } else 0.0
  }

  // Calculate cases with surveillance cameras
  def countSurveillanceCasesInYear(homicides: List[HomicideData], year: Int): Int = {
    homicides.count(h =>
      extractYear(h.dateDied) == year &&
      h.surveillance.trim.contains("camera")
    )
  }
}
