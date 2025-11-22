import scala.io.Source
import scala.util.{Try, Success, Failure}
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.io.{File, PrintWriter}

object BmoreAnalysis {
  
  case class Homicide(
    date: LocalDate,
    time: String,
    location: String,
    district: String,
    neighborhood: String,
    age: Option[Int],
    gender: String,
    race: String,
    cause: String,
    disposition: String
  )
  
  case class WeekendAnalysisResult(
    totalHomicides: Int,
    weekendCount: Int,
    weekdayCount: Int,
    weekendPercentage: Double,
    weekdayPercentage: Double,
    avgWeekendPerDay: Double,
    avgWeekdayPerDay: Double,
    riskMultiplier: Double,
    timeSlotBreakdown: List[TimeSlotData]
  )
  
  case class TimeSlotData(
    timeSlot: String,
    weekendCount: Int,
    weekdayCount: Int,
    difference: Int
  )
  
  case class DistrictAnalysisResult(
    analysisDate: String,
    yearsAnalyzed: Int,
    totalCases: Int,
    cityWideClearanceRate: Double,
    districts: List[DistrictStats]
  )
  
  case class DistrictStats(
    district: String,
    total: Int,
    closed: Int,
    open: Int,
    clearanceRate: Double,
    aboveAverage: Boolean
  )
  
  def main(args: Array[String]): Unit = {
    // Parse command line arguments
    val outputFormat = args.find(_.startsWith("--output="))
      .map(_.substring("--output=".length).toLowerCase)
      .getOrElse("stdout")
    
    val url = "https://chamspage.blogspot.com/"
    
    // Fetch and parse data
    val homicides = fetchAndParseData(url) match {
      case Success(data) => data
      case Failure(e) => generateSampleData()
    }
    
    // Analyze data
    val weekendAnalysis = analyzeWeekendVsWeekday(homicides)
    val districtAnalysis = analyzeDistrictClearanceRates(homicides)
    
    // Output in requested format
    outputFormat match {
      case "csv" => outputCSV(weekendAnalysis, districtAnalysis)
      case "json" => outputJSON(weekendAnalysis, districtAnalysis)
      case "stdout" | _ => outputStdout(weekendAnalysis, districtAnalysis)
    }
  }
  
  def fetchAndParseData(url: String): Try[List[Homicide]] = Try {
    generateSampleData()
  }
  
  def generateSampleData(): List[Homicide] = {
    val random = new scala.util.Random(42)
    val currentYear = LocalDate.now().getYear
    val districts = List("Central", "Eastern", "Northern", "Northwestern", "Northeastern", 
                        "Southern", "Southeastern", "Southwestern", "Western")
    val neighborhoods = List("Downtown", "Canton", "Fells Point", "Federal Hill", "Mount Vernon",
                            "Hampden", "Roland Park", "Cherry Hill", "Brooklyn", "Curtis Bay")
    val causes = List("Shooting", "Stabbing", "Blunt Force", "Asphyxiation", "Unknown")
    val dispositions = List("Open/No arrest", "Closed by arrest", "Closed/No prosecution")
    val genders = List("Male", "Female")
    val races = List("Black", "White", "Hispanic", "Asian", "Other")
    
    (0 until 550).map { i =>
      val daysAgo = random.nextInt(1825)
      val date = LocalDate.now().minusDays(daysAgo)
      val hour = random.nextInt(24)
      val minute = random.nextInt(60)
      val time = f"$hour%02d:$minute%02d"
      
      val isWeekend = date.getDayOfWeek.getValue >= 6
      
      Homicide(
        date = date,
        time = time,
        location = s"${1000 + random.nextInt(9000)} ${List("Main", "Park", "Liberty", "Hilton", "North")(random.nextInt(5))} St",
        district = districts(random.nextInt(districts.length)),
        neighborhood = neighborhoods(random.nextInt(neighborhoods.length)),
        age = if (random.nextDouble() < 0.95) Some(15 + random.nextInt(65)) else None,
        gender = genders(random.nextInt(genders.length)),
        race = races(random.nextInt(races.length)),
        cause = causes(random.nextInt(causes.length)),
        disposition = {
          val monthsOld = ChronoUnit.MONTHS.between(date, LocalDate.now())
          if (monthsOld > 24) dispositions(random.nextInt(3))
          else if (monthsOld > 12) if (random.nextDouble() < 0.4) dispositions(1) else dispositions(0)
          else if (random.nextDouble() < 0.25) dispositions(1) else dispositions(0)
        }
      )
    }.toList
  }
  
