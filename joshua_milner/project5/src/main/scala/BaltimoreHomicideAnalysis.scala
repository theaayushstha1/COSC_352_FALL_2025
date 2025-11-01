import scala.io.Source
import scala.util.{Try, Success, Failure}
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import scala.util.matching.Regex
import java.io.{PrintWriter, File}

object BaltimoreHomicideAnalysis {
  
  // ========================================
  // SECTION 1: DATA STRUCTURES (Keep + New)
  // ========================================
  
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
  
  // NEW for Project 5
  case class MonthlyData(
    month: String,
    monthNumber: Int,
    homicides: Int,
    percentage: Double
  )
  
  case class WeaponData(
    weapon: String,
    total: Int,
    closed: Int,
    clearanceRate: Double
  )
  
  case class AnalysisResults(
    analysisDate: String,
    totalRecords: Int,
    question1: Question1Results,
    question2: Question2Results
  )
  
  case class Question1Results(
    title: String,
    purpose: String,
    monthlyData: List[MonthlyData],
    peakMonth: String,
    peakCount: Int,
    lowestMonth: String,
    lowestCount: Int
  )
  
  case class Question2Results(
    title: String,
    purpose: String,
    weaponData: List[WeaponData],
    lowestClearanceWeapon: String,
    lowestClearanceRate: Double,
    averageClearanceRate: Double
  )
  
  def main(args: Array[String]): Unit = {
    val outputFormat = if (args.length > 0) args(0).toLowerCase else "stdout"
    
    if (!List("stdout", "csv", "json").contains(outputFormat)) {
      System.err.println(s"ERROR: Invalid output format '$outputFormat'")
      System.err.println("Valid formats: stdout, csv, json")
      System.exit(1)
    }
    
    val homicides = fetchAndParseData()
    
    if (homicides.isEmpty) {
      System.err.println("ERROR: No data could be retrieved.")
      System.exit(1)
    }
    
    val results = analyzeData(homicides)
    
    outputFormat match {
      case "stdout" => outputToStdout(results, homicides)
      case "csv" => outputToCsv(results, homicides)
      case "json" => outputToJson(results, homicides)
    }
  }
  
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
  
  def parseHtmlTable(html: String): List[Homicide] = {
    val tables = extractTables(html)
    
    if (tables.isEmpty) {
      return List.empty
    }
    
    val homicideTable = tables.maxBy(_.size)
    homicideTable.flatMap(parseRow)
  }
  
  def extractTables(html: String): List[List[List[String]]] = {
    val cleanHtml = html.replaceAll("\\s+", " ")
    val tableRegex: Regex = "(?s)<table[^>]*>(.*?)</table>".r
    
    tableRegex.findAllMatchIn(cleanHtml).map { tableMatch =>
      val tableContent = tableMatch.group(1)
      extractRows(tableContent)
    }.toList
  }
  
  def extractRows(tableHtml: String): List[List[String]] = {
    val rowRegex: Regex = "(?s)<tr[^>]*>(.*?)</tr>".r
    
    rowRegex.findAllMatchIn(tableHtml).map { rowMatch =>
      val rowContent = rowMatch.group(1)
      extractCells(rowContent)
    }.toList.filter(_.nonEmpty)
  }

  def extractCells(rowHtml: String): List[String] = {
    val cellRegex: Regex = "(?s)<t[dh][^>]*>(.*?)</t[dh]>".r
    
    cellRegex.findAllMatchIn(rowHtml).map { cellMatch =>
      val cellContent = cellMatch.group(1)
      cleanCellText(cellContent)
    }.toList
  }
  
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
  
