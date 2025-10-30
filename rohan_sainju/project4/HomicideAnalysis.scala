import scala.io.Source

object HomicideAnalysis {
  def main(args: Array[String]): Unit = {
    println("=" * 60)
    println("Baltimore City Homicide Data Analysis")
    println("=" * 60)
    println()

    // Read the CSV file
    val filename = "homicides.csv"
    val lines = Source.fromFile(filename).getLines().toList
    
    // Skip header
    val data = lines.tail
    
    // Question 1: How many victims were under 18 years old?
    println("Question 1: How many victims were under 18 years old in 2025?")
    val under18 = data.filter { line =>
      val cols = line.split(",")
      val age = cols(3).toInt
      val year = cols(1).split("/")(2).toInt + 2000
      age < 18 && year == 2025
    }
    println(s"Answer: ${under18.length} victim(s) under 18 years old")
    if (under18.nonEmpty) {
      println("\nDetails:")
      under18.foreach { line =>
        val cols = line.split(",")
        println(s"  - ${cols(2)}, Age ${cols(3)}, Date: ${cols(1)}")
      }
    }
    println()
    
    // Question 2: How many cases are open vs closed?
    println("Question 2: How many homicide cases are open vs closed?")
    val closed = data.count(line => line.split(",")(7) == "Closed")
    val open = data.count(line => line.split(",")(7) == "Unknown")
    val total = data.length
    
    println(s"Answer:")
    println(s"  - Closed cases: $closed (${closed * 100 / total}%)")
    println(s"  - Open cases: $open (${open * 100 / total}%)")
    println(s"  - Total cases: $total")
    println()
    
    println("=" * 60)
    println("Analysis Complete")
    println("=" * 60)
  }
}
