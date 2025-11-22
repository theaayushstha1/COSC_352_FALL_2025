import scala.io.Source

/**
 * Baltimore Homicide Data Analysis
 *
 * QUESTION 1: What percentage of homicide cases with surveillance cameras
 *             get closed compared to cases without cameras?
 *
 * QUESTION 2: What are the most dangerous months in Baltimore, and what
 *             is the average victim age by month?
 */

case class HomicideRecord(
  no: String,
  dateDied: String,
  name: String,
  age: String,
  address: String,
  notes: String,
  noViolentHistory: String,
  surveillanceCamera: String,
  caseClosed: String
)

object BaltimoreHomicideAnalysis {
 
  // ============== CSV PARSING ==============
 
  def parseCSV(filename: String): List[HomicideRecord] = {
    try {
      val source = Source.fromFile(filename)
      try {
        source.getLines()
          .drop(1) // Skip header row
          .flatMap { line =>
            val cols = line.split(",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)", -1)
              .map(_.trim.replaceAll("^\"|\"$", ""))
           
            if (cols.length >= 9 && cols(0).nonEmpty) {
              Some(HomicideRecord(
                cols(0), cols(1), cols(2), cols(3), cols(4),
                cols(5), cols(6), cols(7), cols(8)
              ))
            } else None
          }
          .toList
      } finally {
        source.close()
      }
    } catch {
      case e: Exception =>
        println(s"Error reading file: ${e.getMessage}")
        List.empty
    }
  }
 
  def parseMonth(dateStr: String): Option[Int] = {
    try {
      // Expecting format MM/DD/YY
      val parts = dateStr.split("/")
      if (parts.length >= 1) {
        val month = parts(0).toInt
        if (month >= 1 && month <= 12) Some(month) else None
      } else None
    } catch {
      case _: Exception => None
    }
  }
 
  def parseAge(ageStr: String): Option[Int] = {
    try {
      val age = ageStr.toInt
      if (age > 0) Some(age) else None
    } catch {
      case _: Exception => None
    }
  }
 
  // ============== QUESTION 1: CAMERA & CLOSURE ANALYSIS ==============
 
  def analyzeCameraImpact(records: List[HomicideRecord]): Unit = {
    println("\n" + "=" * 70)
    println("QUESTION 1: What percentage of homicide cases with surveillance")
    println("            cameras get closed compared to cases without cameras?")
    println("=" * 70)
   
    val withCameras = records.filter(r =>
      r.surveillanceCamera.nonEmpty &&
      r.surveillanceCamera.toLowerCase.contains("camera")
    )
   
    val withoutCameras = records.filter(r =>
      r.surveillanceCamera.isEmpty ||
      !r.surveillanceCamera.toLowerCase.contains("camera")
    )
   
    val withCamerasClosed = withCameras.count(r =>
      r.caseClosed.toLowerCase == "closed"
    )
   
    val withoutCamerasClosed = withoutCameras.count(r =>
      r.caseClosed.toLowerCase == "closed"
    )
   
    val withCamerasRate = if (withCameras.nonEmpty)
      (withCamerasClosed.toDouble / withCameras.size) * 100
    else 0.0
   
    val withoutCamerasRate = if (withoutCameras.nonEmpty)
      (withoutCamerasClosed.toDouble / withoutCameras.size) * 100
    else 0.0
   
    println(f"\nCases WITH surveillance cameras: ${withCameras.size}")
    println(f"  - Closed: $withCamerasClosed")
    println(f"  - Closure rate: $withCamerasRate%.2f%%")
    println()
    println(f"Cases WITHOUT surveillance cameras: ${withoutCameras.size}")
    println(f"  - Closed: $withoutCamerasClosed")
    println(f"  - Closure rate: $withoutCamerasRate%.2f%%")
    println()
    println(f"ANSWER: Cases with cameras have a $withCamerasRate%.2f%% closure rate")
    println(f"        Cases without cameras have a $withoutCamerasRate%.2f%% closure rate")
    println(f"        Difference: ${withCamerasRate - withoutCamerasRate}%.2f percentage points")
   
    if (withCamerasRate > withoutCamerasRate) {
      println("\n✓ Surveillance cameras correlate with higher case closure rates!")
    } else if (withCamerasRate < withoutCamerasRate) {
      println("\n✗ Surprisingly, cases without cameras close at a higher rate.")
    } else {
      println("\n→ No significant difference between camera presence and closure rate.")
    }
  }
 