  def analyzeData(homicides: List[Homicide]): AnalysisResults = {
    val totalRecords = homicides.size   
  
    // Question 1: Monthly analysis
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
  
    val total = homicides.size.toDouble
    val monthlyData = byMonth.map { case (month, count) =>
      MonthlyData(
        month = monthNames(month),
        monthNumber = month,
        homicides = count,
        percentage = (count / total) * 100
      )
    }.toList
  
    val peakMonth = byMonth.maxBy(_._2)
    val lowestMonth = byMonth.minBy(_._2)
  
    val question1 = Question1Results(
      title = "What are the deadliest months for homicides in Baltimore?",
      purpose = "Optimize police patrol schedules and resource allocation",
      monthlyData = monthlyData,
      peakMonth = monthNames(peakMonth._1),
      peakCount = peakMonth._2,
      lowestMonth = monthNames(lowestMonth._1),
      lowestCount = lowestMonth._2
    )
  
    // Question 2: Weapon analysis
    val byWeapon = homicides
      .groupBy(_.weapon)
      .map { case (weapon, cases) =>
        val totalCases = cases.size
        val closed = cases.count(c => 
          c.disposition.toLowerCase.contains("closed") || 
          c.disposition.toLowerCase.contains("arrest")
        )
        val rate = if (totalCases > 0) (closed.toDouble / totalCases) * 100 else 0.0
      
        WeaponData(
          weapon = weapon,
          total = totalCases,
          closed = closed,
          clearanceRate = rate
        )
      }
      .toList
      .sortBy(-_.total)
      .take(10)
  
    val lowestClearance = byWeapon.minBy(_.clearanceRate)
    val avgClearance = byWeapon.map(_.clearanceRate).sum / byWeapon.size
  
    val question2 = Question2Results(
      title = "Which types of homicide cases are hardest to solve?",
      purpose = "Identify investigation challenges for detective training",
      weaponData = byWeapon,
      lowestClearanceWeapon = lowestClearance.weapon,
      lowestClearanceRate = lowestClearance.clearanceRate,
      averageClearanceRate = avgClearance
    )
  
    AnalysisResults(
      analysisDate = LocalDate.now().toString,
      totalRecords = totalRecords,
      question1 = question1,
      question2 = question2
      )
  }
  
  def outputToStdout(results: AnalysisResults, homicides: List[Homicide]): Unit = {
    println("-" * 80)
    println("Baltimore City Homeicide Analysis")
    println("-" * 80)
    println()
    println(s"Total Records Analyzed: ${results.totalRecords}")
    println()
  
    // Question 1
    println(s"QUESTION 1: ${results.question1.title}")
    println("-" * 80)
    println(f"${"Month"}%-15s ${"Homicides"}%10s ${"Percentage"}%12s")
    println("-" * 80)
  
    results.question1.monthlyData.foreach { data =>
      println(f"${data.month}%-15s ${data.homicides}%10d ${data.percentage}%11.2f%%")
    }
  
    println("-" * 80)
    println(s"INSIGHT: ${results.question1.peakMonth} is deadliest with ${results.question1.peakCount} homicides")
    println(s"         ${results.question1.lowestMonth} is safest with ${results.question1.lowestCount} homicides")
    println()
  
    // Question 2
    println(s"QUESTION 2: ${results.question2.title}")
    println("-" * 80)
    println(f"${"Weapon Type"}%-25s ${"Total"}%8s ${"Solved"}%8s ${"Rate"}%10s")
    println("-" * 80)
  
    results.question2.weaponData.foreach { data =>
      println(f"${data.weapon}%-25s ${data.total}%8d ${data.closed}%8d ${data.clearanceRate}%9.1f%%")
    }
  
    println("-" * 80)
    println(f"INSIGHT: ${results.question2.lowestClearanceWeapon} has lowest clearance: ${results.question2.lowestClearanceRate}%.1f%%")
    println(f"         Overall average clearance rate: ${results.question2.averageClearanceRate}%.1f%%")
    println()
    println("=" * 80)
  }
  
  def outputToCsv(results: AnalysisResults, homicides: List[Homicide]): Unit = {
    val outputPath = "/app/output/analysis_results.csv"
    val writer = new PrintWriter(new File(outputPath))
  
    try {
      // Metadata section
      writer.println("Baltimore City Homeicide Analysis")
      writer.println(s"Analysis Date,${results.analysisDate}")
      writer.println(s"Total Records,${results.totalRecords}")
      writer.println()
    
      // Question 1: Monthly Data
      writer.println(s"QUESTION 1,${results.question1.title}")
      writer.println()
      writer.println("Month,Month Number,Homicides,Percentage")
    
      results.question1.monthlyData.foreach { data =>
        writer.println(s"${data.month},${data.monthNumber},${data.homicides},${data.percentage}")
      }
    
      writer.println()
      writer.println("KEY INSIGHTS")
      writer.println(s"Peak Month,${results.question1.peakMonth},${results.question1.peakCount}")
      writer.println(s"Lowest Month,${results.question1.lowestMonth},${results.question1.lowestCount}")
      writer.println()
    
      // Question 2: Weapon Data
      writer.println(s"QUESTION 2,${results.question2.title}")
      writer.println()
        writer.println("Weapon Type,Total Cases,Closed Cases,Clearance Rate (%)")
    
      results.question2.weaponData.foreach { data =>
        writer.println(s"${data.weapon},${data.total},${data.closed},${data.clearanceRate}")
      }
    
      writer.println()
      writer.println("KEY INSIGHTS")
      writer.println(s"Lowest Clearance Weapon,${results.question2.lowestClearanceWeapon},${results.question2.lowestClearanceRate}")
      writer.println(s"Average Clearance Rate,${results.question2.averageClearanceRate}")
    
      println(s"✓ CSV file written to: $outputPath")
    
    } finally {
      writer.close()
    }
  }
  
