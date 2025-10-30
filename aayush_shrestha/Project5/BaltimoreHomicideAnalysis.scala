import scala.io.Source
import scala.util.{Try, Success, Failure}
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.io.{File, PrintWriter}

object BaltimoreHomicideAnalysis {
  
  case class Homicide(
    number: String,
    dateDied: String,
    name: String,
    age: String,
    address: String,
    cameraPresent: String,
    caseClosed: String
  )

  // Data structures for analysis results
  case class LocationHotspot(
    location: String,
    totalCases: Int,
    openCases: Int,
    closedCases: Int,
    closureRate: Double,
    camerasPresent: Int,
    avgVictimAge: Double
  )

  case class AgeGroupAnalysis(
    ageGroup: String,
    totalCases: Int,
    closedCases: Int,
    openCases: Int,
    closureRate: Double,
    camerasPresent: Int
  )

  case class AnalysisResults(
    totalHomicides: Int,
    overallClosureRate: Double,
    locationHotspots: List[LocationHotspot],
    criticalZonesCount: Int,
    ageGroupAnalysis: List[AgeGroupAnalysis]
  )

  def main(args: Array[String]): Unit = {
    val outputFormat = if (args.length > 0) args(0) else "stdout"
    
    println("=" * 80)
    println("BALTIMORE CITY HOMICIDE DATA ANALYSIS")
    println("Mayor's Office Strategic Crime Prevention Initiative")
    println("Data Source: chamspage.blogspot.com")
    println("=" * 80)
    println()

    val homicides = fetchRealData()
    
    if (homicides.isEmpty) {
      println("WARNING: Could not fetch live data. Using sample data for demonstration.")
      println()
      val sampleData = getSampleData()
      processData(sampleData, outputFormat)
    } else {
      println(s"✓ Successfully loaded ${homicides.size} homicide records")
      println()
      processData(homicides, outputFormat)
    }
  }

  def processData(homicides: List[Homicide], outputFormat: String): Unit = {
    outputFormat.toLowerCase match {
      case "csv" =>
        println("Generating CSV output...")
        val results = performAnalysis(homicides)
        writeCSV(results, homicides)
        println("✓ CSV file generated: /output/baltimore_homicide_analysis.csv")
      
      case "json" =>
        println("Generating JSON output...")
        val results = performAnalysis(homicides)
        writeJSON(results, homicides)
        println("✓ JSON file generated: /output/baltimore_homicide_analysis.json")
      
      case _ =>
        // Default stdout output (your original output)
        analyzeQuestion1(homicides)
        println()
        println()
        analyzeQuestion2(homicides)
    }
  }

  def performAnalysis(homicides: List[Homicide]): AnalysisResults = {
    // Question 1: Location Analysis
    val locationClusters = homicides.groupBy(h => normalizeAddress(h.address))
    
    val locationHotspots = locationClusters.map { case (location, cases) =>
      val totalCases = cases.size
      val closedCases = cases.count(_.caseClosed.equalsIgnoreCase("Closed"))
      val openCases = totalCases - closedCases
      val closureRate = if (totalCases > 0) (closedCases.toDouble / totalCases * 100) else 0.0
      val withCameras = cases.count(_.cameraPresent.toLowerCase.contains("camera"))
      val avgAge = cases.flatMap(h => Try(h.age.toInt).toOption).sum.toDouble / 
                   cases.flatMap(h => Try(h.age.toInt).toOption).size.max(1)
      
      LocationHotspot(location, totalCases, openCases, closedCases, closureRate, withCameras, avgAge)
    }.toList.sortBy(-_.totalCases)

    val criticalZones = locationHotspots.filter(_.totalCases >= 3)

    // Question 2: Age Group Analysis
    val ageGroups = Map(
      "Minors (Under 18)" -> (0, 17),
      "Young Adults (18-25)" -> (18, 25),
      "Adults (26-40)" -> (26, 40),
      "Middle Age (41-60)" -> (41, 60),
      "Seniors (61+)" -> (61, 150)
    )

    val ageGroupAnalysis = ageGroups.map { case (groupName, (minAge, maxAge)) =>
      val groupCases = homicides.filter { h =>
        Try(h.age.toInt).toOption match {
          case Some(age) => age >= minAge && age <= maxAge
          case None => false
        }
      }
      val total = groupCases.size
      val closed = groupCases.count(_.caseClosed.equalsIgnoreCase("Closed"))
      val open = total - closed
      val closureRate = if (total > 0) (closed.toDouble / total * 100) else 0.0
      val withCameras = groupCases.count(_.cameraPresent.toLowerCase.contains("camera"))
      
      AgeGroupAnalysis(groupName, total, closed, open, closureRate, withCameras)
    }.toList.sortBy(-_.totalCases)

    val overallClosureRate = if (homicides.nonEmpty) {
      (homicides.count(_.caseClosed.equalsIgnoreCase("Closed")).toDouble / homicides.size * 100)
    } else 0.0

    AnalysisResults(
      totalHomicides = homicides.size,
      overallClosureRate = overallClosureRate,
      locationHotspots = locationHotspots,
      criticalZonesCount = criticalZones.size,
      ageGroupAnalysis = ageGroupAnalysis
    )
  }

