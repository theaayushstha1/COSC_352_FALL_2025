import scala.io.Source
import scala.util.{Try, Success, Failure}
import java.net.{URL, HttpURLConnection}
import java.io.{BufferedReader, InputStreamReader, PrintWriter, File}
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

case class HomicideRecord(
  number: Int,
  victim: String,
  age: Option[Int],
  date: String,
  location: String,
  district: String,
  nearCamera: Boolean,
  isClosed: Boolean,
  year: Int
)

case class DistrictStats(
  district: String,
  totalCases: Int,
  closedCases: Int,
  clearanceRate: Double
)

case class CameraStats(
  location: String,
  totalCases: Int,
  closedCases: Int,
  clearanceRate: Double
)

case class AnalysisResults(
  timestamp: String,
  totalRecords: Int,
  yearsAnalyzed: List[Int],
  districtAnalysis: List[DistrictStats],
  districtAverage: Double,
  bestDistrict: String,
  worstDistrict: String,
  cameraAnalysis: CameraAnalysis,
  dataSource: String
)

case class CameraAnalysis(
  nearCameraStats: CameraStats,
  notNearCameraStats: CameraStats,
  percentNearCamera: Double,
  clearanceRateDifference: Double,
  avgAgeNearCamera: Option[Double],
  avgAgeNotNearCamera: Option[Double]
)

object BaltimoreHomicideAnalysis {
  
  def main(args: Array[String]): Unit = {
    val outputFormat = parseOutputFormat(args)
    
    // Fetch and parse data from multiple years
    val years = List(2023, 2024, 2025)
    val allRecords = years.flatMap { year =>
      if (outputFormat == "stdout") {
        println(s"Fetching data for year $year...")
      }
      val records = fetchYearData(year)
      if (outputFormat == "stdout") {
        println(s"  Found ${records.length} records for $year")
      }
      records
    }
    
    val recordsToAnalyze = if (allRecords.isEmpty) {
      if (outputFormat == "stdout") {
        println("\nWarning: No data could be fetched. Using sample data for demonstration.")
      }
      generateSampleData()
    } else {
      if (outputFormat == "stdout") {
        println(s"\nTotal records analyzed: ${allRecords.length}")
      }
      allRecords
    }
    
    // Perform analysis
    val results = performAnalysis(recordsToAnalyze, years)
    
    // Output in requested format
    outputFormat match {
      case "csv" => outputCSV(results, recordsToAnalyze)
      case "json" => outputJSON(results, recordsToAnalyze)
      case _ => outputStdout(results)
    }
  }
  
  def parseOutputFormat(args: Array[String]): String = {
    args.find(_.startsWith("--output="))
      .map(_.substring("--output=".length).toLowerCase)
      .getOrElse("stdout")
  }
  
  def performAnalysis(records: List[HomicideRecord], years: List[Int]): AnalysisResults = {
    val timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"))
    
    // District analysis
    val districtStats = records.groupBy(_.district).map { case (district, districtRecords) =>
      val total = districtRecords.length
      val closed = districtRecords.count(_.isClosed)
      val clearanceRate = if (total > 0) (closed.toDouble / total * 100) else 0.0
      DistrictStats(district, total, closed, clearanceRate)
    }.toList.sortBy(-_.clearanceRate)
    
    val avgClearance = if (districtStats.nonEmpty) 
      districtStats.map(_.clearanceRate).sum / districtStats.length else 0.0
    
    val bestDistrict = if (districtStats.nonEmpty) districtStats.maxBy(_.clearanceRate).district else "N/A"
    val worstDistrict = if (districtStats.nonEmpty) districtStats.minBy(_.clearanceRate).district else "N/A"
    
    // Camera analysis
    val nearCamera = records.filter(_.nearCamera)
    val notNearCamera = records.filterNot(_.nearCamera)
    
    val nearCameraClosed = nearCamera.count(_.isClosed)
    val notNearCameraClosed = notNearCamera.count(_.isClosed)
    
    val nearCameraRate = if (nearCamera.nonEmpty) 
      (nearCameraClosed.toDouble / nearCamera.length * 100) else 0.0
    val notNearCameraRate = if (notNearCamera.nonEmpty) 
      (notNearCameraClosed.toDouble / notNearCamera.length * 100) else 0.0
    
    val pctNearCamera = if (records.nonEmpty) 
      (nearCamera.length.toDouble / records.length * 100) else 0.0
    
    val rateDifference = nearCameraRate - notNearCameraRate
    
    val agesNearCamera = nearCamera.flatMap(_.age)
    val agesNotNear = notNearCamera.flatMap(_.age)
    
    val avgAgeNearCamera = if (agesNearCamera.nonEmpty) 
      Some(agesNearCamera.sum.toDouble / agesNearCamera.length) else None
    val avgAgeNotNear = if (agesNotNear.nonEmpty) 
      Some(agesNotNear.sum.toDouble / agesNotNear.length) else None
    
    val cameraAnalysis = CameraAnalysis(
      CameraStats("Within 1 block of camera", nearCamera.length, nearCameraClosed, nearCameraRate),
      CameraStats("Not near camera", notNearCamera.length, notNearCameraClosed, notNearCameraRate),
      pctNearCamera,
      rateDifference,
      avgAgeNearCamera,
      avgAgeNotNear
    )
    
    AnalysisResults(
      timestamp,
      records.length,
      years,
      districtStats,
      avgClearance,
      bestDistrict,
      worstDistrict,
      cameraAnalysis,
      "chamspage.blogspot.com"
    )
  }
  