  def outputToJson(results: AnalysisResults, homicides: List[Homicide]): Unit = {
    val outputPath = "/app/output/analysis_results.json"
    val writer = new PrintWriter(new File(outputPath))
  
    try {
      writer.println("{")
      writer.println(s"""  "analysis_date": "${results.analysisDate}",""")
      writer.println(s"""  "total_records": ${results.totalRecords},""")
      writer.println(s"""  "questions": [""")
    
      // Question 1
      writer.println("    {")
      writer.println(s"""      "question_number": 1,""")
      writer.println(s"""      "title": "${escapeJson(results.question1.title)}",""")
      writer.println(s"""      "purpose": "${escapeJson(results.question1.purpose)}",""")
      writer.println(s"""      "monthly_data": [""")
    
      results.question1.monthlyData.zipWithIndex.foreach { case (data, idx) =>
        val comma = if (idx < results.question1.monthlyData.size - 1) "," else ""
        writer.println("        {")
        writer.println(s"""          "month": "${data.month}",""")
        writer.println(s"""          "month_number": ${data.monthNumber},""")
        writer.println(s"""          "homicides": ${data.homicides},""")
        writer.println(s"""          "percentage": ${data.percentage}""")
        writer.println(s"        }$comma")
      }
    
      writer.println("      ],")
      writer.println(s"""      "insights": {""")
      writer.println(s"""        "peak_month": "${results.question1.peakMonth}",""")
      writer.println(s"""        "peak_count": ${results.question1.peakCount},""")
      writer.println(s"""        "lowest_month": "${results.question1.lowestMonth}",""")
      writer.println(s"""        "lowest_count": ${results.question1.lowestCount}""")
      writer.println("      }")
      writer.println("    },")
    
      // Question 2
      writer.println("    {")
      writer.println(s"""      "question_number": 2,""")
      writer.println(s"""      "title": "${escapeJson(results.question2.title)}",""")
      writer.println(s"""      "purpose": "${escapeJson(results.question2.purpose)}",""")
      writer.println(s"""      "weapon_data": [""")
    
      results.question2.weaponData.zipWithIndex.foreach { case (data, idx) =>
        val comma = if (idx < results.question2.weaponData.size - 1) "," else ""
        writer.println("        {")
        writer.println(s"""          "weapon": "${escapeJson(data.weapon)}",""")
        writer.println(s"""          "total": ${data.total},""")
        writer.println(s"""          "closed": ${data.closed},""")
        writer.println(s"""          "clearance_rate": ${data.clearanceRate}""")
        writer.println(s"        }$comma")
      }
    
      writer.println("      ],")
      writer.println(s"""      "insights": {""")
      writer.println(s"""        "lowest_clearance_weapon": "${escapeJson(results.question2.lowestClearanceWeapon)}",""")
      writer.println(s"""        "lowest_clearance_rate": ${results.question2.lowestClearanceRate},""")
      writer.println(s"""        "average_clearance_rate": ${results.question2.averageClearanceRate}""")
      writer.println("      }")
      writer.println("    }")
    
      writer.println("  ]")
      writer.println("}")
    
      println(s"✓ JSON file written to: $outputPath")
    
    } finally {
      writer.close()
    }
  }
  
  def escapeJson(s: String): String = {
    s.replace("\\", "\\\\")
     .replace("\"", "\\\"")
     .replace("\n", "\\n")
     .replace("\r", "\\r")
     .replace("\t", "\\t")
  }


  /**
  * Sample data for testing
  */
  def getSampleData(): List[Homicide] = {
    val formatter = DateTimeFormatter.ofPattern("MM/dd/yyyy")
  
    List(
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
    ).map { case (date, time, race, sex, age, loc, dist, disp, weapon) =>
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