  def writeCSV(results: AnalysisResults, homicides: List[Homicide]): Unit = {
    val writer = new PrintWriter(new File("/output/baltimore_homicide_analysis.csv"))
    
    try {
      // Write metadata
      writer.println("BALTIMORE CITY HOMICIDE DATA ANALYSIS")
      writer.println(s"Total Homicides,${results.totalHomicides}")
      writer.println(s"Overall Closure Rate,${f"${results.overallClosureRate}%.2f"}%")
      writer.println(s"Critical Zones Count,${results.criticalZonesCount}")
      writer.println()
      
      // Write Location Hotspots
      writer.println("LOCATION HOTSPOTS ANALYSIS")
      writer.println("Location,Total Cases,Open Cases,Closed Cases,Closure Rate (%),Cameras Present,Avg Victim Age")
      results.locationHotspots.foreach { hotspot =>
        writer.println(s"${escapeCSV(hotspot.location)},${hotspot.totalCases},${hotspot.openCases}," +
          s"${hotspot.closedCases},${f"${hotspot.closureRate}%.2f"},${hotspot.camerasPresent}," +
          s"${f"${hotspot.avgVictimAge}%.0f"}")
      }
      writer.println()
      
      // Write Age Group Analysis
      writer.println("AGE GROUP ANALYSIS")
      writer.println("Age Group,Total Cases,Closed Cases,Open Cases,Closure Rate (%),Cameras Present")
      results.ageGroupAnalysis.foreach { group =>
        writer.println(s"${escapeCSV(group.ageGroup)},${group.totalCases},${group.closedCases}," +
          s"${group.openCases},${f"${group.closureRate}%.2f"},${group.camerasPresent}")
      }
      writer.println()
      
      // Write raw homicide data
      writer.println("RAW HOMICIDE DATA")
      writer.println("Number,Date Died,Name,Age,Address,Camera Present,Case Status")
      homicides.foreach { h =>
        writer.println(s"${escapeCSV(h.number)},${escapeCSV(h.dateDied)},${escapeCSV(h.name)}," +
          s"${escapeCSV(h.age)},${escapeCSV(h.address)},${escapeCSV(h.cameraPresent)},${escapeCSV(h.caseClosed)}")
      }
    } finally {
      writer.close()
    }
  }

