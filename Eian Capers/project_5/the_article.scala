import scala.io.Source
import java.io.{File, PrintWriter}

/**
 * Baltimore Homicide Data Analysis
 *
 * QUESTION 1: What percentage of homicide cases with surveillance cameras
 *             get closed compared to cases without cameras?
 *
 * QUESTION 2: What are the most dangerous months in Baltimore, and what
 *             is the average victim age by month?
 */

object BaltimoreHomicideAnalysis {
  
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
  
  case class CameraStats(
    withTotal: Int, 
    withClosed: Int, 
    withRate: Double,
    withoutTotal: Int, 
    withoutClosed: Int, 
    withoutRate: Double,
    diff: Double
  )
  
  case class MonthStats(
    monthNum: Int,
    monthName: String,
    count: Int,
    avgAge: Option[Double]
  )
  
  def main(args: Array[String]): Unit = {
    try {
      val outputFormat = parseArgs(args)
      
      val csvFile = "info_death.csv"
      val records = parseCSV(csvFile)
      
      if (records.isEmpty) {
        println("ERROR: Could not load data from CSV file")
        sys.exit(1)
      }
      
      val cameraStats = computeCameraStats(records)
      val monthlyStats = computeMonthlyStats(records)
      
      outputFormat match {
        case "csv" => outputCSV(records, cameraStats, monthlyStats)
        case "json" => outputJSON(records, cameraStats, monthlyStats)
        case _ => outputStdout(records, cameraStats, monthlyStats)
      }
      
    } catch {
      case e: Exception =>
        println(s"Error: ${e.getMessage}")
        e.printStackTrace()
    }
  }
  
  def parseArgs(args: Array[String]): String = {
    args.find(_.startsWith("--output=")) match {
      case Some(arg) => 
        val format = arg.split("=")(1).toLowerCase
        if (format == "csv" || format == "json") format else "stdout"
      case None => "stdout"
    }
  }
  