  // ============== QUESTION 2: MONTHLY PATTERNS ANALYSIS ==============
 
  def analyzeMonthlyPatterns(records: List[HomicideRecord]): Unit = {
    println("\n" + "=" * 70)
    println("QUESTION 2: What are the most dangerous months in Baltimore,")
    println("            and what is the average victim age by month?")
    println("=" * 70)
   
    val monthNames = Array("", "January", "February", "March", "April",
      "May", "June", "July", "August", "September", "October",
      "November", "December")
   
    val recordsWithMonths = records.flatMap { r =>
      parseMonth(r.dateDied).map(month => (r, month))
    }
   
    val byMonth = recordsWithMonths
      .groupBy(_._2)
      .view
      .mapValues(_.map(_._1))
      .toMap
   
    val monthlyStats = (1 to 12).map { month =>
      val monthRecords = byMonth.getOrElse(month, List.empty)
      val count = monthRecords.size
     
      val ages = monthRecords.flatMap(r => parseAge(r.age))
      val avgAge = if (ages.nonEmpty) ages.sum.toDouble / ages.size else 0.0
     
      (month, monthNames(month), count, avgAge)
    }.sortBy(-_._3) // Sort by count descending
   
    println(f"\n${"Month"}%-12s | ${"Homicides"}%10s | ${"Avg Victim Age"}%15s")
    println("-" * 70)
   
    monthlyStats.foreach { case (monthNum, monthName, count, avgAge) =>
      val ageStr = if (avgAge > 0) f"$avgAge%.1f years" else "N/A"
      println(f"$monthName%-12s | $count%10d | $ageStr%15s")
    }
   
    val totalCount = monthlyStats.map(_._3).sum
    val deadliestMonth = monthlyStats.head
    val safestMonth = monthlyStats.last
   
    val allAges = records.flatMap(r => parseAge(r.age))
    val overallAvgAge = if (allAges.nonEmpty) allAges.sum.toDouble / allAges.size else 0.0
   
    println("\n" + "=" * 70)
    println("ANSWER:")
    println(f"  Most dangerous month: ${deadliestMonth._2} with ${deadliestMonth._3} homicides")
    println(f"  Safest month: ${safestMonth._2} with ${safestMonth._3} homicides")
   
    if (deadliestMonth._4 > 0) {
      println(f"  Average victim age in ${deadliestMonth._2}: ${deadliestMonth._4}%.1f years")
    }
   
    println(f"  Overall average victim age: $overallAvgAge%.1f years")
    println(f"  Total homicides analyzed: $totalCount")
   
    // Find months above/below average
    val avgHomicidesPerMonth = totalCount.toDouble / 12
    val dangerousMonths = monthlyStats.filter(_._3 > avgHomicidesPerMonth)
   
    println(f"\n  ${dangerousMonths.size} months exceed the average of $avgHomicidesPerMonth%.1f homicides/month:")
    dangerousMonths.take(3).foreach { case (_, name, count, _) =>
      println(f"    - $name: $count homicides")
    }
  }
 
  // ============== MAIN PROGRAM ==============
 
  def main(args: Array[String]): Unit = {
    val filename = if (args.length > 0) args(0) else "info_death.csv"
   
    println("=" * 70)
    println("BALTIMORE HOMICIDE DATA ANALYSIS")
    println("Data Source: chamspage.blogspot.com")
    println("=" * 70)
   
    val records = parseCSV(filename)
   
    if (records.isEmpty) {
      println(s"ERROR: Could not load data from '$filename'")
      println("Please ensure the file exists and is properly formatted.")
      sys.exit(1)
    }
   
    println(s"\n✓ Successfully loaded ${records.size} homicide records from $filename")
   
    // Run both analyses
    analyzeCameraImpact(records)
    analyzeMonthlyPatterns(records)
   
    println("\n" + "=" * 70)
    println("ANALYSIS COMPLETE")
    println("=" * 70 + "\n")
  }
}