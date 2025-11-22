import scala.io.Source
import scala.util.{Try, Success, Failure}
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import scala.util.matching.Regex

object BaltimoreHomicideAnalysis {
  
  // Case class to represent a homicide record
  case class Homicide(
    date: LocalDate,
    time: String,
    race: String,
    sex: String,
    age: Int,
    location: String,
    district: String,
    disposition: String,
    weapon: String
  )
  
  def main(args: Array[String]): Unit = {
    println("-" * 80)
    println("Balitmore City Homicide Analsis")
    println("-" * 80)
    println()
    
    // Fetch and parse data
    val homicides = fetchAndParseData()
    
    if (homicides.isEmpty) {
      println("ERROR: No data could be retrieved.")
      System.exit(1)
    }
    
    println(s"Total Records Analyzed: ${homicides.size}")
    println()
    
    // Answer Question 1
    answerQuestion1(homicides)
    println()
    
    // Answer Question 2
    answerQuestion2(homicides)
    println()
    
    println("=" * 80)
  }
  
  /**
   * Fetch data from the Baltimore homicide statistics page
   */
  def fetchAndParseData(): List[Homicide] = {
    val url = "https://chamspage.blogspot.com/"
    
    println("Fetching data from source...")
    
    Try {
      val html = Source.fromURL(url, "UTF-8").mkString
      println("Data fetched successfully. Parsing...")
      
      val homicides = parseHtmlTable(html)
      println(s"Parsed ${homicides.size} records")
      
      homicides
    } match {
      case Success(data) if data.nonEmpty => data
      case _ => 
        println("Using sample data for demonstration...")
        getSampleData()
    }
  }
  
  /**
   * Parse HTML table into Homicide objects
   */
  def parseHtmlTable(html: String): List[Homicide] = {
    val tables = extractTables(html)
    
    if (tables.isEmpty) {
      return List.empty
    }
    
    val homicideTable = tables.maxBy(_.size)
    homicideTable.flatMap(parseRow)
  }
  
  /**
   * Extract all tables from HTML
   */
  def extractTables(html: String): List[List[List[String]]] = {
    val cleanHtml = html.replaceAll("\\s+", " ")
    val tableRegex: Regex = "(?s)<table[^>]*>(.*?)</table>".r
    
    tableRegex.findAllMatchIn(cleanHtml).map { tableMatch =>
      val tableContent = tableMatch.group(1)
      extractRows(tableContent)
    }.toList
  }
  
  /**
   * Extract rows from table HTML
   */
  def extractRows(tableHtml: String): List[List[String]] = {
    val rowRegex: Regex = "(?s)<tr[^>]*>(.*?)</tr>".r
    
    rowRegex.findAllMatchIn(tableHtml).map { rowMatch =>
      val rowContent = rowMatch.group(1)
      extractCells(rowContent)
    }.toList.filter(_.nonEmpty)
  }
  
  /**
   * Extract cells from row HTML
   */
  def extractCells(rowHtml: String): List[String] = {
    val cellRegex: Regex = "(?s)<t[dh][^>]*>(.*?)</t[dh]>".r
    
    cellRegex.findAllMatchIn(rowHtml).map { cellMatch =>
      val cellContent = cellMatch.group(1)
      cleanCellText(cellContent)
    }.toList
  }
  
  /**
   * Clean cell text
   */
  def cleanCellText(text: String): String = {
    val noTags = text.replaceAll("<[^>]*>", "")
    val decoded = noTags
      .replaceAll("&nbsp;", " ")
      .replaceAll("&amp;", "&")
      .replaceAll("&lt;", "<")
      .replaceAll("&gt;", ">")
      .replaceAll("&quot;", "\"")
      .replaceAll("&#39;", "'")
    
    decoded.replaceAll("\\s+", " ").trim
  }
  
  /**
   * Parse a row into a Homicide object
   */
  def parseRow(cells: List[String]): Option[Homicide] = {
    if (cells.size < 9) return None
    if (!cells(0).matches(".*\\d{1,2}/\\d{1,2}/\\d{4}.*")) return None
    
    Try {
      val dateFormatter = DateTimeFormatter.ofPattern("MM/dd/yyyy")
      val dateStr = cells(0).replaceAll("[^0-9/]", "").trim
      val date = LocalDate.parse(dateStr, dateFormatter)
      val age = parseAge(cells(4))
      
      Homicide(
        date = date,
        time = cells(1).trim,
        race = cells(2).trim,
        sex = cells(3).trim,
        age = age,
        location = cells(5).trim,
        district = cells(6).trim,
        disposition = cells(7).trim,
        weapon = cells(8).trim
      )
    }.toOption
  }
  
  /**
   * Parse age from string
   */
  def parseAge(ageStr: String): Int = {
    val digits = ageStr.replaceAll("[^0-9]", "")
    
    if (digits.nonEmpty) {
      Try(digits.toInt).getOrElse(0)
    } else {
      ageStr.toLowerCase match {
        case s if s.contains("infant") || s.contains("baby") => 0
        case s if s.contains("child") => 10
        case s if s.contains("teen") => 16
        case _ => 0
      }
    }
  }
  
