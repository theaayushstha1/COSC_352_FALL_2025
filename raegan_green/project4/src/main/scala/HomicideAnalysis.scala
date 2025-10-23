import scala.io.Source
import scala.util.Try
import scala.collection.mutable

object HomicideAnalysis {
  
  case class HomicideRecord(
    date: String,
    name: String,
    age: Int,
    address: String,
    year: Int,
    closed: Boolean
  )

  def main(args: Array[String]): Unit = {
    println("\n" + "="*80)
    println("BALTIMORE HOMICIDE STATISTICS ANALYSIS")
    println("="*80 + "\n")

    val records = fetchAndParseData()
    
    if (records.isEmpty) {
      println("ERROR: Could not fetch or parse homicide data from blog")
      println("Please check your internet connection and try again.")
      println("="*80 + "\n")
      return
    }

    println(s"Successfully loaded ${records.length} homicide records\n")

    // Question 1: Case Resolution Efficiency Trends
    analyzeQuestion1(records)
    
    println("\n" + "-"*80 + "\n")
    
    // Question 2: Age-Based Victim Demographics & Vulnerable Populations
    analyzeQuestion2(records)
    
    println("\n" + "="*80 + "\n")
  }

  def fetchAndParseData(): List[HomicideRecord] = {
    try {
      println("Fetching data from Baltimore homicide database...")
      val url = new java.net.URL("http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html")
      val connection = url.openConnection()
      connection.setRequestProperty("User-Agent", "Mozilla/5.0")
      connection.setConnectTimeout(10000)
      connection.setReadTimeout(10000)
      val source = Source.fromInputStream(connection.getInputStream)
      val html = source.mkString
      source.close()
      
      println("Data fetched successfully. Parsing...")
      parseHomicideTable(html)
    } catch {
      case e: Exception =>
        println(s"Error fetching data: ${e.getMessage}")
        List()
    }
  }
  
  def getSampleData(): List[HomicideRecord] = {
    List(
      HomicideRecord("01/02/24", "Noah Gibson", 16, "1 Gorman Avenue", 2024, false),
      HomicideRecord("01/04/24", "Antoine Johnson", 31, "1 North Eutaw Street", 2024, true),
      HomicideRecord("01/12/24", "Deon Beasley", 36, "800 Washington Boulevard", 2024, false),
      HomicideRecord("01/14/24", "Jazmyn Reed", 30, "I-83 North Exit 3", 2024, true),
      HomicideRecord("01/15/24", "Dominic Wynn", 39, "2800 Mayfield Avenue", 2024, false),
      HomicideRecord("01/09/24", "Quantae Arthur", 33, "3600 Belair Road", 2024, false),
      HomicideRecord("01/19/24", "Dequan Thomas", 28, "5200 Fairlawn Avenue", 2024, true),
      HomicideRecord("01/19/24", "Charlie Cameron", 30, "5200 Fairlawn Avenue", 2024, true),
      HomicideRecord("01/19/24", "Willie Cameron Jr", 32, "5200 Fairlawn Avenue", 2024, false),
      HomicideRecord("01/19/24", "Malachi Carter-Bey", 39, "4500 Pennington Avenue", 2024, false),
      HomicideRecord("01/19/24", "Mary Lou Schuman", 60, "4500 Pennington Avenue", 2024, false),
      HomicideRecord("01/23/24", "Seron O'Neal", 6, "2000 Deering Avenue", 2024, true),
      HomicideRecord("01/24/23", "Delroy Plummer", 68, "5200 Fairlawn Avenue", 2023, false),
      HomicideRecord("01/26/24", "Kareem Gee", 20, "1200 East Preston Street", 2024, true),
      HomicideRecord("01/30/24", "Sean Hennessy", 34, "1100 West Baltimore Street", 2024, false),
      HomicideRecord("01/30/24", "Davon Brown", 36, "4000 Wilsby Avenue", 2024, false),
      HomicideRecord("02/01/24", "Charles Banks", 46, "5200 Saybrook Road", 2024, false),
      HomicideRecord("02/02/24", "D'Shawn Johnson", 25, "900 Coppin Court", 2024, false),
      HomicideRecord("02/03/24", "Melvin White", 55, "3000 Edmondson Avenue", 2024, true),
      HomicideRecord("02/07/24", "Ricardo Brooks-Watters", 32, "4400 Belair Road", 2024, true),
      HomicideRecord("02/07/24", "Odell Curtis", 40, "4400 Belair Road", 2024, true),
      HomicideRecord("02/09/24", "Milo Turner", 30, "6500 Parnell Avenue", 2024, false),
      HomicideRecord("02/16/24", "Dwayne Flintall", 38, "900 North Carrollton Avenue", 2024, false),
      HomicideRecord("02/16/24", "Darrian Williams", 45, "4000 Kathland Avenue", 2024, false),
      HomicideRecord("02/16/24", "Rickey Cole", 69, "4000 Kathland Avenue", 2024, false),
      HomicideRecord("02/17/24", "Amari Williams", 20, "200 Marion Street", 2024, false),
      HomicideRecord("02/20/24", "Darcell Mitchell", 19, "800 West Lexington Street", 2024, true),
      HomicideRecord("02/29/24", "Bryant Williams", 38, "100 South Stockton Street", 2024, false),
      HomicideRecord("02/29/24", "Cormer Askins", 16, "800 Bethune Road", 2024, false),
      HomicideRecord("03/01/24", "Johnny Small", 55, "5300 Frankford Avenue", 2024, true),
      HomicideRecord("03/02/24", "Alvin Ray Henry", 35, "1400 East Biddle Street", 2024, true),
      HomicideRecord("03/05/24", "Isiah Taylor", 21, "200 South Monstary Avenue", 2024, false),
      HomicideRecord("03/06/24", "Denzel Brown", 29, "4000 Loch Raven Boulevard", 2024, true),
      HomicideRecord("03/07/24", "Wayne Sawyer", 41, "200 Furrow Street", 2024, false),
      HomicideRecord("03/11/24", "Rasheed Lindsey", 24, "3000 Spaulding Avenue", 2024, false),
      HomicideRecord("03/12/24", "Timothy Peaks", 58, "1000 Glover Street", 2024, false),
      HomicideRecord("03/12/24", "Justice Smallwood", 33, "1 South Chester Street", 2024, false),
      HomicideRecord("03/13/24", "Christine Liddic-Rozzell", 49, "4000 Alto Road", 2024, false),
      HomicideRecord("03/13/24", "Martinez Brown", 26, "1500 East 28th Street", 2024, false),
      HomicideRecord("03/15/24", "Lenora Alston", 35, "1000 Fulton Street", 2024, true),
      HomicideRecord("04/10/24", "James Wilson", 27, "2300 Pennsylvania Avenue", 2024, false),
      HomicideRecord("04/15/24", "Marcus Thompson", 22, "800 North Avenue", 2024, false),
      HomicideRecord("04/20/24", "Kevin Davis", 31, "1500 West North Avenue", 2024, true),
      HomicideRecord("05/05/24", "Tyrone Jackson", 29, "3400 Greenmount Avenue", 2024, false),
      HomicideRecord("05/12/24", "Andre Williams", 24, "2100 East Monument Street", 2024, false),
      HomicideRecord("06/08/24", "Robert Miller", 33, "1700 East Baltimore Street", 2024, true),
      HomicideRecord("06/15/24", "Michael Brown", 26, "900 North Gay Street", 2024, false),
      HomicideRecord("07/04/24", "Christopher Lee", 28, "2500 Druid Hill Avenue", 2024, false),
      HomicideRecord("07/20/24", "Brandon Harris", 23, "3100 West North Avenue", 2024, true),
      HomicideRecord("08/10/24", "Jonathan Taylor", 30, "1900 East Fayette Street", 2024, false)
    )
  }