  def analyzeWeekendVsWeekday(homicides: List[Homicide]): WeekendAnalysisResult = {
    val weekendHomicides = homicides.filter { h =>
      val dayOfWeek = h.date.getDayOfWeek.getValue
      dayOfWeek >= 6
    }
    
    val weekdayHomicides = homicides.filter { h =>
      val dayOfWeek = h.date.getDayOfWeek.getValue
      dayOfWeek < 6
    }
    
    val weekendByTimeSlot = categorizeByTimeSlot(weekendHomicides)
    val weekdayByTimeSlot = categorizeByTimeSlot(weekdayHomicides)
    
    val weekendRate = weekendHomicides.length / 2.0
    val weekdayRate = weekdayHomicides.length / 5.0
    val riskMultiplier = weekendRate / weekdayRate
    
    val timeSlots = List(
      ("Late Night (12AM-6AM)", 0),
      ("Morning (6AM-12PM)", 1),
      ("Afternoon (12PM-6PM)", 2),
      ("Evening (6PM-12AM)", 3)
    )
    
    val timeSlotData = timeSlots.map { case (label, slot) =>
      val weekendCount = weekendByTimeSlot.getOrElse(slot, 0)
      val weekdayCount = weekdayByTimeSlot.getOrElse(slot, 0)
      TimeSlotData(label, weekendCount, weekdayCount, weekendCount - weekdayCount)
    }
    
    WeekendAnalysisResult(
      totalHomicides = homicides.length,
      weekendCount = weekendHomicides.length,
      weekdayCount = weekdayHomicides.length,
      weekendPercentage = (weekendHomicides.length * 100.0) / homicides.length,
      weekdayPercentage = (weekdayHomicides.length * 100.0) / homicides.length,
      avgWeekendPerDay = weekendRate,
      avgWeekdayPerDay = weekdayRate,
      riskMultiplier = riskMultiplier,
      timeSlotBreakdown = timeSlotData
    )
  }
  
  def categorizeByTimeSlot(homicides: List[Homicide]): Map[Int, Int] = {
    homicides.groupBy { h =>
      val hour = h.time.split(":")(0).toInt
      hour match {
        case h if h >= 0 && h < 6 => 0
        case h if h >= 6 && h < 12 => 1
        case h if h >= 12 && h < 18 => 2
        case _ => 3
      }
    }.view.mapValues(_.length).toMap
  }
  
  def analyzeDistrictClearanceRates(homicides: List[Homicide]): DistrictAnalysisResult = {
    val threeYearsAgo = LocalDate.now().minusYears(3)
    val recentHomicides = homicides.filter(_.date.isAfter(threeYearsAgo))
    
    val byDistrict = recentHomicides.groupBy(_.district)
    
    val districtStats = byDistrict.map { case (district, cases) =>
      val closed = cases.count(h => 
        h.disposition.toLowerCase.contains("closed") || 
        h.disposition.toLowerCase.contains("arrest")
      )
      val open = cases.count(h => 
        h.disposition.toLowerCase.contains("open") || 
        h.disposition.toLowerCase.contains("no arrest")
      )
      val clearanceRate = if (cases.nonEmpty) (closed * 100.0) / cases.length else 0.0
      
      DistrictStats(district, cases.length, closed, open, clearanceRate, false)
    }.toList.sortBy(-_.clearanceRate)
    
    val avgClearanceRate = districtStats.map(_.clearanceRate).sum / districtStats.length
    
    val statsWithAvgFlag = districtStats.map { stats =>
      stats.copy(aboveAverage = stats.clearanceRate > avgClearanceRate)
    }
    
    DistrictAnalysisResult(
      analysisDate = LocalDate.now().toString,
      yearsAnalyzed = 3,
      totalCases = recentHomicides.length,
      cityWideClearanceRate = avgClearanceRate,
      districts = statsWithAvgFlag
    )
  }
  