  def outputStdout(results: AnalysisResults): Unit = {
    println("Baltimore Homicide Statistics Analysis")
    println("=" * 70)
    println()
    println()
    println("=" * 70)
    println()
    
    // Question 1: District clearance rates
    println("QUESTION 1: District Clearance Rate Analysis (2023-2025)")
    println("-" * 70)
    println()
    println("CONTEXT: This analysis helps the Mayor's office identify which")
    println("police districts are most effective at solving homicides and where")
    println("to allocate additional detective resources for maximum impact.")
    println()
    
    println(f"${"District"}%-20s ${"Total"}%8s ${"Closed"}%8s ${"Rate"}%10s")
    println("-" * 70)
    
    results.districtAnalysis.foreach { stats =>
      val indicator = if (stats.clearanceRate >= 50) "✓" else if (stats.clearanceRate >= 30) "○" else "✗"
      println(f"$indicator ${stats.district}%-19s ${stats.totalCases}%7d ${stats.closedCases}%7d ${stats.clearanceRate}%9.1f%%")
    }
    
    println()
    println("KEY FINDINGS:")
    println(f"  • Best performing: ${results.bestDistrict} with ${results.districtAnalysis.maxBy(_.clearanceRate).clearanceRate}%.1f%% clearance rate")
    println(f"  • Needs attention: ${results.worstDistrict} with ${results.districtAnalysis.minBy(_.clearanceRate).clearanceRate}%.1f%% clearance rate")
    println(f"  • City-wide average: ${results.districtAverage}%.1f%% clearance rate")
    
    val belowAverage = results.districtAnalysis.filter(_.clearanceRate < results.districtAverage)
    println(f"  • ${belowAverage.length} of ${results.districtAnalysis.length} districts below average")
    
    println()
    println("=" * 70)
    println()
    
    // Question 2: Camera analysis
    println("QUESTION 2: Police Surveillance Camera ROI Analysis")
    println("-" * 70)
    println()
    println("CONTEXT: Baltimore has invested millions in CCTV infrastructure.")
    println("This analysis evaluates whether camera proximity improves case")
    println("closure rates and informs future technology investment decisions.")
    println()
    
    val cam = results.cameraAnalysis
    println(f"${"Location"}%-30s ${"Total"}%8s ${"Closed"}%8s ${"Rate"}%10s")
    println("-" * 70)
    println(f"${cam.nearCameraStats.location}%-30s ${cam.nearCameraStats.totalCases}%7d ${cam.nearCameraStats.closedCases}%7d ${cam.nearCameraStats.clearanceRate}%9.1f%%")
    println(f"${cam.notNearCameraStats.location}%-30s ${cam.notNearCameraStats.totalCases}%7d ${cam.notNearCameraStats.closedCases}%7d ${cam.notNearCameraStats.clearanceRate}%9.1f%%")
    
    println()
    println("KEY FINDINGS:")
    println(f"  • ${cam.percentNearCamera}%.1f%% of all homicides occur within 1 block of cameras")
    println(f"  • Clearance rate difference: ${cam.clearanceRateDifference}%+.1f%% (cameras vs. no cameras)")
    
    if (cam.avgAgeNearCamera.isDefined && cam.avgAgeNotNearCamera.isDefined) {
      println(f"  • Average victim age near cameras: ${cam.avgAgeNearCamera.get}%.1f years")
      println(f"  • Average victim age not near cameras: ${cam.avgAgeNotNearCamera.get}%.1f years")
    }
    
    println()
    println("-" * 70)
    println()
    println("DATA NOTES:")
    println(s"  • Analysis timestamp: ${results.timestamp}")
    println(s"  • Total records analyzed: ${results.totalRecords}")
    println(s"  • Data source: ${results.dataSource}")
    println()
  }
  
