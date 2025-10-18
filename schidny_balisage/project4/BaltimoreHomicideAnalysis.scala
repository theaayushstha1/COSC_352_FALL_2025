import scala.io.Source
import scala.util.{Try, Success, Failure}

object BaltimoreHomicideAnalysis {
  
  case class Homicide(
    number: String,
    dateDied: String,
    name: String,
    age: String,
    addressBlock: String,
    notes: String,
    noViolentHistory: String,
    cameraAtIntersection: String,
    caseClosed: String
  )
  
  def main(args: Array[String]): Unit = {
    val url = "https://chamspage.blogspot.com/"
    
    println("Fetching Baltimore Homicide Statistics...")
    
    Try(Source.fromURL(url)) match {
      case Success(source) =>
        try {
          val content = source.mkString
          val homicides = parseHomicides(content)
          
          println("\n" + "="*80)
          analyzeNeighborhoodSolveRates(homicides)
          println("\n" + "="*80)
          analyzeVictimDemographicsAndOutcomes(homicides)
          println("="*80 + "\n")
        } finally {
          source.close()
        }
      case Failure(exception) =>
        println(s"Error fetching data: ${exception.getMessage}")
        System.exit(1)
    }
  }
  
  def parseHomicides(content: String): List[Homicide] = {
    val rows = content.split("\n")
      .filter(line => line.trim.startsWith("|") && !line.contains("Date Died") && !line.contains("---"))
      .map(_.split("\\|").map(_.trim))
      .filter(_.length >= 9)
    
    rows.map { cols =>
      Homicide(
        number = cols(1),
        dateDied = cols(2),
        name = cols(3).replaceAll("\\[|\\]|\\(.*?\\)", "").trim,
        age = cols(4),
        addressBlock = cols(5),
        notes = cols(6),
        noViolentHistory = cols(7),
        cameraAtIntersection = cols(8),
        caseClosed = cols(9)
      )
    }.filter(h => h.number.nonEmpty && h.number.forall(c => c.isDigit || c == '?')).toList
  }
  
  def extractNeighborhood(address: String): String = {
    val streetPattern = """(?:\d+\s+)?(.+?)\s+(?:Avenue|Street|Road|Boulevard|Drive|Court|Way|Terrace|Place|Lane|Circle|Parkway|Highway)""".r
    
    streetPattern.findFirstMatchIn(address) match {
      case Some(m) => m.group(1).trim
      case None => 
        if (address.contains("I-")) "Highway"
        else address.split(" ").take(2).mkString(" ")
    }
  }
  
  def analyzeNeighborhoodSolveRates(homicides: List[Homicide]): Unit = {
    println("Question 1: Which neighborhoods have the lowest solve rates?")
    println()
    
    val validHomicides = homicides.filter(h => h.addressBlock.nonEmpty && h.number.matches("\\d+"))
    
    val neighborhoodData = validHomicides
      .groupBy(h => extractNeighborhood(h.addressBlock))
      .map { case (neighborhood, cases) =>
        val total = cases.length
        val closed = cases.count(_.caseClosed.toLowerCase == "closed")
        val solveRate = if (total > 0) (closed.toDouble / total * 100) else 0.0
        (neighborhood, total, closed, solveRate)
      }
      .filter(_._2 >= 3) // At least 3 cases for statistical relevance
      .toList
      .sortBy(_._4)
    
    println(f"${"Neighborhood"}%-30s ${"Total Cases"}%12s ${"Closed"}%8s ${"Solve Rate"}%12s")
    println("-" * 70)
    
    neighborhoodData.take(15).foreach { case (neighborhood, total, closed, rate) =>
      println(f"$neighborhood%-30s $total%12d $closed%8d ${rate}%11.1f%%")
    }
    
    println()
    println(f"Total neighborhoods analyzed: ${neighborhoodData.length}")
    println(f"Average solve rate across all neighborhoods: ${neighborhoodData.map(_._4).sum / neighborhoodData.length}%.1f%%")
  }
  
  def analyzeVictimDemographicsAndOutcomes(homicides: List[Homicide]): Unit = {
    println("\nQuestion 2: What's the relationship between victim demographics and case outcomes?")
    println()
    
    val validHomicides = homicides.filter(h => 
      h.age.nonEmpty && 
      h.age.forall(c => c.isDigit) && 
      h.number.matches("\\d+")
    )
    
    // Age group analysis
    val ageGroups = Map(
      "Under 18" -> (0, 17),
      "18-25" -> (18, 25),
      "26-35" -> (26, 35),
      "36-50" -> (36, 50),
      "Over 50" -> (51, 150)
    )
    
    println("Analysis by Age Group:")
    println(f"${"Age Group"}%-15s ${"Total Cases"}%12s ${"Closed"}%8s ${"Solve Rate"}%12s")
    println("-" * 55)
    
    ageGroups.foreach { case (groupName, (minAge, maxAge)) =>
      val groupCases = validHomicides.filter { h =>
        Try(h.age.toInt).toOption match {
          case Some(age) => age >= minAge && age <= maxAge
          case None => false
        }
      }
      val total = groupCases.length
      val closed = groupCases.count(_.caseClosed.toLowerCase == "closed")
      val solveRate = if (total > 0) (closed.toDouble / total * 100) else 0.0
      
      println(f"$groupName%-15s $total%12d $closed%8d ${solveRate}%11.1f%%")
    }
    
    println()
    println("Analysis by Criminal History:")
    println(f"${"Category"}%-25s ${"Total"}%8s ${"Closed"}%8s ${"Solve Rate"}%12s")
    println("-" * 60)
    
    val withHistory = validHomicides.filter(h => h.noViolentHistory.toLowerCase != "none" && h.noViolentHistory.nonEmpty)
    val withoutHistory = validHomicides.filter(h => h.noViolentHistory.toLowerCase == "none")
    
    val historyData = List(
      ("No violent history", withoutHistory),
      ("Has violent history", withHistory)
    )
    
    historyData.foreach { case (category, cases) =>
      val total = cases.length
      val closed = cases.count(_.caseClosed.toLowerCase == "closed")
      val solveRate = if (total > 0) (closed.toDouble / total * 100) else 0.0
      
      println(f"$category%-25s $total%8d $closed%8d ${solveRate}%11.1f%%")
    }
    
    println()
    println("Analysis by Surveillance Camera Presence:")
    println(f"${"Camera Status"}%-25s ${"Total"}%8s ${"Closed"}%8s ${"Solve Rate"}%12s")
    println("-" * 60)
    
    val withCamera = validHomicides.filter(h => h.cameraAtIntersection.contains("camera"))
    val withoutCamera = validHomicides.filter(h => h.cameraAtIntersection.isEmpty)
    
    val cameraData = List(
      ("Camera present", withCamera),
      ("No camera", withoutCamera)
    )
    
    cameraData.foreach { case (category, cases) =>
      val total = cases.length
      val closed = cases.count(_.caseClosed.toLowerCase == "closed")
      val solveRate = if (total > 0) (closed.toDouble / total * 100) else 0.0
      
      println(f"$category%-25s $total%8d $closed%8d ${solveRate}%11.1f%%")
    }
    
    println()
    val overallClosed = validHomicides.count(_.caseClosed.toLowerCase == "closed")
    val overallTotal = validHomicides.length
    val overallRate = (overallClosed.toDouble / overallTotal * 100)
    println(f"Overall solve rate for 2024: ${overallRate}%.1f%% ($overallClosed of $overallTotal cases)")
  }
}