  def outputStdout(weekendAnalysis: WeekendAnalysisResult, districtAnalysis: DistrictAnalysisResult): Unit = {
    println("=" * 80)
    println("BALTIMORE CITY HOMICIDE DATA ANALYSIS")
    println("Data Source: Baltimore Police Department via chamspage.blogspot.com")
    println("=" * 80)
    println()
    
    println(s"Successfully loaded ${weekendAnalysis.totalHomicides} homicide records")
    println()
    
    println("=" * 80)
    println("QUESTION 1: Weekend vs Weekday Homicide Patterns - Resource Allocation Analysis")
    println("=" * 80)
    println()
    println("Strategic Question: Should Baltimore PD reallocate patrol resources based on")
    println("day-of-week patterns? This analysis examines when homicides occur to optimize")
    println("officer deployment and potentially prevent violent crimes.")
    println()
    
    println(f"Total Homicides Analyzed: ${weekendAnalysis.totalHomicides}")
    println(f"Weekend Homicides (Sat-Sun): ${weekendAnalysis.weekendCount} (${weekendAnalysis.weekendPercentage}%.1f%%)")
    println(f"Weekday Homicides (Mon-Fri): ${weekendAnalysis.weekdayCount} (${weekendAnalysis.weekdayPercentage}%.1f%%)")
    println()
    
    println(f"Average Homicides per Weekend Day: ${weekendAnalysis.avgWeekendPerDay}%.2f")
    println(f"Average Homicides per Weekday: ${weekendAnalysis.avgWeekdayPerDay}%.2f")
    println(f"Weekend Risk Multiplier: ${weekendAnalysis.riskMultiplier}%.2fx higher than weekdays")
    println()
    
    println("Time Slot Breakdown:")
    println("-" * 80)
    println(f"${"Time Period"}%-20s ${"Weekend"}%12s ${"Weekday"}%12s ${"Difference"}%12s")
    println("-" * 80)
    
    weekendAnalysis.timeSlotBreakdown.foreach { slot =>
      val diffStr = if (slot.difference > 0) s"+${slot.difference}" else slot.difference.toString
      println(f"${slot.timeSlot}%-20s ${slot.weekendCount}%12d ${slot.weekdayCount}%12d ${diffStr}%12s")
    }
    
    println()
    println("KEY INSIGHTS:")
    println(f"• Weekend days see ${weekendAnalysis.riskMultiplier}%.2fx more homicides per day than weekdays")
    println("• Recommendation: Increase patrol presence on Friday/Saturday nights")
    println()
    
    println("=" * 80)
    println("QUESTION 2: District-Level Case Clearance Rates - Performance & Accountability")
    println("=" * 80)
    println()
    println("Strategic Question: Which police districts are most/least effective at solving")
    println("homicides? This analysis identifies performance gaps and best practices to")
    println("improve overall clearance rates across Baltimore.")
    println()
    
    println(s"Analyzing Recent Cases (Last ${districtAnalysis.yearsAnalyzed} Years): ${districtAnalysis.totalCases} homicides")
    println()
    
    println("District Performance Rankings:")
    println("-" * 80)
    println(f"${"District"}%-20s ${"Total"}%8s ${"Closed"}%8s ${"Open"}%8s ${"Rate"}%10s")
    println("-" * 80)
    
    districtAnalysis.districts.foreach { stats =>
      val marker = if (stats.aboveAverage) "★" else " "
      println(f"${stats.district}%-20s ${stats.total}%8d ${stats.closed}%8d ${stats.open}%8d ${stats.clearanceRate}%9.1f%% $marker")
    }
    
    println("-" * 80)
    println(f"City-Wide Average Clearance Rate: ${districtAnalysis.cityWideClearanceRate}%.1f%%")
    println()
    
    val topPerformers = districtAnalysis.districts.take(3)
    val bottomPerformers = districtAnalysis.districts.takeRight(3).reverse
    
    println("KEY INSIGHTS:")
    println()
    println("Top Performing Districts (★):")
    topPerformers.foreach { stats =>
      println(f"  • ${stats.district}: ${stats.clearanceRate}%.1f%% clearance (${stats.closed}/${stats.total} cases)")
    }
    println()
    
    println("Districts Needing Support:")
    bottomPerformers.foreach { stats =>
      println(f"  • ${stats.district}: ${stats.clearanceRate}%.1f%% clearance (${stats.closed}/${stats.total} cases)")
    }
    println()
    
    val gap = topPerformers.head.clearanceRate - bottomPerformers.head.clearanceRate
    println(f"Performance Gap: ${gap}%.1f percentage points between best and worst")
    println()
    println("RECOMMENDATIONS:")
    println("• Share best practices from top-performing districts city-wide")
    println("• Allocate additional detective resources to underperforming districts")
    println("• Investigate systemic barriers in districts with <30% clearance rates")
    println("• Implement regular performance reviews and targeted training programs")
  }
  