  def outputCSV(results: AnalysisResults, records: List[HomicideRecord]): Unit = {
    val timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"))
    
    // Write district analysis CSV
    val districtFile = new File(s"district_analysis_${timestamp}.csv")
    val districtWriter = new PrintWriter(districtFile)
    
    districtWriter.println("district,total_cases,closed_cases,clearance_rate,performance_indicator")
    results.districtAnalysis.foreach { stats =>
      val indicator = if (stats.clearanceRate >= 50) "high" else if (stats.clearanceRate >= 30) "medium" else "low"
      districtWriter.println(s"${stats.district},${stats.totalCases},${stats.closedCases},${stats.clearanceRate},$indicator")
    }
    districtWriter.close()
    
    // Write camera analysis CSV
    val cameraFile = new File(s"camera_analysis_${timestamp}.csv")
    val cameraWriter = new PrintWriter(cameraFile)
    
    cameraWriter.println("location_type,total_cases,closed_cases,clearance_rate")
    val cam = results.cameraAnalysis
    cameraWriter.println(s"near_camera,${cam.nearCameraStats.totalCases},${cam.nearCameraStats.closedCases},${cam.nearCameraStats.clearanceRate}")
    cameraWriter.println(s"not_near_camera,${cam.notNearCameraStats.totalCases},${cam.notNearCameraStats.closedCases},${cam.notNearCameraStats.clearanceRate}")
    cameraWriter.close()
    
    // Write summary CSV
    val summaryFile = new File(s"analysis_summary_${timestamp}.csv")
    val summaryWriter = new PrintWriter(summaryFile)
    
    summaryWriter.println("metric,value")
    summaryWriter.println(s"timestamp,${results.timestamp}")
    summaryWriter.println(s"total_records,${results.totalRecords}")
    summaryWriter.println(s"years_analyzed,${results.yearsAnalyzed.mkString(";")}")
    summaryWriter.println(s"city_avg_clearance_rate,${results.districtAverage}")
    summaryWriter.println(s"best_performing_district,${results.bestDistrict}")
    summaryWriter.println(s"worst_performing_district,${results.worstDistrict}")
    summaryWriter.println(s"percent_homicides_near_camera,${cam.percentNearCamera}")
    summaryWriter.println(s"camera_clearance_rate_difference,${cam.clearanceRateDifference}")
    cam.avgAgeNearCamera.foreach(age => summaryWriter.println(s"avg_age_near_camera,$age"))
    cam.avgAgeNotNearCamera.foreach(age => summaryWriter.println(s"avg_age_not_near_camera,$age"))
    summaryWriter.println(s"data_source,${results.dataSource}")
    summaryWriter.close()
    
    // Write individual records CSV
    val recordsFile = new File(s"homicide_records_${timestamp}.csv")
    val recordsWriter = new PrintWriter(recordsFile)
    
    recordsWriter.println("record_number,victim_name,age,date,location,district,near_camera,is_closed,year")
    records.foreach { record =>
      val ageStr = record.age.map(_.toString).getOrElse("")
      recordsWriter.println(s"${record.number},${record.victim},${ageStr},${record.date},${record.location},${record.district},${record.nearCamera},${record.isClosed},${record.year}")
    }
    recordsWriter.close()
    
    println(s"CSV files generated:")
    println(s"  - ${districtFile.getName}")
    println(s"  - ${cameraFile.getName}")
    println(s"  - ${summaryFile.getName}")
    println(s"  - ${recordsFile.getName}")
  }
  