  /**
   * QUESTION 1: Deadliest months for homicides
   */
  def answerQuestion1(homicides: List[Homicide]): Unit = {
    println("QUESTION 1: What are the deadliest months for homicides in Baltimore?")
    println("-" * 80)
    
    val byMonth = homicides
      .groupBy(h => h.date.getMonthValue)
      .view
      .mapValues(_.size)
      .toSeq
      .sortBy(_._1)
    
    val monthNames = Map(
      1 -> "January", 2 -> "February", 3 -> "March", 4 -> "April",
      5 -> "May", 6 -> "June", 7 -> "July", 8 -> "August",
      9 -> "September", 10 -> "October", 11 -> "November", 12 -> "December"
    )
    
    println(f"${"Month"}%-15s ${"Homicides"}%10s ${"Percentage"}%12s")
    println("-" * 80)
    
    val total = homicides.size.toDouble
    
    byMonth.foreach { case (month, count) =>
      val percentage = (count / total) * 100
      println(f"${monthNames(month)}%-15s ${count}%10d ${percentage}%11.2f%%")
    }
    
    val peakMonth = byMonth.maxBy(_._2)
    val lowestMonth = byMonth.minBy(_._2)
    
    println("-" * 80)
    println(s"INSIGHT: ${monthNames(peakMonth._1)} is deadliest with ${peakMonth._2} homicides")
    println(s"         ${monthNames(lowestMonth._1)} is safest with ${lowestMonth._2} homicides")
  }
  
  /**
   * QUESTION 2: Weapon types with lowest clearance rates
   */
  def answerQuestion2(homicides: List[Homicide]): Unit = {
    println("QUESTION 2: Which types of homicide cases are hardest to solve?")
    println("-" * 80)
    
    val byWeapon = homicides
      .groupBy(_.weapon)
      .map { case (weapon, cases) =>
        val total = cases.size
        val closed = cases.count(c => 
          c.disposition.toLowerCase.contains("closed") || 
          c.disposition.toLowerCase.contains("arrest")
        )
        val clearanceRate = if (total > 0) (closed.toDouble / total) * 100 else 0.0
        (weapon, total, closed, clearanceRate)
      }
      .toSeq
      .sortBy(-_._2)
      .take(10)
    
    println(f"${"Weapon Type"}%-25s ${"Total"}%8s ${"Solved"}%8s ${"Rate"}%10s")
    println("-" * 80)
    
    byWeapon.foreach { case (weapon, total, closed, rate) =>
      println(f"${weapon}%-25s ${total}%8d ${closed}%8d ${rate}%9.1f%%")
    }
    
    val lowestClearance = byWeapon.minBy(_._4)
    val avgClearance = byWeapon.map(_._4).sum / byWeapon.size
    
    println("-" * 80)
    println(f"INSIGHT: ${lowestClearance._1} has lowest clearance: ${lowestClearance._4}%.1f%%")
    println(f"         Overall average clearance rate: ${avgClearance}%.1f%%")
  }
  
  /**
   * Sample data for testing
   */
  def getSampleData(): List[Homicide] = {
    val formatter = DateTimeFormatter.ofPattern("MM/dd/yyyy")
    
    val data = List(
      ("01/15/2024", "10:30 PM", "Black", "Male", 25, "1200 N Avenue", "Western", "Open", "Firearm"),
      ("01/20/2024", "02:15 AM", "Black", "Male", 32, "800 E Monument", "Eastern", "Closed by Arrest", "Firearm"),
      ("02/03/2024", "11:45 PM", "Black", "Male", 19, "2100 W Lexington", "Western", "Open", "Firearm"),
      ("02/14/2024", "03:30 PM", "White", "Male", 45, "400 S Broadway", "Southeastern", "Closed by Arrest", "Knife"),
      ("03/22/2024", "09:00 PM", "Black", "Male", 28, "1500 Pennsylvania", "Western", "Open", "Firearm"),
      ("04/05/2024", "01:20 AM", "Hispanic", "Male", 23, "3300 Greenmount", "Northeastern", "Open", "Firearm"),
      ("05/17/2024", "06:45 PM", "Black", "Male", 34, "2200 W North", "Western", "Closed by Arrest", "Firearm"),
      ("06/21/2024", "11:00 PM", "Black", "Male", 21, "1800 N Charles", "Central", "Open", "Firearm"),
      ("07/04/2024", "12:30 AM", "Black", "Male", 29, "900 N Stricker", "Western", "Open", "Firearm"),
      ("07/15/2024", "10:15 PM", "Black", "Male", 26, "1400 W Baltimore", "Southwestern", "Closed by Arrest", "Firearm"),
      ("08/08/2024", "02:45 AM", "Black", "Female", 31, "700 N Patterson", "Eastern", "Open", "Blunt Object"),
      ("08/20/2024", "08:30 PM", "Black", "Male", 22, "2500 W Franklin", "Western", "Open", "Firearm"),
      ("09/12/2024", "04:00 PM", "Black", "Male", 17, "1100 E Chase", "Eastern", "Open", "Firearm"),
      ("09/25/2024", "01:15 AM", "White", "Male", 38, "600 S Conkling", "Southeastern", "Closed by Arrest", "Knife"),
      ("10/10/2024", "11:30 PM", "Black", "Male", 24, "1900 W Pratt", "Northwestern", "Open", "Firearm"),
      ("11/02/2024", "05:20 PM", "Black", "Male", 30, "1600 E Madison", "Eastern", "Open", "Firearm"),
      ("11/18/2024", "09:45 PM", "Hispanic", "Female", 27, "2800 Edmondson", "Western", "Closed by Arrest", "Knife"),
      ("12/05/2024", "03:10 AM", "Black", "Male", 35, "1200 W Fayette", "Western", "Open", "Firearm"),
      ("12/20/2024", "07:30 PM", "Black", "Male", 20, "3100 Greenmount", "Northeastern", "Open", "Firearm"),
      ("12/31/2024", "11:50 PM", "Black", "Male", 33, "900 N Gilmor", "Western", "Open", "Firearm")
    )
    
    data.map { case (date, time, race, sex, age, loc, dist, disp, weapon) =>
      Homicide(
        date = LocalDate.parse(date, formatter),
        time = time,
        race = race,
        sex = sex,
        age = age,
        location = loc,
        district = dist,
        disposition = disp,
        weapon = weapon
      )
    }
  }
}