  def parseCSV(filename: String): List[HomicideRecord] = {
    try {
      val source = Source.fromFile(filename)
      try {
        source.getLines()
          .drop(1)
          .flatMap { line =>
            val cols = parseCSVLine(line)
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
  
  def parseCSVLine(line: String): Array[String] = {
    val result = scala.collection.mutable.ArrayBuffer[String]()
    var current = new StringBuilder()
    var inQuotes = false
    var i = 0
    
    while (i < line.length) {
      val c = line.charAt(i)
      
      if (c == '"') {
        inQuotes = !inQuotes
      } else if (c == ',' && !inQuotes) {
        result += current.toString().trim
        current = new StringBuilder()
      } else {
        current += c
      }
      i += 1
    }
    result += current.toString().trim
    
    result.toArray
  }
  
  def parseMonth(dateStr: String): Option[Int] = {
    try {
      val parts = dateStr.split("/")
      if (parts.length >= 1 && parts(0).nonEmpty) {
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
  
  def computeCameraStats(records: List[HomicideRecord]): CameraStats = {
    val withCameras = records.filter(r =>
      r.surveillanceCamera.nonEmpty &&
      r.surveillanceCamera.toLowerCase.contains("camera")
    )
    val withoutCameras = records.filter(r =>
      r.surveillanceCamera.isEmpty ||
      !r.surveillanceCamera.toLowerCase.contains("camera")
    )
    val withCamerasClosed = withCameras.count(r => r.caseClosed.toLowerCase == "closed")
    val withoutCamerasClosed = withoutCameras.count(r => r.caseClosed.toLowerCase == "closed")
    val withCamerasRate = if (withCameras.nonEmpty) (withCamerasClosed.toDouble / withCameras.size) * 100 else 0.0
    val withoutCamerasRate = if (withoutCameras.nonEmpty) (withoutCamerasClosed.toDouble / withoutCameras.size) * 100 else 0.0
    
    CameraStats(
      withCameras.size, withCamerasClosed, withCamerasRate,
      withoutCameras.size, withoutCamerasClosed, withoutCamerasRate,
      withCamerasRate - withoutCamerasRate
    )
  }
  
  def computeMonthlyStats(records: List[HomicideRecord]): List[MonthStats] = {
    val monthNames = Array("", "January", "February", "March", "April",
      "May", "June", "July", "August", "September", "October",
      "November", "December")
    
    val recordsWithMonths = records.flatMap { r =>
      parseMonth(r.dateDied).map(month => (r, month))
    }
    val byMonth = recordsWithMonths.groupBy(_._2).view.mapValues(_.map(_._1)).toMap
    
    (1 to 12).toList.map { m =>
      val recs = byMonth.getOrElse(m, List.empty)
      val ages = recs.flatMap(r => parseAge(r.age))
      val avg = if (ages.nonEmpty) Some(ages.sum.toDouble / ages.size) else None
      MonthStats(m, monthNames(m), recs.size, avg)
    }.sortBy(-_.count)
  }
  
  def outputStdout(records: List[HomicideRecord], cameraStats: CameraStats, monthlyStats: List[MonthStats]): Unit = {
    println("="*70)
    println("BALTIMORE HOMICIDE DATA ANALYSIS")
    println("Data Source: chamspage.blogspot.com")
    println("="*70)
    println(s"\n✓ Successfully loaded ${records.length} homicide records\n")
    
    println("="*70)
    println("QUESTION 1: What percentage of homicide cases with surveillance")
    println("            cameras get closed compared to cases without cameras?")
    println("="*70)
    
    println(f"\nCases WITH surveillance cameras: ${cameraStats.withTotal}")
    println(f"  - Closed: ${cameraStats.withClosed}")
    println(f"  - Closure rate: ${cameraStats.withRate}%.2f%%")
    println()
    println(f"Cases WITHOUT surveillance cameras: ${cameraStats.withoutTotal}")
    println(f"  - Closed: ${cameraStats.withoutClosed}")
    println(f"  - Closure rate: ${cameraStats.withoutRate}%.2f%%")
    println()
    println(f"ANSWER: Cases with cameras have a ${cameraStats.withRate}%.2f%% closure rate")
    println(f"        Cases without cameras have a ${cameraStats.withoutRate}%.2f%% closure rate")
    println(f"        Difference: ${cameraStats.diff}%.2f percentage points")
    
    if (cameraStats.withRate > cameraStats.withoutRate) {
      println("\n✓ Surveillance cameras correlate with higher case closure rates!")
    } else if (cameraStats.withRate < cameraStats.withoutRate) {
      println("\n✗ Surprisingly, cases without cameras close at a higher rate.")
    } else {
      println("\n→ No significant difference between camera presence and closure rate.")
    }
    
    println("\n" + "="*70)
    println("QUESTION 2: What are the most dangerous months in Baltimore,")
    println("            and what is the average victim age by month?")
    println("="*70)
    
    println(f"\n${"Month"}%-12s | ${"Homicides"}%10s | ${"Avg Victim Age"}%15s")
    println("-"*70)
    
    monthlyStats.foreach { stat =>
      val ageStr = stat.avgAge.map(a => f"$a%.1f years").getOrElse("N/A")
      println(f"${stat.monthName}%-12s | ${stat.count}%10d | $ageStr%15s")
    }
    
    val totalCount = monthlyStats.map(_.count).sum
    val deadliest = monthlyStats.head
    val safest = monthlyStats.last
    
    println()
    println(f"ANSWER: Most dangerous month: ${deadliest.monthName} with ${deadliest.count} homicides")
    println(f"        Safest month: ${safest.monthName} with ${safest.count} homicides")
    
    val allAges = records.flatMap(r => parseAge(r.age))
    val overallAvgAge = if (allAges.nonEmpty) allAges.sum.toDouble / allAges.size else 0.0
    println(f"        Overall average victim age: $overallAvgAge%.1f years")
    
    val avgPerMonth = totalCount.toDouble / 12.0
    val dangerousMonths = monthlyStats.filter(_.count > avgPerMonth)
    println(f"\n✓ ${dangerousMonths.size} months are above average (>${avgPerMonth}%.1f homicides/month)")
    println(f"  Dangerous months: ${dangerousMonths.map(_.monthName).mkString(", ")}")
    
    println("\n" + "="*70)
    println("ANALYSIS COMPLETE")
    println("="*70 + "\n")
  }
  
  def outputCSV(records: List[HomicideRecord], cameraStats: CameraStats, monthlyStats: List[MonthStats]): Unit = {
    val writer = new PrintWriter("analysis_summary.csv")
    
    try {
      writer.println("Baltimore Homicide Analysis Report")
      writer.println(s"Total Records,${records.length}")
      writer.println()
      
      writer.println("QUESTION 1: What percentage of homicide cases with surveillance cameras get closed compared to cases without cameras?")
      writer.println()
      writer.println("Camera Analysis")
      writer.println("Category,Total Cases,Cases Closed,Closure Rate (%)")
      writer.println(s"""WITH cameras,${cameraStats.withTotal},${cameraStats.withClosed},${f"${cameraStats.withRate}%.2f"}""")
      writer.println(s"""WITHOUT cameras,${cameraStats.withoutTotal},${cameraStats.withoutClosed},${f"${cameraStats.withoutRate}%.2f"}""")
      writer.println(s"""Difference (percentage points),,,${f"${cameraStats.diff}%.2f"}""")
      writer.println()
      
      writer.println("QUESTION 2: What are the most dangerous months in Baltimore and what is the average victim age by month?")
      writer.println()
      writer.println("Monthly Analysis")
      writer.println("Month,Homicides,Average Victim Age")
      monthlyStats.foreach { stat =>
        val ageStr = stat.avgAge.map(a => f"$a%.1f").getOrElse("N/A")
        writer.println(s"${stat.monthName},${stat.count},$ageStr")
      }
      writer.println()
      
      val dangerous = monthlyStats.filter(_.count > monthlyStats.map(_.count).sum.toDouble / 12.0).take(5)
      writer.println("Top Dangerous Months")
      writer.println("Rank,Month,Homicides")
      dangerous.zipWithIndex.foreach { case (stat, idx) =>
        writer.println(s"${idx + 1},${stat.monthName},${stat.count}")
      }
      
      println("\n✓ Wrote analysis CSV -> analysis_summary.csv")
      
    } finally {
      writer.close()
    }
  }
  
  def outputJSON(records: List[HomicideRecord], cameraStats: CameraStats, monthlyStats: List[MonthStats]): Unit = {
    val writer = new PrintWriter("analysis_summary.json")
    
    try {
      writer.println("{")
      writer.println(s"""  "analysis": "Baltimore Homicide Data Analysis",""")
      writer.println(s"""  "dataSource": "chamspage.blogspot.com",""")
      writer.println(s"""  "totalRecords": ${records.length},""")
      writer.println()
      
      // Camera Analysis
      writer.println(s"""  "cameraAnalysis": {""")
      writer.println(s"""    "withCamera": {""")
      writer.println(s"""      "totalCases": ${cameraStats.withTotal},""")
      writer.println(s"""      "casesClosed": ${cameraStats.withClosed},""")
      writer.println(f"""      "closureRate": ${cameraStats.withRate}%.2f""")
      writer.println(s"""    },""")
      writer.println(s"""    "withoutCamera": {""")
      writer.println(s"""      "totalCases": ${cameraStats.withoutTotal},""")
      writer.println(s"""      "casesClosed": ${cameraStats.withoutClosed},""")
      writer.println(f"""      "closureRate": ${cameraStats.withoutRate}%.2f""")
      writer.println(s"""    },""")
      writer.println(f"""    "closureRateDifference": ${cameraStats.diff}%.2f""")
      writer.println(s"""  },""")
      writer.println()
      
      // Monthly Statistics
      writer.println(s"""  "monthlyStatistics": [""")
      monthlyStats.zipWithIndex.foreach { case (stat, idx) =>
        val comma = if (idx < monthlyStats.length - 1) "," else ""
        writer.println(s"""    {""")
        writer.println(s"""      "month": ${stat.monthNum},""")
        writer.println(s"""      "monthName": "${stat.monthName}",""")
        writer.println(s"""      "homicideCount": ${stat.count},""")
        val ageStr = stat.avgAge.map(a => f"$a%.2f").getOrElse("null")
        writer.println(s"""      "averageVictimAge": $ageStr""")
        writer.println(s"""    }$comma""")
      }
      writer.println(s"""  ],""")
      writer.println()
      
      // Summary
      val deadliest = monthlyStats.head
      val safest = monthlyStats.last
      val allAges = records.flatMap(r => parseAge(r.age))
      val overallAvgAge = if (allAges.nonEmpty) Some(allAges.sum.toDouble / allAges.size) else None
      
      writer.println(s"""  "summary": {""")
      writer.println(s"""    "mostDangerousMonth": {""")
      writer.println(s"""      "month": "${deadliest.monthName}",""")
      writer.println(s"""      "homicides": ${deadliest.count}""")
      writer.println(s"""    },""")
      writer.println(s"""    "safestMonth": {""")
      writer.println(s"""      "month": "${safest.monthName}",""")
      writer.println(s"""      "homicides": ${safest.count}""")
      writer.println(s"""    },""")
      val avgStr = overallAvgAge.map(a => f"$a%.2f").getOrElse("null")
      writer.println(s"""    "overallAverageVictimAge": $avgStr""")
      writer.println(s"""  }""")
      
      writer.println("}")
      
      println("\n✓ Wrote analysis JSON -> analysis_summary.json")
      
    } finally {
      writer.close()
    }
  }
} 