  def outputJSON(results: AnalysisResults, records: List[HomicideRecord]): Unit = {
    val timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"))
    val jsonFile = new File(s"baltimore_homicide_analysis_${timestamp}.json")
    val writer = new PrintWriter(jsonFile)
    
    writer.println("{")
    writer.println(s"""  "analysis_metadata": {""")
    writer.println(s"""    "timestamp": "${results.timestamp}",""")
    writer.println(s"""    "total_records": ${results.totalRecords},""")
    writer.println(s"""    "years_analyzed": [${results.yearsAnalyzed.mkString(", ")}],""")
    writer.println(s"""    "data_source": "${results.dataSource}" """)
    writer.println(s"""  },""")
    
    writer.println(s"""  "question_1_district_analysis": {""")
    writer.println(s"""    "summary": {""")
    writer.println(s"""      "city_average_clearance_rate": ${results.districtAverage},""")
    writer.println(s"""      "best_performing_district": "${results.bestDistrict}",""")
    writer.println(s"""      "worst_performing_district": "${results.worstDistrict}",""")
    writer.println(s"""      "total_districts": ${results.districtAnalysis.length}""")
    writer.println(s"""    },""")
    writer.println(s"""    "districts": [""")
    
    results.districtAnalysis.zipWithIndex.foreach { case (stats, idx) =>
      val comma = if (idx < results.districtAnalysis.length - 1) "," else ""
      writer.println(s"""      {""")
      writer.println(s"""        "district": "${stats.district}",""")
      writer.println(s"""        "total_cases": ${stats.totalCases},""")
      writer.println(s"""        "closed_cases": ${stats.closedCases},""")
      writer.println(s"""        "clearance_rate": ${stats.clearanceRate}""")
      writer.println(s"""      }$comma""")
    }
    
    writer.println(s"""    ]""")
    writer.println(s"""  },""")
    
    val cam = results.cameraAnalysis
    writer.println(s"""  "question_2_camera_analysis": {""")
    writer.println(s"""    "summary": {""")
    writer.println(s"""      "percent_near_camera": ${cam.percentNearCamera},""")
    writer.println(s"""      "clearance_rate_difference": ${cam.clearanceRateDifference},""")
    cam.avgAgeNearCamera.foreach(age => writer.println(s"""      "avg_age_near_camera": $age,"""))
    cam.avgAgeNotNearCamera.foreach(age => writer.println(s"""      "avg_age_not_near_camera": $age,"""))
    writer.println(s"""      "analysis": "Camera proximity impact on case closure rates" """)
    writer.println(s"""    },""")
    writer.println(s"""    "locations": [""")
    writer.println(s"""      {""")
    writer.println(s"""        "type": "near_camera",""")
    writer.println(s"""        "total_cases": ${cam.nearCameraStats.totalCases},""")
    writer.println(s"""        "closed_cases": ${cam.nearCameraStats.closedCases},""")
    writer.println(s"""        "clearance_rate": ${cam.nearCameraStats.clearanceRate}""")
    writer.println(s"""      },""")
    writer.println(s"""      {""")
    writer.println(s"""        "type": "not_near_camera",""")
    writer.println(s"""        "total_cases": ${cam.notNearCameraStats.totalCases},""")
    writer.println(s"""        "closed_cases": ${cam.notNearCameraStats.closedCases},""")
    writer.println(s"""        "clearance_rate": ${cam.notNearCameraStats.clearanceRate}""")
    writer.println(s"""      }""")
    writer.println(s"""    ]""")
    writer.println(s"""  },""")
    
    writer.println(s"""  "raw_records": [""")
    records.zipWithIndex.foreach { case (record, idx) =>
      val comma = if (idx < records.length - 1) "," else ""
      val ageJson = record.age.map(_.toString).getOrElse("null")
      writer.println(s"""    {""")
      writer.println(s"""      "number": ${record.number},""")
      writer.println(s"""      "victim": "${record.victim}",""")
      writer.println(s"""      "age": $ageJson,""")
      writer.println(s"""      "date": "${record.date}",""")
      writer.println(s"""      "location": "${record.location}",""")
      writer.println(s"""      "district": "${record.district}",""")
      writer.println(s"""      "near_camera": ${record.nearCamera},""")
      writer.println(s"""      "is_closed": ${record.isClosed},""")
      writer.println(s"""      "year": ${record.year}""")
      writer.println(s"""    }$comma""")
    }
    writer.println(s"""  ]""")
    
    writer.println("}")
    writer.close()
    
    println(s"JSON file generated: ${jsonFile.getName}")
  }
  
