import scala.io.Source
import java.io.PrintWriter

object HomicideAnalysis {
  
  case class Homicide(
    no: String,
    date: String,
    name: String,
    age: Int,
    address: String,
    notes: String,
    camera: String,
    caseClosed: String
  )
  
  def main(args: Array[String]): Unit = {
    // In Scala 3, when running with "scala ClassName arg", args includes the class name
    // So we need to check if we have at least 2 args and use args(1)
    val outputFormat = if (args.length > 1) args(1).toLowerCase else "stdout"
    
    // Read CSV data
    val source = Source.fromFile("homicides.csv")
    val lines = source.getLines().toList
    source.close()
    
    // Skip header and parse data
    val homicides = lines.tail.map { line =>
      val cols = line.split(",").map(_.trim)
      Homicide(
        no = cols(0),
        date = cols(1),
        name = cols(2),
        age = cols(3).toInt,
        address = cols(4),
        notes = cols(5),
        camera = cols(6),
        caseClosed = cols(7)
      )
    }
    
    // Analysis 1: Count victims under 18 in 2025
    val under18in2025 = homicides.count(h => h.date.contains("25") && h.age < 18)
    
    // Analysis 2: Count open vs closed cases
    val closedCases = homicides.count(_.caseClosed == "Closed")
    val openCases = homicides.count(h => h.caseClosed == "Open" || h.caseClosed == "Unknown")
    val totalCases = homicides.length
    val closedPercent = if (totalCases > 0) (closedCases.toDouble / totalCases * 100).toInt else 0
    val openPercent = if (totalCases > 0) (openCases.toDouble / totalCases * 100).toInt else 0
    
    // Output based on format
    outputFormat match {
      case "csv" => outputCSV(under18in2025, closedCases, openCases, totalCases, closedPercent, openPercent)
      case "json" => outputJSON(under18in2025, closedCases, openCases, totalCases, closedPercent, openPercent)
      case _ => outputStdout(under18in2025, closedCases, openCases, totalCases, closedPercent, openPercent)
    }
  }
  
  def outputStdout(under18: Int, closed: Int, open: Int, total: Int, closedPct: Int, openPct: Int): Unit = {
    println("=" * 70)
    println("Baltimore City Homicide Data Analysis")
    println("=" * 70)
    println()
    println("Question 1: How many victims were under 18 years old in 2025?")
    println(s"Answer: $under18 victim(s) under 18 years old")
    println()
    println("Question 2: How many homicide cases are open vs closed?")
    println("Answer:")
    println(s"  - Closed cases: $closed ($closedPct%)")
    println(s"  - Open cases: $open ($openPct%)")
    println(s"  - Total cases: $total")
    println()
    println("=" * 70)
  }
  
  def outputCSV(under18: Int, closed: Int, open: Int, total: Int, closedPct: Int, openPct: Int): Unit = {
    val pw = new PrintWriter("output.csv")
    try {
      pw.println("metric,value,percentage")
      pw.println(s"victims_under_18_in_2025,$under18,")
      pw.println(s"closed_cases,$closed,$closedPct")
      pw.println(s"open_cases,$open,$openPct")
      pw.println(s"total_cases,$total,100")
      pw.flush()
      println("CSV output written to output.csv")
    } finally {
      pw.close()
    }
  }
  
  def outputJSON(under18: Int, closed: Int, open: Int, total: Int, closedPct: Int, openPct: Int): Unit = {
    val pw = new PrintWriter("output.json")
    try {
      pw.println("{")
      pw.println("  \"analysis\": \"Baltimore City Homicide Data\",")
      pw.println("  \"questions\": {")
      pw.println("    \"victims_under_18_in_2025\": {")
      pw.println(s"      \"count\": $under18")
      pw.println("    },")
      pw.println("    \"case_status\": {")
      pw.println(s"      \"closed\": $closed,")
      pw.println(s"      \"closed_percentage\": $closedPct,")
      pw.println(s"      \"open\": $open,")
      pw.println(s"      \"open_percentage\": $openPct,")
      pw.println(s"      \"total\": $total")
      pw.println("    }")
      pw.println("  }")
      pw.println("}")
      pw.flush()
      println("JSON output written to output.json")
    } finally {
      pw.close()
    }
  }
}