  def parseHomicideTable(html: String): List[HomicideRecord] = {
    val records = mutable.ListBuffer[HomicideRecord]()
    
    // Extract all <td> content into a list
    val tdPattern = "<td>(.*?)</td>".r
    val allCells = tdPattern.findAllMatchIn(html).map(m => extractText(m.group(1))).toList
    
    println(s"Extracting data from ${allCells.length} table cells...")
    
    // Process cells in groups of 9 (each row has 9 columns)
    var i = 0
    while (i + 8 < allCells.length) {
      try {
        val numStr = allCells(i).trim
        val dateStr = allCells(i + 1).trim
        val nameStr = allCells(i + 2).trim
        val ageStr = allCells(i + 3).trim
        val addressStr = allCells(i + 4).trim
        val closedStr = allCells(i + 8).trim.toLowerCase
        
        // Check if this looks like a valid homicide record
        if (numStr.matches("\\d{3}") && dateStr.matches("\\d{2}/\\d{2}/\\d{2}")) {
          val age = Try(ageStr.toInt).getOrElse(0)
          val year = extractYear(dateStr)
          val closed = closedStr.contains("closed")
          
          if (age > 0 && year >= 2020 && year <= 2025 && addressStr.length > 3) {
            records += HomicideRecord(dateStr, nameStr, age, addressStr, year, closed)
          }
          
          // Move to next record (9 cells per record)
          i += 9
        } else {
          // Not a valid record, move forward one cell
          i += 1
        }
      } catch {
        case _: Exception => 
          i += 1
      }
    }
    
    records.toList
  }

  def extractText(cell: String): String = {
    // Remove HTML tags and decode entities
    val noTags = cell.replaceAll("<[^>]*>", "")
    val decoded = noTags
      .replace("&nbsp;", " ")
      .replace("&amp;", "&")
      .replace("&lt;", "<")
      .replace("&gt;", ">")
      .replace("&quot;", "\"")
    decoded
  }

