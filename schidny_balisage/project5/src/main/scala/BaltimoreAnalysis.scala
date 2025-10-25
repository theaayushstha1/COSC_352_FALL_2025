import org.apache.spark.sql.{SparkSession, DataFrame}
import org.apache.spark.sql.functions._
import java.io.{File, PrintWriter}

object BaltimoreAnalysis {
  
  case class CrimeStats(
    neighborhood: String,
    totalCrimes: Long,
    violentCrimes: Long,
    propertyCrimes: Long,
    averagePerMonth: Double
  )
  
  def main(args: Array[String]): Unit = {
    // Parse command line arguments
    val outputFormat = args.find(_.startsWith("--output="))
      .map(_.split("=")(1).toLowerCase)
      .getOrElse("stdout")
    
    val spark = SparkSession.builder()
      .appName("Baltimore Crime Analysis")
      .master("local[*]")
      .getOrCreate()
    
    import spark.implicits._
    
    // Read the crime data
    val crimesDF = spark.read
      .option("header", "true")
      .option("inferSchema", "true")
      .csv("/data/BPD_Part_1_Victim_Based_Crime_Data.csv")
    
    // Perform analysis - group by neighborhood and count crimes
    val crimeStats = crimesDF
      .filter($"Neighborhood".isNotNull && $"Neighborhood" =!= "")
      .groupBy("Neighborhood")
      .agg(
        count("*").as("totalCrimes"),
        sum(when($"Description".contains("ASSAULT") || 
                 $"Description".contains("ROBBERY") || 
                 $"Description".contains("HOMICIDE"), 1).otherwise(0)).as("violentCrimes"),
        sum(when($"Description".contains("BURGLARY") || 
                 $"Description".contains("LARCENY") || 
                 $"Description".contains("THEFT"), 1).otherwise(0)).as("propertyCrimes")
      )
      .withColumn("averagePerMonth", $"totalCrimes" / 12.0)
      .orderBy($"totalCrimes".desc)
    
    // Convert to case class for easier manipulation
    val statsData = crimeStats.as[CrimeStats].collect()
    
    // Output based on format
    outputFormat match {
      case "csv" => writeCsv(statsData)
      case "json" => writeJson(statsData)
      case "stdout" | _ => writeStdout(statsData)
    }
    
    spark.stop()
  }
  
  def writeStdout(data: Array[CrimeStats]): Unit = {
    println("Baltimore Crime Statistics by Neighborhood")
    println("=" * 80)
    println(f"${"Neighborhood"}%-30s ${"Total"}%10s ${"Violent"}%10s ${"Property"}%10s ${"Avg/Month"}%10s")
    println("-" * 80)
    data.foreach { stat =>
      println(f"${stat.neighborhood}%-30s ${stat.totalCrimes}%10d ${stat.violentCrimes}%10d ${stat.propertyCrimes}%10d ${stat.averagePerMonth}%10.2f")
    }
    println("=" * 80)
  }
  
  def writeCsv(data: Array[CrimeStats]): Unit = {
    val filename = "baltimore_crime_stats.csv"
    val writer = new PrintWriter(new File(filename))
    
    try {
      // Write header
      writer.println("neighborhood,total_crimes,violent_crimes,property_crimes,average_per_month")
      
      // Write data rows
      data.foreach { stat =>
        writer.println(s"${escapeCsv(stat.neighborhood)},${stat.totalCrimes},${stat.violentCrimes},${stat.propertyCrimes},${stat.averagePerMonth}")
      }
      
      println(s"CSV output written to: $filename")
    } finally {
      writer.close()
    }
  }
  
  def writeJson(data: Array[CrimeStats]): Unit = {
    val filename = "baltimore_crime_stats.json"
    val writer = new PrintWriter(new File(filename))
    
    try {
      writer.println("{")
      writer.println("  \"metadata\": {")
      writer.println("    \"source\": \"Baltimore Police Department Part 1 Crime Data\",")
      writer.println("    \"generated_at\": \"" + java.time.LocalDateTime.now() + "\",")
      writer.println(s"    \"total_neighborhoods\": ${data.length}")
      writer.println("  },")
      writer.println("  \"crime_statistics\": [")
      
      data.zipWithIndex.foreach { case (stat, idx) =>
        writer.println("    {")
        writer.println(s"      \"neighborhood\": ${escapeJson(stat.neighborhood)},")
        writer.println(s"      \"total_crimes\": ${stat.totalCrimes},")
        writer.println(s"      \"violent_crimes\": ${stat.violentCrimes},")
        writer.println(s"      \"property_crimes\": ${stat.propertyCrimes},")
        writer.println(s"      \"average_per_month\": ${stat.averagePerMonth}")
        writer.print("    }")
        if (idx < data.length - 1) writer.println(",")
        else writer.println()
      }
      
      writer.println("  ]")
      writer.println("}")
      
      println(s"JSON output written to: $filename")
    } finally {
      writer.close()
    }
  }
  
  def escapeCsv(str: String): String = {
    if (str.contains(",") || str.contains("\"") || str.contains("\n")) {
      "\"" + str.replace("\"", "\"\"") + "\""
    } else {
      str
    }
  }
  
  def escapeJson(str: String): String = {
    "\"" + str.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n") + "\""
  }
}
