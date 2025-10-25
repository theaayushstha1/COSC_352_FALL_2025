import scala.io.Source



object HomicideAnalysis {
  
  case class Homicide(
    no: String,
    dateDied: String,
    name: String,
    age: String,
    addressBlock: String,
    notes: String,
    noCriminalHistory: String,
    surveillanceCamera: String,
    caseClosed: String
  )
  
  def main(args: Array[String]): Unit = {
    try {
      // Read CSV file
      val csvFile = "chamspage_table1.csv"
      val homicides = parseCSV(csvFile)
      
      println(s"Loaded ${homicides.length} homicide records")
      println("="*80)
      println()
      
      // Question 1: Which address blocks have the most repeated homicides? 
      repeatedHomicides(homicides)
      
      println()
      println("="*80)
      println()
      
      // Question 2: Which months have the highest homicide rates?
      highestMonths(homicides)
      
    } catch {
      case e: Exception =>
        println(s"Error: ${e.getMessage}")
        e.printStackTrace()
    }
  }
  
  def parseCSV(filename: String): List[Homicide] = {
    val bufferedSource = Source.fromFile(filename)
    val lines = bufferedSource.getLines().toList
    bufferedSource.close()
    
    // Skip header row
    val dataLines = lines.drop(1)
    
    dataLines.flatMap { line =>
      // Handle CSV parsing - be careful with commas inside fields
      val parts = parseCSVLine(line)
      
      if (parts.length >= 9) {
        Some(Homicide(
          no = parts(0),
          dateDied = parts(1),
          name = parts(2),
          age = parts(3),
          addressBlock = parts(4),
          notes = parts(5),
          noCriminalHistory = if (parts.length > 6) parts(6) else "",
          surveillanceCamera = if (parts.length > 7) parts(7) else "",
          caseClosed = if (parts.length > 8) parts(8) else ""
        ))
      } else {
        None
      }
    }
  }
  
  def parseCSVLine(line: String): Array[String] = {
    // Simple CSV parsing - handles quoted fields
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
  
  def repeatedHomicides(homicides: List[Homicide]): Unit = {
    println("Question 1: Which address blocks have the most repeated homicides? ?")
    println()
    
    // Group by address block and count occurrences
    val addressCounts = homicides
      .filter(h => h.addressBlock.trim.nonEmpty) // Filter out empty addresses
      .groupBy(_.addressBlock)
      .mapValues(_.length)
      .toList
      .sortBy(-_._2) // Sort by count descending
    
    // Only show addresses with 2 or more homicides
    val repeatedAddresses = addressCounts.filter(_._2 >= 2)
    
    println(s"Total unique address blocks: ${addressCounts.length}")
    println(s"Address blocks with repeated homicides (2+): ${repeatedAddresses.length}")
    println()
    
    println("Top 15 address blocks with most homicides:")
    repeatedAddresses.take(15).zipWithIndex.foreach { case ((address, count), idx) =>
      println(f"  ${idx + 1}%2d. $address%-40s: $count%3d homicides")
    }
    
    println()
    println("Details for top hotspot:")
    if (repeatedAddresses.nonEmpty) {
      val topAddress = repeatedAddresses.head._1
      val victimsAtAddress = homicides.filter(_.addressBlock == topAddress)
      
      println(s"Location: $topAddress")
      println(s"Total homicides: ${victimsAtAddress.length}")
      println()
      println("Victims at this location:")
      victimsAtAddress.foreach { h =>
        println(f"  ${h.dateDied}%-12s | ${h.name}%-30s | Age: ${h.age}%3s")
      }
    }
  }
  
  def highestMonths(homicides: List[Homicide]): Unit = {
    println("Question 2: Which months have the highest homicide rates?")
    println()
    
    // Extract month from date (format: MM/DD/YY)
    val monthNames = Map(
      "01" -> "January",
      "02" -> "February", 
      "03" -> "March",
      "04" -> "April",
      "05" -> "May",
      "06" -> "June",
      "07" -> "July",
      "08" -> "August",
      "09" -> "September",
      "10" -> "October",
      "11" -> "November",
      "12" -> "December"
    )
    
    val monthCounts = homicides.flatMap { h =>
      // Extract month from date (MM/DD/YY format)
      val dateParts = h.dateDied.split("/")
      if (dateParts.length >= 2) {
        Some(dateParts(0)) // First part is the month
      } else {
        None
      }
    }
    .groupBy(identity)
    .mapValues(_.length)
    .toList
    .sortBy(-_._2) // Sort by count descending
    
    println("Homicides by month (all years combined):")
    println()
    
    monthCounts.foreach { case (month, count) =>
      val monthName = monthNames.getOrElse(month, month)
      val percentage = (count.toDouble / homicides.length * 100)
      println(f"  $monthName%-12s: $count%3d homicides ($percentage%5.1f%%)")
    }
    
    println()
    
    // Identify the deadliest month
    if (monthCounts.nonEmpty) {
      val (deadliestMonth, maxCount) = monthCounts.head
      val monthName = monthNames.getOrElse(deadliestMonth, deadliestMonth)
      println(s"Deadliest month: $monthName with $maxCount homicides")
      
      // Show some victims from the deadliest month
      val victimsInDeadliestMonth = homicides.filter(h => h.dateDied.startsWith(deadliestMonth + "/"))
      println()
      println(s"Sample victims from $monthName (first 10):")
      victimsInDeadliestMonth.take(10).foreach { h =>
        println(f"  ${h.dateDied}%-12s | ${h.name}%-30s | ${h.addressBlock}")
      }
    }
  }
}