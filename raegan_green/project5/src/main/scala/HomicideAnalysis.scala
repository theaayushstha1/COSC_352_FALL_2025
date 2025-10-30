import scala.io.Source
import scala.util.Try
import scala.collection.mutable
import java.io.{File, PrintWriter}

object HomicideAnalysis {
  
  case class HomicideRecord(
    date: String,
    name: String,
    age: Int,
    address: String,
    year: Int,
    closed: Boolean
  )
  
  case class AnalysisResults(
    totalRecords: Int,
    closureRatesByYear: List[(Int, Int, Int, Int)], // (year, total, closed, rate)
    ageGroupStats: List[(String, Int, Int)], // (groupName, count, percent)
    topAges: List[(Int, Int)], // (age, count)
    youthStats: (Int, Int, Int) // (children, teens, totalYouth)
  )

  def main(args: Array[String]): Unit = {
    val outputFormat = if (args.length > 0) args(0).toLowerCase else "stdout"
    
    if (!List("stdout", "csv", "json").contains(outputFormat)) {
      println(s"Error: Invalid output format '$outputFormat'")
      println("Valid formats: stdout, csv, json")
      System.exit(1)
    }
    
    // Fetch and parse data
    val records = fetchAndParseData()
    
    if (records.isEmpty) {
      println("ERROR: Could not fetch or parse homicide data from blog")
      println("Please check your internet connection and try again.")
      return
    }

    // Perform analysis
    val results = analyzeData(records)
    
    // Output based on format
    outputFormat match {
      case "stdout" => outputStdout(results, records)
      case "csv" => outputCSV(results, records)
      case "json" => outputJSON(results, records)
    }
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

  def parseHomicideTable(html: String): List[HomicideRecord] = {
    val records = mutable.ListBuffer[HomicideRecord]()
    
    val tdPattern = "<td>(.*?)</td>".r
    val allCells = tdPattern.findAllMatchIn(html).map(m => extractText(m.group(1))).toList
    
    println(s"Extracting data from ${allCells.length} table cells...")
    
    var i = 0
    while (i + 8 < allCells.length) {
      try {
        val numStr = allCells(i).trim
        val dateStr = allCells(i + 1).trim
        val nameStr = allCells(i + 2).trim
        val ageStr = allCells(i + 3).trim
        val addressStr = allCells(i + 4).trim
        val closedStr = allCells(i + 8).trim.toLowerCase
        
        if (numStr.matches("\\d{3}") && dateStr.matches("\\d{2}/\\d{2}/\\d{2}")) {
          val age = Try(ageStr.toInt).getOrElse(0)
          val year = extractYear(dateStr)
          val closed = closedStr.contains("closed")
          
          if (age > 0 && year >= 2020 && year <= 2025 && addressStr.length > 3) {
            records += HomicideRecord(dateStr, nameStr, age, addressStr, year, closed)
          }
          
          i += 9
        } else {
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
    val parts = dateStr.split("/")
    if (parts.length >= 3) {
      val yearPart = parts(2)
      if (yearPart.length == 2) {
        2000 + yearPart.toInt
      } else if (yearPart.length == 4) {
        yearPart.toInt
      } else {
        0
      }
    } else {
      val yearMatch = """\d{4}""".r.findFirstIn(dateStr)
      yearMatch.map(_.toInt).getOrElse(0)
    }
  }

  def analyzeData(records: List[HomicideRecord]): AnalysisResults = {
    // Closure rates by year
    val recordsByYear = records
      .filter(_.year >= 2022)
      .groupBy(_.year)
      .toList
      .sortBy(_._1)
    
    val closureRates = recordsByYear.map { case (year, yearRecords) =>
      val total = yearRecords.length
      val closed = yearRecords.count(_.closed)
      val open = total - closed
      val rate = if (total > 0) ((closed.toDouble / total) * 100).toInt else 0
      (year, total, closed, rate)
    }
    
    // Age group statistics
    val ageGroups = mutable.Map[String, List[HomicideRecord]]()
    ageGroups("Children (0-12)") = records.filter(r => r.age >= 0 && r.age <= 12)
    ageGroups("Teens (13-18)") = records.filter(r => r.age >= 13 && r.age <= 18)
    ageGroups("Young Adults (19-30)") = records.filter(r => r.age >= 19 && r.age <= 30)
    ageGroups("Adults (31-50)") = records.filter(r => r.age >= 31 && r.age <= 50)
    ageGroups("Seniors (51+)") = records.filter(r => r.age >= 51)
    
    val ageGroupStats = ageGroups.toList.sortBy(-_._2.length).map { case (groupName, groupRecords) =>
      val count = groupRecords.length
      val percent = if (records.length > 0) ((count.toDouble / records.length) * 100).toInt else 0
      (groupName, count, percent)
    }
    
    // Top ages
    val topAges = records
      .groupBy(_.age)
      .mapValues(_.length)
      .toList
      .sortBy(-_._2)
      .take(5)
    
    // Youth statistics
    val childVictims = ageGroups("Children (0-12)").length
    val teenVictims = ageGroups("Teens (13-18)").length
    val youthTotal = childVictims + teenVictims
    
    AnalysisResults(
      records.length,
      closureRates,
      ageGroupStats,
      topAges,
      (childVictims, teenVictims, youthTotal)
    )
  }

  def outputStdout(results: AnalysisResults, records: List[HomicideRecord]): Unit = {
    println("\n" + "="*80)
    println("BALTIMORE HOMICIDE STATISTICS ANALYSIS")
    println("="*80 + "\n")
    
    println(s"Successfully loaded ${results.totalRecords} homicide records\n")
    
    // Question 1
    println("Question 1: What is the Case Closure Rate by Year, and is it Improving?")
    println("Why This Matters: Police department performance and resource allocation efficiency")
    println("-" * 80)
    println("\nCase Closure Rates by Year (2022-2024):")
    println("-" * 80)
    println("Year  | Total Cases | Closed | Open  | Closure Rate")
    println("-" * 80)
    
    for ((year, total, closed, rate) <- results.closureRatesByYear) {
      val open = total - closed
      println(f"$year | $total%11d | $closed%6d | $open%5d | $rate%%")
    }
    
    println("\n" + "-" * 80)
    println("Key Findings:")
    
    if (results.closureRatesByYear.length >= 2) {
      val (firstYear, _, _, firstRate) = results.closureRatesByYear.head
      val (lastYear, _, _, lastRate) = results.closureRatesByYear.last
      val change = lastRate - firstRate
      
      println(f"• Year $firstYear Closure Rate: $firstRate%%")
      println(f"• Year $lastYear Closure Rate: $lastRate%%")
      if (change > 0) {
        println(f"• IMPROVEMENT: +$change%% closure rate increase")
      } else if (change < 0) {
        println(f"• DECLINE: $change%% closure rate decrease")
      } else {
        println("• No change in closure rate")
      }
    }
    
    println("\n" + "-"*80 + "\n")
    
    // Question 2
    println("Question 2: Which Age Groups Are Most at Risk, Particularly Children & Youth?")
    println("Why This Matters: Identifying vulnerable populations enables targeted prevention programs")
    println("-" * 80)
    println("\nVictim Distribution by Age Group:")
    println("-" * 80)
    
    for ((groupName, count, percent) <- results.ageGroupStats) {
      val bar = "█" * (percent / 2)
      println(f"$groupName%-25s: $count%3d victims ($percent%3d%%) $bar")
    }
    
    println("\n" + "-" * 80)
    println("Critical Vulnerability Analysis:")
    
    val (childVictims, teenVictims, youthTotal) = results.youthStats
    val youthPercent = if (results.totalRecords > 0) ((youthTotal.toDouble / results.totalRecords) * 100).toInt else 0
    
    println(f"• Children (0-12): $childVictims homicides")
    println(f"• Teens (13-18): $teenVictims homicides")
    println(f"• Combined Youth Total: $youthTotal homicides ($youthPercent%% of all homicides)")
    
    if (childVictims > 0) {
      println(f"• ALERT: $childVictims children under 13 killed - critical child welfare concern")
    }
    
    if (teenVictims > 0) {
      println(f"• URGENT: $teenVictims teenagers killed - intervention programs needed")
    }
    
    println("\n• Top 5 Most Common Victim Ages:")
    for ((age, count) <- results.topAges) {
      println(f"  Age $age: $count victims")
    }
    
    println("\n" + "="*80 + "\n")
  }

  def outputCSV(results: AnalysisResults, records: List[HomicideRecord]): Unit = {
    val outputDir = new File("/app/output")
    if (!outputDir.exists()) outputDir.mkdirs()
    
    val writer = new PrintWriter(new File("/app/output/homicide_analysis.csv"))
    
    try {
      // Header
      writer.println("Baltimore Homicide Analysis - Generated on " + java.time.LocalDate.now())
      writer.println()
      
      // Summary statistics
      writer.println("SUMMARY")
      writer.println("Total Records," + results.totalRecords)
      writer.println()
      
      // Closure rates by year
      writer.println("CASE CLOSURE RATES BY YEAR")
      writer.println("Year,Total Cases,Closed Cases,Open Cases,Closure Rate (%)")
      for ((year, total, closed, rate) <- results.closureRatesByYear) {
        val open = total - closed
        writer.println(s"$year,$total,$closed,$open,$rate")
      }
      writer.println()
      
      // Age group statistics
      writer.println("VICTIM DISTRIBUTION BY AGE GROUP")
      writer.println("Age Group,Count,Percentage (%)")
      for ((groupName, count, percent) <- results.ageGroupStats) {
        writer.println(s"$groupName,$count,$percent")
      }
      writer.println()
      
      // Youth statistics
      writer.println("YOUTH VIOLENCE STATISTICS")
      val (childVictims, teenVictims, youthTotal) = results.youthStats
      val youthPercent = if (results.totalRecords > 0) ((youthTotal.toDouble / results.totalRecords) * 100).toInt else 0
      writer.println("Category,Count")
      writer.println(s"Children (0-12),$childVictims")
      writer.println(s"Teens (13-18),$teenVictims")
      writer.println(s"Total Youth,$youthTotal")
      writer.println(s"Youth Percentage,$youthPercent%")
      writer.println()
      
      // Top ages
      writer.println("TOP 5 VICTIM AGES")
      writer.println("Age,Count")
      for ((age, count) <- results.topAges) {
        writer.println(s"$age,$count")
      }
      writer.println()
      
      // Individual records
      writer.println("INDIVIDUAL HOMICIDE RECORDS")
      writer.println("Date,Name,Age,Address,Year,Case Closed")
      for (record <- records.sortBy(r => (r.year, r.date))) {
        val closedStr = if (record.closed) "Yes" else "No"
        val safeName = record.name.replace(",", ";")
        val safeAddress = record.address.replace(",", ";")
        writer.println(s"${record.date},$safeName,${record.age},$safeAddress,${record.year},$closedStr")
      }
      
      println(s"CSV file written successfully: ${results.totalRecords} records")
    } finally {
      writer.close()
    }
  }

  def outputJSON(results: AnalysisResults, records: List[HomicideRecord]): Unit = {
    val outputDir = new File("/app/output")
    if (!outputDir.exists()) outputDir.mkdirs()
    
    val writer = new PrintWriter(new File("/app/output/homicide_analysis.json"))
    
    try {
      writer.println("{")
      writer.println("  \"metadata\": {")
      writer.println(s"    \"generatedDate\": \"${java.time.LocalDate.now()}\",")
      writer.println(s"    \"totalRecords\": ${results.totalRecords},")
      writer.println("    \"source\": \"http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html\"")
      writer.println("  },")
      
      // Closure rates
      writer.println("  \"closureRates\": [")
      val closureRatesJSON = results.closureRatesByYear.map { case (year, total, closed, rate) =>
        val open = total - closed
        s"""    {
      "year": $year,
      "totalCases": $total,
      "closedCases": $closed,
      "openCases": $open,
      "closureRatePercent": $rate
    }"""
      }.mkString(",\n")
      writer.println(closureRatesJSON)
      writer.println("  ],")
      
      // Age groups
      writer.println("  \"ageGroupStatistics\": [")
      val ageGroupsJSON = results.ageGroupStats.map { case (groupName, count, percent) =>
        s"""    {
      "ageGroup": "$groupName",
      "count": $count,
      "percentageOfTotal": $percent
    }"""
      }.mkString(",\n")
      writer.println(ageGroupsJSON)
      writer.println("  ],")
      
      // Youth statistics
      val (childVictims, teenVictims, youthTotal) = results.youthStats
      val youthPercent = if (results.totalRecords > 0) ((youthTotal.toDouble / results.totalRecords) * 100).toInt else 0
      writer.println("  \"youthStatistics\": {")
      writer.println(s"    \"children\": $childVictims,")
      writer.println(s"    \"teens\": $teenVictims,")
      writer.println(s"    \"totalYouth\": $youthTotal,")
      writer.println(s"    \"youthPercentage\": $youthPercent")
      writer.println("  },")
      
      // Top ages
      writer.println("  \"topVictimAges\": [")
      val topAgesJSON = results.topAges.map { case (age, count) =>
        s"""    { "age": $age, "count": $count }"""
      }.mkString(",\n")
      writer.println(topAgesJSON)
      writer.println("  ],")
      
      // Individual records
      writer.println("  \"homicideRecords\": [")
      val recordsJSON = records.sortBy(r => (r.year, r.date)).map { record =>
        val safeName = record.name.replace("\"", "\\\"")
        val safeAddress = record.address.replace("\"", "\\\"")
        s"""    {
      "date": "${record.date}",
      "name": "$safeName",
      "age": ${record.age},
      "address": "$safeAddress",
      "year": ${record.year},
      "caseClosed": ${record.closed}
    }"""
      }.mkString(",\n")
      writer.println(recordsJSON)
      writer.println("  ]")
      
      writer.println("}")
      
      println(s"JSON file written successfully: ${results.totalRecords} records")
    } finally {
      writer.close()
    }
  }
}