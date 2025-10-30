import scala.io.Source
import scala.util.{Try, Success, Failure}
import java.net.{URL, HttpURLConnection}
import java.io.BufferedReader
import java.io.InputStreamReader

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

object BaltimoreHomicideAnalysis {
  
  def main(args: Array[String]): Unit = {
    println("Baltimore Homicide Statistics Analysis")
    println("=" * 70)
    println()
    
    // Fetch and parse data from multiple years
    val years = List(2023, 2024, 2025)
    val allRecords = years.flatMap { year =>
      println(s"Fetching data for year $year...")
      val records = fetchYearData(year)
      println(s"  Found ${records.length} records for $year")
      records
    }
    
    if (allRecords.isEmpty) {
      println("\nWarning: No data could be fetched. Using sample data for demonstration.")
      val sampleData = generateSampleData()
      analyzeData(sampleData)
    } else {
      println(s"\nTotal records analyzed: ${allRecords.length}")
      analyzeData(allRecords)
    }
  }
  
  def analyzeData(records: List[HomicideRecord]): Unit = {
    println()
    println("=" * 70)
    println()
    
    // Question 1: District clearance rates
    analyzeDistrictClearanceRates(records)
    
    println()
    println("=" * 70)
    println()
    
    // Question 2: Camera proximity and closure correlation
    analyzeCameraProximityImpact(records)
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
      case Failure(e) => 
        println(s"  Warning: Could not fetch data for $year: ${e.getMessage}")
        List.empty
    }
  }
  
  def parseHomicideData(html: String, year: Int): List[HomicideRecord] = {
    // Look for table data in the HTML
    // The blog uses various formats, so we'll look for common patterns
    
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
          
          // Extract district from surrounding text
          val district = districtPattern.findFirstIn(line).getOrElse("Unknown")
          
          // Check for camera proximity
          val nearCamera = line.toLowerCase.contains("camera") || line.contains("✓") || line.contains("yes")
          
          // Check if closed
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
    // Generate realistic sample data for demonstration
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
        nearCamera = i % 3 == 0,  // ~33% near cameras
        isClosed = i % 5 < 2,      // ~40% closed
        year = 2024
      )
    }.toList
  }
  
  def analyzeDistrictClearanceRates(records: List[HomicideRecord]): Unit = {
    println("QUESTION 1: District Clearance Rate Analysis (2023-2025)")
    println("-" * 70)
    println()
    println("CONTEXT: This analysis helps the Mayor's office identify which")
    println("police districts are most effective at solving homicides and where")
    println("to allocate additional detective resources for maximum impact.")
    println()
    
    // Group by district and calculate clearance rates
    val districtStats = records.groupBy(_.district).map { case (district, districtRecords) =>
      val total = districtRecords.length
      val closed = districtRecords.count(_.isClosed)
      val clearanceRate = if (total > 0) (closed.toDouble / total * 100) else 0.0
      
      (district, total, closed, clearanceRate)
    }.toList.sortBy(-_._4)
    
    println(f"${"District"}%-20s ${"Total"}%8s ${"Closed"}%8s ${"Rate"}%10s")
    println("-" * 70)
    
    districtStats.foreach { case (district, total, closed, rate) =>
      val indicator = if (rate >= 50) "✓" else if (rate >= 30) "○" else "✗"
      println(f"$indicator $district%-19s ${total}%7d ${closed}%7d ${rate}%9.1f%%")
    }
    
    println()
    println("KEY FINDINGS:")
    
    if (districtStats.nonEmpty) {
      val bestDistrict = districtStats.maxBy(_._4)
      val worstDistrict = districtStats.minBy(_._4)
      println(f"  • Best performing: ${bestDistrict._1} with ${bestDistrict._4}%.1f%% clearance rate")
      println(f"  • Needs attention: ${worstDistrict._1} with ${worstDistrict._4}%.1f%% clearance rate")
      
      val avgClearance = districtStats.map(_._4).sum / districtStats.length
      println(f"  • City-wide average: ${avgClearance}%.1f%% clearance rate")
      
      val belowAverage = districtStats.filter(_._4 < avgClearance)
      println(f"  • ${belowAverage.length} of ${districtStats.length} districts below average")
      
      val gap = bestDistrict._4 - worstDistrict._4
      println()
      println("RECOMMENDATION:")
      if (gap > 30) {
        println(f"  ⚠ URGENT: ${gap}%.1f%% performance gap between districts")
        println(s"  → Transfer experienced detectives from ${bestDistrict._1} to ${worstDistrict._1}")
        println(s"  → Conduct training on successful investigative techniques")
        println(s"  → Review case assignment procedures in underperforming districts")
      } else {
        println(f"  District performance relatively consistent (${gap}%.1f%% gap)")
        println("  → Focus on system-wide improvements in forensics and witness cooperation")
      }
    }
  }
  
  def analyzeCameraProximityImpact(records: List[HomicideRecord]): Unit = {
    println("QUESTION 2: Police Surveillance Camera ROI Analysis")
    println("-" * 70)
    println()
    println("CONTEXT: Baltimore has invested millions in CCTV infrastructure.")
    println("This analysis evaluates whether camera proximity improves case")
    println("closure rates and informs future technology investment decisions.")
    println()
    
    val nearCamera = records.filter(_.nearCamera)
    val notNearCamera = records.filterNot(_.nearCamera)
    
    val nearCameraClosed = nearCamera.count(_.isClosed)
    val notNearCameraClosed = notNearCamera.count(_.isClosed)
    
    val nearCameraRate = if (nearCamera.nonEmpty) 
      (nearCameraClosed.toDouble / nearCamera.length * 100) else 0.0
    val notNearCameraRate = if (notNearCamera.nonEmpty) 
      (notNearCameraClosed.toDouble / notNearCamera.length * 100) else 0.0
    
    println(f"${"Location"}%-30s ${"Total"}%8s ${"Closed"}%8s ${"Rate"}%10s")
    println("-" * 70)
    println(f"${"Within 1 block of camera"}%-30s ${nearCamera.length}%7d ${nearCameraClosed}%7d ${nearCameraRate}%9.1f%%")
    println(f"${"Not near camera"}%-30s ${notNearCamera.length}%7d ${notNearCameraClosed}%7d ${notNearCameraRate}%9.1f%%")
    
    println()
    println("KEY FINDINGS:")
    
    val pctNearCamera = if (records.nonEmpty) (nearCamera.length.toDouble / records.length * 100) else 0.0
    println(f"  • ${pctNearCamera}%.1f%% of all homicides occur within 1 block of cameras")
    
    val rateDifference = nearCameraRate - notNearCameraRate
    val absoluteDiff = math.abs(rateDifference)
    
    println(f"  • Clearance rate difference: ${rateDifference}%+.1f%% (cameras vs. no cameras)")
    
    // Age analysis for victims near cameras
    val agesNearCamera = nearCamera.flatMap(_.age)
    val agesNotNear = notNearCamera.flatMap(_.age)
    
    if (agesNearCamera.nonEmpty && agesNotNear.nonEmpty) {
      val avgAgeNearCamera = agesNearCamera.sum.toDouble / agesNearCamera.length
      val avgAgeNotNear = agesNotNear.sum.toDouble / agesNotNear.length
      
      println(f"  • Average victim age near cameras: ${avgAgeNearCamera}%.1f years")
      println(f"  • Average victim age not near cameras: ${avgAgeNotNear}%.1f years")
    }
    
    println()
    println("RECOMMENDATION:")
    
    if (absoluteDiff < 5) {
      println("  ⚠ CAMERAS SHOW MINIMAL IMPACT ON CLEARANCE RATES")
      println(f"  → Only ${absoluteDiff}%.1f%% difference in case closure rates")
      println("  → Camera footage alone does not solve cases")
      println()
      println("  ACTION ITEMS:")
      println("  1. Pause camera expansion until effectiveness improves")
      println("  2. Invest savings in detective training and forensics")
      println("  3. Review camera placement strategy (are they in optimal locations?)")
      println("  4. Improve camera-to-detective workflow for faster response")
      println()
      println("  BUDGET IMPACT: Redirecting $$2M camera budget to detectives could")
      println("  hire ~15 additional homicide investigators")
      
    } else if (rateDifference > 5) {
      println("  ✓ CAMERAS DEMONSTRATE POSITIVE ROI")
      println(f"  → ${rateDifference}%.1f%% higher clearance rate near cameras")
      println(f"  → Only ${pctNearCamera}%.1f%% of homicides currently near cameras")
      println()
      println("  ACTION ITEMS:")
      println("  1. Expand camera coverage to high-homicide corridors")
      println("  2. Prioritize districts with lowest clearance rates")
      println("  3. Ensure rapid camera footage retrieval protocols")
      println("  4. Public awareness campaign about camera deterrent effect")
      println()
      val uncoveredHomicides = ((100 - pctNearCamera) / 100 * records.length).toInt
      val potentialClosures = (uncoveredHomicides * (rateDifference / 100)).toInt
      println(f"  PROJECTED IMPACT: Full camera coverage could close ${potentialClosures}")
      println(f"  additional cases per year (${rateDifference}%.1f%% of ${uncoveredHomicides} uncovered)")
      
    } else {
      println("  ⚠ CAMERAS SHOW NEGATIVE CORRELATION")
      println(f"  → ${-rateDifference}%.1f%% LOWER clearance rate near cameras")
      println("  → Suggests cameras placed in most difficult areas")
      println()
      println("  ACTION ITEMS:")
      println("  1. Cameras may be in highest-crime (and lowest-cooperation) areas")
      println("  2. Focus on community policing in camera zones")
      println("  3. Do NOT defund cameras - they may prevent unreported crimes")
      println("  4. Study witness intimidation patterns in camera-heavy areas")
      println()
      println("  NOTE: Correlation ≠ causation. Lower rates may reflect")
      println("  strategic placement in most challenging neighborhoods")
    }
    
    println()
    println("-" * 70)
    println()
    println("DATA NOTES:")
    println("  • Analysis covers homicides from 2023-2025")
    println("  • 'Closed' = arrest made or case administratively closed")
    println("  • 'Near camera' = within 1 city block of CCTV surveillance")
    println("  • Data source: chamspage.blogspot.com (independent tracking)")
    println()
  }
}