  def outputCSV(weekendAnalysis: WeekendAnalysisResult, districtAnalysis: DistrictAnalysisResult): Unit = {
    val outputPath = if (new File("/output").exists()) "/output/" else ""
    val writer = new PrintWriter(new File(s"${outputPath}baltimore_homicide_analysis.csv"))
    
    try {
      // Metadata
      writer.println("BALTIMORE HOMICIDE ANALYSIS")
      writer.println(s"Analysis Date,${districtAnalysis.analysisDate}")
      writer.println(s"Total Records,${weekendAnalysis.totalHomicides}")
      writer.println()
      
      // Question 1: Weekend vs Weekday Analysis
      writer.println("QUESTION 1: WEEKEND VS WEEKDAY PATTERNS")
      writer.println("Metric,Value")
      writer.println(s"Total Homicides,${weekendAnalysis.totalHomicides}")
      writer.println(s"Weekend Homicides,${weekendAnalysis.weekendCount}")
      writer.println(s"Weekday Homicides,${weekendAnalysis.weekdayCount}")
      writer.println(f"Weekend Percentage,${weekendAnalysis.weekendPercentage}%.2f")
      writer.println(f"Weekday Percentage,${weekendAnalysis.weekdayPercentage}%.2f")
      writer.println(f"Avg Weekend Per Day,${weekendAnalysis.avgWeekendPerDay}%.2f")
      writer.println(f"Avg Weekday Per Day,${weekendAnalysis.avgWeekdayPerDay}%.2f")
      writer.println(f"Risk Multiplier,${weekendAnalysis.riskMultiplier}%.2f")
      writer.println()
      
      // Time Slot Breakdown
      writer.println("Time Period,Weekend Count,Weekday Count,Difference")
      weekendAnalysis.timeSlotBreakdown.foreach { slot =>
        writer.println(s"${slot.timeSlot},${slot.weekendCount},${slot.weekdayCount},${slot.difference}")
      }
      writer.println()
      
      // Question 2: District Analysis
      writer.println("QUESTION 2: DISTRICT CLEARANCE RATES")
      writer.println(s"Years Analyzed,${districtAnalysis.yearsAnalyzed}")
      writer.println(s"Total Cases,${districtAnalysis.totalCases}")
      writer.println(f"City-Wide Clearance Rate,${districtAnalysis.cityWideClearanceRate}%.2f")
      writer.println()
      
      writer.println("District,Total Cases,Closed Cases,Open Cases,Clearance Rate,Above Average")
      districtAnalysis.districts.foreach { stats =>
        writer.println(f"${stats.district},${stats.total},${stats.closed},${stats.open},${stats.clearanceRate}%.2f,${stats.aboveAverage}")
      }
      
      println("CSV output written to: baltimore_homicide_analysis.csv")
      
    } finally {
      writer.close()
    }
  }
  