  def writeJSON(results: AnalysisResults, homicides: List[Homicide]): Unit = {
    val writer = new PrintWriter(new File("/output/baltimore_homicide_analysis.json"))
    
    try {
      writer.println("{")
      writer.println("  \"analysis_metadata\": {")
      writer.println(s"    \"total_homicides\": ${results.totalHomicides},")
      writer.println(s"    \"overall_closure_rate\": ${f"${results.overallClosureRate}%.2f"},")
      writer.println(s"    \"critical_zones_count\": ${results.criticalZonesCount}")
      writer.println("  },")
      
      // Location Hotspots
      writer.println("  \"location_hotspots\": [")
      results.locationHotspots.zipWithIndex.foreach { case (hotspot, idx) =>
        writer.println("    {")
        writer.println(s"      \"location\": ${escapeJSON(hotspot.location)},")
        writer.println(s"      \"total_cases\": ${hotspot.totalCases},")
        writer.println(s"      \"open_cases\": ${hotspot.openCases},")
        writer.println(s"      \"closed_cases\": ${hotspot.closedCases},")
        writer.println(s"      \"closure_rate\": ${f"${hotspot.closureRate}%.2f"},")
        writer.println(s"      \"cameras_present\": ${hotspot.camerasPresent},")
        writer.println(s"      \"avg_victim_age\": ${f"${hotspot.avgVictimAge}%.0f"}")
        if (idx < results.locationHotspots.size - 1) {
          writer.println("    },")
        } else {
          writer.println("    }")
        }
      }
      writer.println("  ],")
      
      // Age Group Analysis
      writer.println("  \"age_group_analysis\": [")
      results.ageGroupAnalysis.zipWithIndex.foreach { case (group, idx) =>
        writer.println("    {")
        writer.println(s"      \"age_group\": ${escapeJSON(group.ageGroup)},")
        writer.println(s"      \"total_cases\": ${group.totalCases},")
        writer.println(s"      \"closed_cases\": ${group.closedCases},")
        writer.println(s"      \"open_cases\": ${group.openCases},")
        writer.println(s"      \"closure_rate\": ${f"${group.closureRate}%.2f"},")
        writer.println(s"      \"cameras_present\": ${group.camerasPresent}")
        if (idx < results.ageGroupAnalysis.size - 1) {
          writer.println("    },")
        } else {
          writer.println("    }")
        }
      }
      writer.println("  ],")
      
      // Raw Homicide Data
      writer.println("  \"raw_homicide_data\": [")
      homicides.zipWithIndex.foreach { case (h, idx) =>
        writer.println("    {")
        writer.println(s"      \"number\": ${escapeJSON(h.number)},")
        writer.println(s"      \"date_died\": ${escapeJSON(h.dateDied)},")
        writer.println(s"      \"name\": ${escapeJSON(h.name)},")
        writer.println(s"      \"age\": ${escapeJSON(h.age)},")
        writer.println(s"      \"address\": ${escapeJSON(h.address)},")
        writer.println(s"      \"camera_present\": ${escapeJSON(h.cameraPresent)},")
        writer.println(s"      \"case_status\": ${escapeJSON(h.caseClosed)}")
        if (idx < homicides.size - 1) {
          writer.println("    },")
        } else {
          writer.println("    }")
        }
      }
      writer.println("  ]")
      writer.println("}")
    } finally {
      writer.close()
    }
  }

  def escapeCSV(str: String): String = {
    if (str.contains(",") || str.contains("\"") || str.contains("\n")) {
      "\"" + str.replace("\"", "\"\"") + "\""
    } else {
      str
    }
  }

  def escapeJSON(str: String): String = {
    "\"" + str
      .replace("\\", "\\\\")
      .replace("\"", "\\\"")
      .replace("\n", "\\n")
      .replace("\r", "\\r")
      .replace("\t", "\\t") + "\""
  }

  // Keep your original fetchRealData, getSampleData, analyzeQuestion1, analyzeQuestion2, and normalizeAddress methods
  def fetchRealData(): List[Homicide] = {
    try {
      println("Fetching live data from chamspage.blogspot.com...")
      val url = "http://chamspage.blogspot.com"
      val html = Source.fromURL(url, "UTF-8").mkString
      val lines = html.split("\n")
      val homicides = scala.collection.mutable.ListBuffer[Homicide]()
      var inTable = false
      
      lines.foreach { line =>
        if (line.contains("<table")) {
          inTable = true
        }
        if (inTable && line.contains("<tr>")) {
          val cells = line.split("<td>").map(_.replaceAll("<[^>]*>", "").trim)
          if (cells.length >= 9 && cells(0).matches("\\d+")) {
            homicides += Homicide(
              cells(0),
              cells(1),
              cells(2),
              cells(3),
              cells(4),
              if (cells.length > 7) cells(7) else "None",
              if (cells.length > 8) cells(8) else "Open"
            )
          }
        }
      }
      
      println(s"✓ Retrieved ${homicides.size} records")
      println()
      homicides.toList
    } catch {
      case e: Exception =>
        println(s"✗ Error: ${e.getMessage}")
        println()
        List.empty
    }
  }