  def extractYear(dateStr: String): Int = {
    // Handle format like "01/02/24" or "01/02/2024"
    val parts = dateStr.split("/")
    if (parts.length >= 3) {
      val yearPart = parts(2)
      if (yearPart.length == 2) {
        // Two digit year - assume 20xx
        2000 + yearPart.toInt
      } else if (yearPart.length == 4) {
        yearPart.toInt
      } else {
        0
      }
    } else {
      // Try finding 4-digit year
      val yearMatch = """\d{4}""".r.findFirstIn(dateStr)
      yearMatch.map(_.toInt).getOrElse(0)
    }
  }

  def analyzeQuestion1(records: List[HomicideRecord]): Unit = {
    println("Question 1: What is the Case Closure Rate by Year, and is it Improving?")
    println("Why This Matters: Police department performance and resource allocation efficiency")
    println("-" * 80)
    
    val recordsByYear = records
      .filter(_.year >= 2022)
      .groupBy(_.year)
      .toList
      .sortBy(_._1)

    println("\nCase Closure Rates by Year (2022-2024):")
    println("-" * 80)
    println("Year  | Total Cases | Closed | Open  | Closure Rate")
    println("-" * 80)
    
    for ((year, yearRecords) <- recordsByYear) {
      val total = yearRecords.length
      val closed = yearRecords.count(_.closed)
      val open = total - closed
      val rate = if (total > 0) ((closed.toDouble / total) * 100).toInt else 0
      println(f"$year | $total%11d | $closed%6d | $open%5d | $rate%%")
    }

    println("\n" + "-" * 80)
    println("Key Findings:")
    
    if (recordsByYear.length >= 2) {
      val firstYear = recordsByYear.head
      val lastYear = recordsByYear.last
      val firstRate = ((firstYear._2.count(_.closed).toDouble / firstYear._2.length) * 100).toInt
      val lastRate = ((lastYear._2.count(_.closed).toDouble / lastYear._2.length) * 100).toInt
      val change = lastRate - firstRate
      
      println(f"• Year ${firstYear._1} Closure Rate: $firstRate%%")
      println(f"• Year ${lastYear._1} Closure Rate: $lastRate%%")
      if (change > 0) {
        println(f"• IMPROVEMENT: +$change%% closure rate increase")
      } else if (change < 0) {
        println(f"• DECLINE: $change%% closure rate decrease")
      } else {
        println("• No change in closure rate")
      }
    }
  }

  def analyzeQuestion2(records: List[HomicideRecord]): Unit = {
    println("Question 2: Which Age Groups Are Most at Risk, Particularly Children & Youth?")
    println("Why This Matters: Identifying vulnerable populations enables targeted prevention programs")
    println("-" * 80)
    
    val ageGroups = mutable.Map[String, List[HomicideRecord]]()
    
    ageGroups("Children (0-12)") = records.filter(r => r.age >= 0 && r.age <= 12)
    ageGroups("Teens (13-18)") = records.filter(r => r.age >= 13 && r.age <= 18)
    ageGroups("Young Adults (19-30)") = records.filter(r => r.age >= 19 && r.age <= 30)
    ageGroups("Adults (31-50)") = records.filter(r => r.age >= 31 && r.age <= 50)
    ageGroups("Seniors (51+)") = records.filter(r => r.age >= 51)
    
    println("\nVictim Distribution by Age Group:")
    println("-" * 80)
    
    val sortedGroups = ageGroups.toList.sortBy(-_._2.length)
    
    for ((groupName, groupRecords) <- sortedGroups) {
      val count = groupRecords.length
      val percent = if (records.length > 0) ((count.toDouble / records.length) * 100).toInt else 0
      val bar = "█" * (percent / 2)
      println(f"$groupName%-25s: $count%3d victims ($percent%3d%%) $bar")
    }

    println("\n" + "-" * 80)
    println("Critical Vulnerability Analysis:")
    
    val childVictims = ageGroups("Children (0-12)").length
    val teenVictims = ageGroups("Teens (13-18)").length
    val youthTotal = childVictims + teenVictims
    val youthPercent = if (records.length > 0) ((youthTotal.toDouble / records.length) * 100).toInt else 0
    
    println(f"• Children (0-12): $childVictims homicides")
    println(f"• Teens (13-18): $teenVictims homicides")
    println(f"• Combined Youth Total: $youthTotal homicides ($youthPercent%% of all homicides)")
    
    if (childVictims > 0) {
      println(f"• ALERT: $childVictims children under 13 killed - critical child welfare concern")
    }
    
    if (teenVictims > 0) {
      println(f"• URGENT: $teenVictims teenagers killed - intervention programs needed")
    }
    
    // Highest risk individual ages
    println("\n• Top 5 Most Common Victim Ages:")
    val ageFrequency = records
      .groupBy(_.age)
      .mapValues(_.length)
      .toList
      .sortBy(-_._2)
      .take(5)
    
    for ((age, count) <- ageFrequency) {
      println(f"  Age $age: $count victims")
    }
  }
}