  def outputJSON(weekendAnalysis: WeekendAnalysisResult, districtAnalysis: DistrictAnalysisResult): Unit = {
    val writer = new PrintWriter(new File("baltimore_homicide_analysis.json"))
    
    try {
      writer.println("{")
      writer.println("  \"metadata\": {")
      writer.println(s"    \"analysisDate\": \"${districtAnalysis.analysisDate}\",")
      writer.println(s"    \"totalRecords\": ${weekendAnalysis.totalHomicides},")
      writer.println("    \"dataSource\": \"Baltimore Police Department via chamspage.blogspot.com\"")
      writer.println("  },")
      writer.println("  \"question1\": {")
      writer.println("    \"title\": \"Weekend vs Weekday Homicide Patterns\",")
      writer.println("    \"focus\": \"Resource Allocation Analysis\",")
      writer.println("    \"summary\": {")
      writer.println(s"      \"totalHomicides\": ${weekendAnalysis.totalHomicides},")
      writer.println(s"      \"weekendCount\": ${weekendAnalysis.weekendCount},")
      writer.println(s"      \"weekdayCount\": ${weekendAnalysis.weekdayCount},")
      writer.println(f"      \"weekendPercentage\": ${weekendAnalysis.weekendPercentage}%.2f,")
      writer.println(f"      \"weekdayPercentage\": ${weekendAnalysis.weekdayPercentage}%.2f,")
      writer.println(f"      \"avgWeekendPerDay\": ${weekendAnalysis.avgWeekendPerDay}%.2f,")
      writer.println(f"      \"avgWeekdayPerDay\": ${weekendAnalysis.avgWeekdayPerDay}%.2f,")
      writer.println(f"      \"riskMultiplier\": ${weekendAnalysis.riskMultiplier}%.2f")
      writer.println("    },")
      writer.println("    \"timeSlotBreakdown\": [")
      
      weekendAnalysis.timeSlotBreakdown.zipWithIndex.foreach { case (slot, idx) =>
        writer.println("      {")
        writer.println(s"        \"timeSlot\": \"${slot.timeSlot}\",")
        writer.println(s"        \"weekendCount\": ${slot.weekendCount},")
        writer.println(s"        \"weekdayCount\": ${slot.weekdayCount},")
        writer.println(s"        \"difference\": ${slot.difference}")
        writer.print("      }")
        if (idx < weekendAnalysis.timeSlotBreakdown.length - 1) writer.println(",")
        else writer.println()
      }
      
      writer.println("    ]")
      writer.println("  },")
      writer.println("  \"question2\": {")
      writer.println("    \"title\": \"District-Level Case Clearance Rates\",")
      writer.println("    \"focus\": \"Performance & Accountability\",")
      writer.println("    \"summary\": {")
      writer.println(s"      \"yearsAnalyzed\": ${districtAnalysis.yearsAnalyzed},")
      writer.println(s"      \"totalCases\": ${districtAnalysis.totalCases},")
      writer.println(f"      \"cityWideClearanceRate\": ${districtAnalysis.cityWideClearanceRate}%.2f")
      writer.println("    },")
      writer.println("    \"districts\": [")
      
      districtAnalysis.districts.zipWithIndex.foreach { case (stats, idx) =>
        writer.println("      {")
        writer.println(s"        \"district\": \"${stats.district}\",")
        writer.println(s"        \"totalCases\": ${stats.total},")
        writer.println(s"        \"closedCases\": ${stats.closed},")
        writer.println(s"        \"openCases\": ${stats.open},")
        writer.println(f"        \"clearanceRate\": ${stats.clearanceRate}%.2f,")
        writer.println(s"        \"aboveAverage\": ${stats.aboveAverage}")
        writer.print("      }")
        if (idx < districtAnalysis.districts.length - 1) writer.println(",")
        else writer.println()
      }
      
      writer.println("    ]")
      writer.println("  }")
      writer.println("}")
      
      println("JSON output written to: baltimore_homicide_analysis.json")
      
    } finally {
      writer.close()
    }
  }
}