  def getSampleData(): List[Homicide] = {
    List(
      Homicide("1", "01/05/25", "John Smith", "17", "1200 block N Broadway", "camera at intersection", "Open"),
      Homicide("2", "01/12/25", "Maria Garcia", "34", "1200 block N Broadway", "None", "Closed"),
      Homicide("3", "01/18/25", "James Johnson", "22", "2500 block E Monument St", "camera at intersection", "Closed"),
      Homicide("4", "02/03/25", "Robert Williams", "45", "2500 block E Monument St", "None", "Open"),
      Homicide("5", "02/14/25", "Michael Brown", "28", "800 block W Baltimore St", "camera at intersection", "Closed"),
      Homicide("6", "03/07/25", "David Jones", "19", "800 block W Baltimore St", "None", "Open"),
      Homicide("7", "03/22/25", "Christopher Davis", "56", "1500 block W North Ave", "camera at intersection", "Closed"),
      Homicide("8", "04/10/25", "Daniel Miller", "31", "1500 block W North Ave", "None", "Open"),
      Homicide("9", "05/15/25", "Matthew Wilson", "42", "3300 block Greenmount Ave", "camera at intersection", "Closed"),
      Homicide("10", "06/20/25", "Anthony Moore", "25", "3300 block Greenmount Ave", "camera at intersection", "Closed"),
      Homicide("11", "07/04/25", "Donald Taylor", "63", "900 block N Carey St", "None", "Open"),
      Homicide("12", "07/18/25", "Mark Anderson", "29", "900 block N Carey St", "camera at intersection", "Closed"),
      Homicide("13", "08/09/25", "Steven Thomas", "38", "1700 block E North Ave", "camera at intersection", "Closed"),
      Homicide("14", "08/22/25", "Paul Jackson", "21", "1700 block E North Ave", "None", "Open"),
      Homicide("15", "09/12/25", "Andrew White", "47", "2100 block W Pratt St", "camera at intersection", "Closed"),
      Homicide("16", "09/25/25", "Joshua Harris", "16", "2100 block W Pratt St", "None", "Open"),
      Homicide("17", "10/08/25", "Kenneth Martin", "52", "4200 block Park Heights Ave", "camera at intersection", "Closed"),
      Homicide("18", "10/15/25", "Kevin Thompson", "26", "4200 block Park Heights Ave", "None", "Open"),
      Homicide("19", "11/03/25", "Brian Garcia", "33", "800 block N Gay St", "camera at intersection", "Closed"),
      Homicide("20", "11/20/25", "George Martinez", "71", "1400 block W Fayette St", "None", "Open"),
      Homicide("21", "12/05/25", "Edward Robinson", "24", "2200 block Druid Hill Ave", "camera at intersection", "Closed"),
      Homicide("22", "12/18/25", "Ronald Clark", "39", "1100 block E Monument St", "None", "Closed"),
      Homicide("23", "01/10/25", "Timothy Rodriguez", "15", "3400 block W Baltimore St", "camera at intersection", "Open"),
      Homicide("24", "02/20/25", "Jason Lewis", "58", "1800 block N Charles St", "None", "Closed"),
      Homicide("25", "03/15/25", "Jeffrey Lee", "27", "1200 block N Broadway", "camera at intersection", "Open")
    )
  }

  // Keep your original analyzeQuestion1, analyzeQuestion2, and normalizeAddress methods here
  // (I'll omit them for brevity, but copy them from your original file)
  
  def normalizeAddress(address: String): String = {
    val blockPattern = "(\\d+)\\s+block\\s+(.+)".r
    address.toLowerCase match {
      case blockPattern(number, street) => 
        s"${number} block ${street.split(" ").take(3).mkString(" ")}".take(35)
      case _ => 
        address.split(" ").filter(_.nonEmpty).take(4).mkString(" ").take(35)
    }
  }

  def analyzeQuestion1(homicides: List[Homicide]): Unit = {
    // Copy your entire analyzeQuestion1 method here
  }

  def analyzeQuestion2(homicides: List[Homicide]): Unit = {
    // Copy your entire analyzeQuestion2 method here
  }

  def runSampleAnalysis(): Unit = {
    // Copy your runSampleAnalysis if needed
  }
}
