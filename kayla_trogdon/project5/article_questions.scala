import scala.io.Source
import java.io.PrintWriter

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
  
  case class AddressStats(
    address: String,
    count: Int,
    victims: List[Homicide]
  )
  
  case class MonthStats(
    month: String,
    monthName: String,
    count: Int,
    percentage: Double
  )
  
  def main(args: Array[String]): Unit = {
    try {
      val outputFormat = parseArgs(args)
      
      val csvFile = "chamspage_table1.csv"
      val homicides = parseCSV(csvFile)
      
      val addressStats = analyzeAddressBlocks(homicides)
      val monthStats = analyzeMonths(homicides)
      
      outputFormat match {
        case "csv" => outputCSV(homicides, addressStats, monthStats)
        case "json" => outputJSON(homicides, addressStats, monthStats)
        case _ => outputStdout(homicides, addressStats, monthStats)
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
  
  def parseCSV(filename: String): List[Homicide] = {
    val bufferedSource = Source.fromFile(filename)
    val lines = bufferedSource.getLines().toList
    bufferedSource.close()
    
    val dataLines = lines.drop(1)
    
    dataLines.flatMap { line =>
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
  
  def analyzeAddressBlocks(homicides: List[Homicide]): List[AddressStats] = {
    homicides
      .filter(h => h.addressBlock.trim.nonEmpty)
      .groupBy(_.addressBlock)
      .map { case (address, victims) => 
        AddressStats(address, victims.length, victims)
      }
      .toList
      .sortBy(-_.count)
      .filter(_.count >= 2)
  }
  
  def analyzeMonths(homicides: List[Homicide]): List[MonthStats] = {
    val monthNames = Map(
      "01" -> "January", "02" -> "February", "03" -> "March",
      "04" -> "April", "05" -> "May", "06" -> "June",
      "07" -> "July", "08" -> "August", "09" -> "September",
      "10" -> "October", "11" -> "November", "12" -> "December"
    )
    
    val total = homicides.length.toDouble
    
    homicides.flatMap { h =>
      val dateParts = h.dateDied.split("/")
      if (dateParts.length >= 2) Some(dateParts(0)) else None
    }
    .groupBy(identity)
    .map { case (month, instances) =>
      MonthStats(
        month,
        monthNames.getOrElse(month, month),
        instances.length,
        (instances.length / total) * 100
      )
    }
    .toList
    .sortBy(-_.count)
  }
  
  def outputStdout(homicides: List[Homicide], addressStats: List[AddressStats], monthStats: List[MonthStats]): Unit = {
    println(s"Loaded ${homicides.length} homicide records")
    println("="*80)
    println()
    
    println("Question 1: Which address blocks have the most repeated homicides?")
    println()
    
    val addressCounts = homicides
      .filter(h => h.addressBlock.trim.nonEmpty)
      .groupBy(_.addressBlock)
      .mapValues(_.length)
      .toList
      .sortBy(-_._2)
    
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
    
    println()
    println("="*80)
    println()
    
    println("Question 2: Which months have the highest homicide rates?")
    println()
    
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
      val dateParts = h.dateDied.split("/")
      if (dateParts.length >= 2) {
        Some(dateParts(0))
      } else {
        None
      }
    }
    .groupBy(identity)
    .mapValues(_.length)
    .toList
    .sortBy(-_._2)
    
    println("Homicides by month (all years combined):")
    println()
    
    monthCounts.foreach { case (month, count) =>
      val monthName = monthNames.getOrElse(month, month)
      val percentage = (count.toDouble / homicides.length * 100)
      println(f"  $monthName%-12s: $count%3d homicides ($percentage%5.1f%%)")
    }
    
    println()
    
    if (monthCounts.nonEmpty) {
      val (deadliestMonth, maxCount) = monthCounts.head
      val monthName = monthNames.getOrElse(deadliestMonth, deadliestMonth)
      println(s"Deadliest month: $monthName with $maxCount homicides")
      
      val victimsInDeadliestMonth = homicides.filter(h => h.dateDied.startsWith(deadliestMonth + "/"))
      println()
      println(s"Sample victims from $monthName (first 10):")
      victimsInDeadliestMonth.take(10).foreach { h =>
        println(f"  ${h.dateDied}%-12s | ${h.name}%-30s | ${h.addressBlock}")
      }
    }
  }
  
  def outputCSV(homicides: List[Homicide], addressStats: List[AddressStats], monthStats: List[MonthStats]): Unit = {
    val writer = new PrintWriter("homicide_analysis.csv")
    
    try {
      writer.println("Baltimore Homicide Analysis Report")
      writer.println(s"Total Records,${homicides.length}")
      writer.println()
      
      writer.println("QUESTION 1: Which address blocks have the most repeated homicides?")
      writer.println("ADDRESS BLOCK ANALYSIS")
      writer.println("Rank,Address Block,Homicide Count")
      addressStats.take(20).zipWithIndex.foreach { case (stat, idx) =>
        writer.println(s"""${idx + 1},"${stat.address}",${stat.count}""")
      }
      writer.println()
      
      writer.println("TOP ADDRESS BLOCK DETAILS")
      if (addressStats.nonEmpty) {
        val top = addressStats.head
        writer.println(s"""Location,"${top.address}"""")
        writer.println(s"Total Homicides,${top.count}")
        writer.println()
        writer.println("Date,Name,Age")
        top.victims.foreach { h =>
          writer.println(s"""${h.dateDied},"${h.name}",${h.age}""")
        }
      }
      writer.println()
      
      writer.println("QUESTION 2: Which months have the highest homicide rates?")
      writer.println("MONTHLY ANALYSIS")
      writer.println("Month,Month Name,Homicide Count,Percentage")
      monthStats.foreach { stat =>
        writer.println(f"${stat.month},${stat.monthName},${stat.count},${stat.percentage}%.2f")
      }
      
      println("✅ CSV file 'homicide_analysis.csv' created successfully!")
      
    } finally {
      writer.close()
    }
  }
  
  def outputJSON(homicides: List[Homicide], addressStats: List[AddressStats], monthStats: List[MonthStats]): Unit = {
    val writer = new PrintWriter("homicide_analysis.json")
    
    try {
      writer.println("{")
      writer.println(s"""  "report_title": "Baltimore Homicide Analysis",""")
      writer.println(s"""  "total_records": ${homicides.length},""")
      writer.println(s"""  "address_block_analysis": {""")
      writer.println(s"""    "total_unique_addresses": ${homicides.filter(_.addressBlock.trim.nonEmpty).groupBy(_.addressBlock).size},""")
      writer.println(s"""    "addresses_with_repeats": ${addressStats.length},""")
      writer.println(s"""    "top_addresses": [""")
      
      addressStats.take(20).zipWithIndex.foreach { case (stat, idx) =>
        val comma = if (idx < addressStats.take(20).length - 1) "," else ""
        writer.println(s"""      {""")
        writer.println(s"""        "rank": ${idx + 1},""")
        writer.println(s"""        "address": "${escapeJSON(stat.address)}",""")
        writer.println(s"""        "homicide_count": ${stat.count}""")
        writer.print(s"""      }$comma""")
        writer.println()
      }
      
      writer.println(s"""    ],""")
      writer.println(s"""    "top_address_details": {""")
      
      if (addressStats.nonEmpty) {
        val top = addressStats.head
        writer.println(s"""      "location": "${escapeJSON(top.address)}",""")
        writer.println(s"""      "total_homicides": ${top.count},""")
        writer.println(s"""      "victims": [""")
        
        top.victims.zipWithIndex.foreach { case (h, idx) =>
          val comma = if (idx < top.victims.length - 1) "," else ""
          writer.println(s"""        {""")
          writer.println(s"""          "date": "${h.dateDied}",""")
          writer.println(s"""          "name": "${escapeJSON(h.name)}",""")
          writer.println(s"""          "age": "${h.age}"""")
          writer.print(s"""        }$comma""")
          writer.println()
        }
        
        writer.println(s"""      ]""")
      }
      
      writer.println(s"""    }""")
      writer.println(s"""  },""")
      writer.println(s"""  "monthly_analysis": {""")
      writer.println(s"""    "months": [""")
      
      monthStats.zipWithIndex.foreach { case (stat, idx) =>
        val comma = if (idx < monthStats.length - 1) "," else ""
        writer.println(s"""      {""")
        writer.println(s"""        "month": "${stat.month}",""")
        writer.println(s"""        "month_name": "${stat.monthName}",""")
        writer.println(s"""        "homicide_count": ${stat.count},""")
        writer.println(f"""        "percentage": ${stat.percentage}%.2f""")
        writer.print(s"""      }$comma""")
        writer.println()
      }
      
      writer.println(s"""    ],""")
      
      if (monthStats.nonEmpty) {
        val deadliest = monthStats.head
        writer.println(s"""    "deadliest_month": {""")
        writer.println(s"""      "month": "${deadliest.month}",""")
        writer.println(s"""      "month_name": "${deadliest.monthName}",""")
        writer.println(s"""      "homicide_count": ${deadliest.count}""")
        writer.println(s"""    }""")
      }
      
      writer.println(s"""  }""")
      writer.println("}")
      
      println("✅ JSON file 'homicide_analysis.json' created successfully!")
      
    } finally {
      writer.close()
    }
  }
  
  def escapeJSON(str: String): String = {
    str.replace("\\", "\\\\")
       .replace("\"", "\\\"")
       .replace("\n", "\\n")
       .replace("\r", "\\r")
       .replace("\t", "\\t")
  }
} 