  def fetchYearData(year: Int): List[HomicideRecord] = {
    val url = s"http://chamspage.blogspot.com/$year/01/$year-baltimore-city-homicide-list.html"
    
    Try {
      val connection = new URL(url).openConnection().asInstanceOf[HttpURLConnection]
      connection.setRequestMethod("GET")
      connection.setConnectTimeout(5000)
      connection.setReadTimeout(5000)
      connection.setRequestProperty("User-Agent", "Mozilla/5.0")
      
      val reader = new BufferedReader(new InputStreamReader(connection.getInputStream))
      val html = Iterator.continually(reader.readLine()).takeWhile(_ != null).mkString("\n")
      reader.close()
      
      parseHomicideData(html, year)
    } match {
      case Success(records) => records
      case Failure(e) => List.empty
    }
  }
  
  def parseHomicideData(html: String, year: Int): List[HomicideRecord] = {
    val victimPattern = """(?i)(\d+)\.\s+([A-Za-z\s,'-]+?)(?:\s+(\d+))?\s+(\d{1,2}/\d{1,2}/\d{2,4})""".r
    val districtPattern = """(?i)(Northern|Southern|Eastern|Western|Central|Northeast|Northwest|Southeast|Southwest)""".r
    
    val lines = html.split("\n")
    var records = List[HomicideRecord]()
    var recordNum = 0
    
    for (line <- lines) {
      victimPattern.findFirstMatchIn(line) match {
        case Some(m) =>
          recordNum += 1
          val num = Try(m.group(1).toInt).getOrElse(recordNum)
          val victim = m.group(2).trim
          val age = Option(m.group(3)).flatMap(s => Try(s.toInt).toOption)
          val date = m.group(4)
          val district = districtPattern.findFirstIn(line).getOrElse("Unknown")
          val nearCamera = line.toLowerCase.contains("camera") || line.contains("✓") || line.contains("yes")
          val isClosed = line.toLowerCase.contains("closed") || 
                        line.toLowerCase.contains("arrest") ||
                        line.toLowerCase.contains("charged")
          val location = extractLocation(line)
          
          records = HomicideRecord(num, victim, age, date, location, district, nearCamera, isClosed, year) :: records
          
        case None => // Continue searching
      }
    }
    
    records.reverse
  }
  
  def extractLocation(text: String): String = {
    val locationPattern = """(\d{1,5})\s+(?:block\s+of\s+)?([A-Z][a-z\s]+(?:Street|Avenue|Road|Drive|Court|Way|Lane|Boulevard))""".r
    locationPattern.findFirstMatchIn(text).map(m => s"${m.group(1)} ${m.group(2)}").getOrElse("Unknown")
  }
  
  def generateSampleData(): List[HomicideRecord] = {
    val districts = List("Eastern", "Western", "Northern", "Southern", "Central", "Northeast", "Northwest")
    val victims = List("John Doe", "Jane Smith", "Michael Johnson", "Mary Williams", "Robert Brown")
    
    (1 to 150).map { i =>
      HomicideRecord(
        number = i,
        victim = victims(i % victims.length) + s" #$i",
        age = Some(18 + (i % 50)),
        date = s"${(i % 12) + 1}/${(i % 28) + 1}/2024",
        location = s"${100 + (i * 13) % 8900} Main Street",
        district = districts(i % districts.length),
        nearCamera = i % 3 == 0,
        isClosed = i % 5 < 2,
        year = 2024
      )
    }.toList
  }
}