import scala.io.Source
import scala.util.{Try, Success, Failure}
import java.time.LocalDate
import java.time.format.DateTimeFormatter

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
  
  def main(args: Array[String]): Unit = {
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
      runSampleAnalysis()
    } else {
      println(s"✓ Successfully loaded ${homicides.size} homicide records")
      println()
      analyzeQuestion1(homicides)
      println()
      println()
      analyzeQuestion2(homicides)
    }
  }
  
  def fetchRealData(): List[Homicide] = {
    try {
      println("Fetching live data from chamspage.blogspot.com...")
      val url = "http://chamspage.blogspot.com"
      val html = Source.fromURL(url, "UTF-8").mkString
      
      val lines = html.split("\n")
      val homicides = scala.collection.mutable.ListBuffer[Homicide]()
      
      var inTable = false
      lines.foreach { line =>
        if (line.contains("<table") && line.contains("border")) {
          inTable = true
        } else if (line.contains("</table>")) {
          inTable = false
        } else if (inTable && line.contains("<td")) {
          val tdPattern = "<td[^>]*>([^<]*)</td>".r
          val cells = tdPattern.findAllMatchIn(line).map(_.group(1).trim).toList
          
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
  
  def runSampleAnalysis(): Unit = {
    // Enhanced sample data with realistic Baltimore street addresses and varied demographics
    val sampleData = List(
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
    
    println(s"✓ Loaded ${sampleData.size} sample records for demonstration")
    println()
    analyzeQuestion1(sampleData)
    println()
    println()
    analyzeQuestion2(sampleData)
  }
  
  def analyzeQuestion1(homicides: List[Homicide]): Unit = {
    println("=" * 80)
    println("QUESTION 1: Which specific street locations have the highest homicide")
    println("            concentrations, and should Baltimore implement 'Violence")
    println("            Interruption Zones' at these hotspots?")
    println("=" * 80)
    println()
    println("STRATEGIC RATIONALE:")
    println("Concentrated violence at specific locations suggests systemic issues")
    println("(drug markets, gang territories, or social disorder). Identifying these")
    println("micro-hotspots enables targeted deployment of Violence Interruption")
    println("specialists, enhanced street lighting, community programs, and focused")
    println("police presence to disrupt cycles of retaliatory violence.")
    println()
    
    // Group by street block to find geographic clusters
    val locationClusters = homicides.groupBy(h => normalizeAddress(h.address))
    
    // Calculate metrics for each location
    val locationAnalysis = locationClusters.map { case (location, cases) =>
      val totalCases = cases.size
      val closedCases = cases.count(_.caseClosed.equalsIgnoreCase("Closed"))
      val openCases = totalCases - closedCases
      val closureRate = if (totalCases > 0) (closedCases.toDouble / totalCases * 100) else 0.0
      val withCameras = cases.count(_.cameraPresent.toLowerCase.contains("camera"))
      val avgAge = cases.flatMap(h => Try(h.age.toInt).toOption).sum.toDouble / 
                   cases.flatMap(h => Try(h.age.toInt).toOption).size.max(1)
      
      (location, totalCases, closedCases, openCases, closureRate, withCameras, avgAge)
    }.toList.sortBy(-_._2) // Sort by total cases descending
    
    println("=" * 80)
    println("HIGH-CONCENTRATION VIOLENCE HOTSPOTS (Top 15)")
    println("=" * 80)
    println(f"${"Location"}%-35s ${"Total"}%5s ${"Open"}%5s ${"Closed"}%6s ${"Rate"}%6s ${"Cam"}%4s")
    println("-" * 80)
    
    locationAnalysis.take(15).foreach { case (location, total, closed, open, rate, cameras, avgAge) =>
      println(f"${location}%-35s ${total}%5d ${open}%5d ${closed}%6d ${rate}%5.1f%% ${cameras}%4d")
    }
    
    // Identify critical intervention zones (3+ homicides)
    val criticalZones = locationAnalysis.filter(_._2 >= 3)
    val totalInCriticalZones = criticalZones.map(_._2).sum
    val percentageInHotspots = if (homicides.nonEmpty) 
      (totalInCriticalZones.toDouble / homicides.size * 100) else 0.0
    
    println()
    println("=" * 80)
    println("CRITICAL FINDINGS:")
    println("=" * 80)
    println(f"✓ ${criticalZones.size} locations have 3+ homicides (CRITICAL HOTSPOTS)")
    println(f"✓ ${totalInCriticalZones} homicides (${percentageInHotspots}%.1f%%) occurred in these zones")
    println(f"✓ ${locationAnalysis.count(_._6 > 0)} high-violence locations have camera coverage")
    
    if (criticalZones.nonEmpty) {
      val worstLocation = criticalZones.head
      println(f"✓ Most dangerous: ${worstLocation._1} (${worstLocation._2} homicides)")
    }
    
    println()
    println("=" * 80)
    println("RECOMMENDED VIOLENCE INTERRUPTION ZONES:")
    println("=" * 80)
    
    criticalZones.take(5).foreach { case (location, total, closed, open, rate, cameras, avgAge) =>
      println(f"→ ${location}")
      println(f"  • ${total} homicides | ${open} open cases | Avg victim age: ${avgAge.toInt}")
      if (cameras == 0) {
        println(f"  • ACTION: Install surveillance cameras immediately")
      }
      println(f"  • ACTION: Deploy conflict mediators and violence interrupters")
      println(f"  • ACTION: Increase foot patrols during high-risk evening hours")
      println()
    }
    
    println("POLICY RECOMMENDATIONS:")
    println("-" * 80)
    println(s"1. Establish Violence Interruption Zones at ${criticalZones.size} identified hotspots")
    println(s"2. Deploy community outreach workers to ${criticalZones.take(5).size} highest-priority locations")
    println("3. Implement environmental design changes (lighting, visibility, landscaping)")
    println("4. Coordinate with property owners for security improvements")
    println(f"5. Projected impact: Reduce ${(totalInCriticalZones * 0.3).toInt}+ homicides annually (30%% reduction)")
  }
  
  def analyzeQuestion2(homicides: List[Homicide]): Unit = {
    println("=" * 80)
    println("QUESTION 2: What is the correlation between victim age demographics and")
    println("            case closure success rates, revealing which age groups need")
    println("            targeted investigative resources?")
    println("=" * 80)
    println()
    println("STRATEGIC RATIONALE:")
    println("Different victim demographics may have varying case closure rates due to")
    println("witness cooperation, community engagement, investigative complexity, or")
    println("resource allocation. Identifying disparities enables targeted deployment")
    println("of specialized detective units and community liaison resources where")
    println("they will maximize case clearance effectiveness.")
    println()
    
    // Parse ages and categorize
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
      
      (groupName, total, closed, open, closureRate, withCameras)
    }.toList.sortBy(-_._2)
    
    println("=" * 80)
    println("AGE-BASED CASE CLOSURE ANALYSIS")
    println("=" * 80)
    println(f"${"Age Group"}%-25s ${"Total"}%6s ${"Closed"}%7s ${"Open"}%6s ${"Rate"}%7s ${"Camera"}%7s")
    println("-" * 80)
    
    ageGroupAnalysis.foreach { case (group, total, closed, open, rate, cameras) =>
      if (total > 0) {
        println(f"${group}%-25s ${total}%6d ${closed}%7d ${open}%6d ${rate}%6.1f%% ${cameras}%7d")
      }
    }
    
    // Find groups with concerning closure rates
    val overallClosureRate = if (homicides.nonEmpty) {
      (homicides.count(_.caseClosed.equalsIgnoreCase("Closed")).toDouble / homicides.size * 100)
    } else 0.0
    
    val underperformingGroups = ageGroupAnalysis.filter { case (_, total, _, _, rate, _) =>
      total > 0 && rate < overallClosureRate
    }
    
    val highPerformingGroups = ageGroupAnalysis.filter { case (_, total, _, _, rate, _) =>
      total > 0 && rate > overallClosureRate
    }
    
    println()
    println("=" * 80)
    println("CRITICAL FINDINGS:")
    println("=" * 80)
    println(f"✓ Overall case closure rate: ${overallClosureRate}%.1f%%")
    println(f"✓ ${underperformingGroups.size} age groups have below-average closure rates")
    println(f"✓ ${highPerformingGroups.size} age groups have above-average closure rates")
    
    if (ageGroupAnalysis.nonEmpty) {
      val bestGroup = ageGroupAnalysis.maxBy(_._5)
      val worstGroup = ageGroupAnalysis.filter(_._2 > 0).minBy(_._5)
      
      if (bestGroup._2 > 0 && worstGroup._2 > 0) {
        val disparity = bestGroup._5 - worstGroup._5
        println(f"✓ Closure rate disparity: ${disparity}%.1f%% between age groups")
        println(f"  → Highest: ${bestGroup._1} (${bestGroup._5}%.1f%%)")
        println(f"  → Lowest:  ${worstGroup._1} (${worstGroup._5}%.1f%%)")
      }
    }
    
    println()
    println("=" * 80)
    println("INVESTIGATIVE RESOURCE ALLOCATION RECOMMENDATIONS:")
    println("=" * 80)
    
    underperformingGroups.sortBy(_._5).foreach { case (group, total, closed, open, rate, cameras) =>
      println(f"→ ${group}: ${rate}%.1f%% closure rate (${open} open cases)")
      
      group match {
        case name if name.contains("Minor") =>
          println("  • PRIORITY: Assign specialized juvenile homicide detectives")
          println("  • ACTION: Partner with school liaisons and youth services")
          println("  • ACTION: Implement trauma-informed witness interview protocols")
          
        case name if name.contains("Young Adult") =>
          println("  • ACTION: Deploy gang unit investigators for potential retaliation cases")
          println("  • ACTION: Engage street outreach workers for witness cooperation")
          println("  • ACTION: Focus on social media evidence and digital forensics")
          
        case name if name.contains("Senior") =>
          println("  • ACTION: Assign elder abuse specialists to investigate patterns")
          println("  • ACTION: Coordinate with social services for vulnerable victim backgrounds")
          println("  • ACTION: Review for potential robbery or financial motive cases")
          
        case _ =>
          println("  • ACTION: Increase detective staffing for this demographic")
          println("  • ACTION: Improve community liaison engagement")
      }
      println()
    }
    
    println("SUMMARY POLICY RECOMMENDATIONS:")
    println("-" * 80)
    println("1. Create specialized detective units for underperforming demographics")
    println("2. Allocate additional investigative hours to age groups with low closure rates")
    println("3. Implement targeted witness protection and community engagement programs")
    println("4. Review case management protocols to identify systemic barriers")
    
    if (underperformingGroups.nonEmpty) {
      val potentialImpact = underperformingGroups.map(_._4).sum
      println(f"5. Projected impact: Solving ${(potentialImpact * 0.25).toInt}+ additional cases with focused resources")
    }
  }
  
  def normalizeAddress(address: String): String = {
    // Extract block and street name, normalizing format
    val blockPattern = "(\\d+)\\s+block\\s+(.+)".r
    address.toLowerCase match {
      case blockPattern(number, street) => 
        s"${number} block ${street.split(" ").take(3).mkString(" ")}".take(35)
      case _ => 
        address.split(" ").filter(_.nonEmpty).take(4).mkString(" ").take(35)
    }
  }
}
