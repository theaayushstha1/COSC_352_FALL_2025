import scala.io.Source
import scala.util.{Try, Success, Failure}
import java.io.{PrintWriter, File}
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

case class CrimeRecord(
  id: String,
  caseNumber: String,
  date: String,
  block: String,
  iucr: String,
  primaryType: String,
  description: String,
  locationDescription: String,
  arrest: Boolean,
  domestic: Boolean,
  beat: String,
  district: String,
  ward: String,
  communityArea: String,
  fbiCode: String,
  xCoordinate: String,
  yCoordinate: String,
  year: String,
  updatedOn: String,
  latitude: String,
  longitude: String,
  location: String
)

object CrimeDataApp {
  
  def main(args: Array[String]): Unit = {
    val outputFormat = parseArgs(args)
    
    println(s"Crime Data Analysis Tool")
    println(s"Output Format: $outputFormat")
    println("-" * 50)
    
    val csvFile = "data/crimes.csv"
    
    Try {
      val records = loadCrimeData(csvFile)
      
      outputFormat match {
        case "csv" => 
          writeCSV(records)
          println("Data written to output/crime_report.csv")
        case "json" => 
          writeJSON(records)
          println("Data written to output/crime_report.json")
        case _ => 
          printToStdout(records)
      }
      
    } match {
      case Success(_) => println("\nProcessing completed successfully")
      case Failure(e) => 
        println(s"Error: ${e.getMessage}")
        e.printStackTrace()
    }
  }
  
  def parseArgs(args: Array[String]): String = {
    args.find(_.startsWith("--output=")) match {
      case Some(arg) => 
        val format = arg.split("=")(1).toLowerCase
        if (format == "csv" || format == "json") format
        else {
          println(s"Warning: Unknown format '$format', defaulting to stdout")
          "stdout"
        }
      case None => "stdout"
    }
  }
  
  def loadCrimeData(filename: String): List[CrimeRecord] = {
    val source = Source.fromFile(filename)
    try {
      val lines = source.getLines().toList
      val dataLines = lines.tail // Skip header
      
      dataLines.flatMap { line =>
        parseCrimeLine(line)
      }
    } finally {
      source.close()
    }
  }
  
  def parseCrimeLine(line: String): Option[CrimeRecord] = {
    Try {
      val fields = parseCSVLine(line)
      if (fields.length >= 21) {
        Some(CrimeRecord(
          id = fields(0),
          caseNumber = fields(1),
          date = fields(2),
          block = fields(3),
          iucr = fields(4),
          primaryType = fields(5),
          description = fields(6),
          locationDescription = fields(7),
          arrest = fields(8).toLowerCase == "true",
          domestic = fields(9).toLowerCase == "true",
          beat = fields(10),
          district = fields(11),
          ward = fields(12),
          communityArea = fields(13),
          fbiCode = fields(14),
          xCoordinate = fields(15),
          yCoordinate = fields(16),
          year = fields(17),
          updatedOn = fields(18),
          latitude = fields(19),
          longitude = fields(20),
          location = if (fields.length > 21) fields(21) else ""
        ))
      } else None
    }.getOrElse(None)
  }
  
  def parseCSVLine(line: String): Array[String] = {
    val result = scala.collection.mutable.ArrayBuffer[String]()
    var current = new StringBuilder
    var inQuotes = false
    
    for (c <- line) {
      c match {
        case '"' => inQuotes = !inQuotes
        case ',' if !inQuotes =>
          result += current.toString.trim
          current = new StringBuilder
        case _ => current += c
      }
    }
    result += current.toString.trim
    result.toArray
  }
  
  def printToStdout(records: List[CrimeRecord]): Unit = {
    println("\n=== Crime Data Summary ===\n")
    println(f"Total Records: ${records.length}%,d")
    
    // Crime type analysis
    val crimeTypes = records.groupBy(_.primaryType).mapValues(_.length)
    println("\n--- Top 10 Crime Types ---")
    crimeTypes.toSeq.sortBy(-_._2).take(10).foreach { case (crimeType, count) =>
      println(f"$crimeType%-30s: $count%,6d")
    }
    
    // Arrest statistics
    val arrestCount = records.count(_.arrest)
    val arrestRate = (arrestCount.toDouble / records.length) * 100
    println(f"\n--- Arrest Statistics ---")
    println(f"Arrests Made: $arrestCount%,d (${arrestRate}%.2f%%)")
    println(f"No Arrest: ${records.length - arrestCount}%,d (${100 - arrestRate}%.2f%%)")
    
    // District analysis
    val districts = records.filter(_.district.nonEmpty).groupBy(_.district).mapValues(_.length)
    println("\n--- Top 10 Districts by Crime Count ---")
    districts.toSeq.sortBy(-_._2).take(10).foreach { case (district, count) =>
      println(f"District $district%-3s: $count%,6d crimes")
    }
    
    // Domestic incidents
    val domesticCount = records.count(_.domestic)
    val domesticRate = (domesticCount.toDouble / records.length) * 100
    println(f"\n--- Domestic Incidents ---")
    println(f"Domestic: $domesticCount%,d (${domesticRate}%.2f%%)")
    println(f"Non-Domestic: ${records.length - domesticCount}%,d (${100 - domesticRate}%.2f%%)")
  }
  
  def writeCSV(records: List[CrimeRecord]): Unit = {
    new File("output").mkdirs()
    val writer = new PrintWriter(new File("output/crime_report.csv"))
    
    try {
      // Write header
      writer.println("ID,Case Number,Date,Block,IUCR,Primary Type,Description," +
        "Location Description,Arrest,Domestic,Beat,District,Ward,Community Area," +
        "FBI Code,X Coordinate,Y Coordinate,Year,Updated On,Latitude,Longitude,Location")
      
      // Write data
      records.foreach { record =>
        writer.println(
          s"${escapeCSV(record.id)}," +
          s"${escapeCSV(record.caseNumber)}," +
          s"${escapeCSV(record.date)}," +
          s"${escapeCSV(record.block)}," +
          s"${escapeCSV(record.iucr)}," +
          s"${escapeCSV(record.primaryType)}," +
          s"${escapeCSV(record.description)}," +
          s"${escapeCSV(record.locationDescription)}," +
          s"${record.arrest}," +
          s"${record.domestic}," +
          s"${escapeCSV(record.beat)}," +
          s"${escapeCSV(record.district)}," +
          s"${escapeCSV(record.ward)}," +
          s"${escapeCSV(record.communityArea)}," +
          s"${escapeCSV(record.fbiCode)}," +
          s"${escapeCSV(record.xCoordinate)}," +
          s"${escapeCSV(record.yCoordinate)}," +
          s"${escapeCSV(record.year)}," +
          s"${escapeCSV(record.updatedOn)}," +
          s"${escapeCSV(record.latitude)}," +
          s"${escapeCSV(record.longitude)}," +
          s"${escapeCSV(record.location)}"
        )
      }
    } finally {
      writer.close()
    }
  }
  
  def escapeCSV(field: String): String = {
    if (field.contains(",") || field.contains("\"") || field.contains("\n")) {
      "\"" + field.replace("\"", "\"\"") + "\""
    } else {
      field
    }
  }
  
  def writeJSON(records: List[CrimeRecord]): Unit = {
    new File("output").mkdirs()
    val writer = new PrintWriter(new File("output/crime_report.json"))
    
    try {
      writer.println("{")
      writer.println(s"""  "metadata": {""")
      writer.println(s"""    "generated_at": "${LocalDateTime.now().format(DateTimeFormatter.ISO_DATE_TIME)}",""")
      writer.println(s"""    "total_records": ${records.length},""")
      writer.println(s"""    "format_version": "1.0"""")
      writer.println("  },")
      writer.println(s"""  "records": [""")
      
      records.zipWithIndex.foreach { case (record, index) =>
        writer.println("    {")
        writer.println(s"""      "id": "${escapeJSON(record.id)}",""")
        writer.println(s"""      "case_number": "${escapeJSON(record.caseNumber)}",""")
        writer.println(s"""      "date": "${escapeJSON(record.date)}",""")
        writer.println(s"""      "block": "${escapeJSON(record.block)}",""")
        writer.println(s"""      "iucr": "${escapeJSON(record.iucr)}",""")
        writer.println(s"""      "primary_type": "${escapeJSON(record.primaryType)}",""")
        writer.println(s"""      "description": "${escapeJSON(record.description)}",""")
        writer.println(s"""      "location_description": "${escapeJSON(record.locationDescription)}",""")
        writer.println(s"""      "arrest": ${record.arrest},""")
        writer.println(s"""      "domestic": ${record.domestic},""")
        writer.println(s"""      "beat": "${escapeJSON(record.beat)}",""")
        writer.println(s"""      "district": "${escapeJSON(record.district)}",""")
        writer.println(s"""      "ward": "${escapeJSON(record.ward)}",""")
        writer.println(s"""      "community_area": "${escapeJSON(record.communityArea)}",""")
        writer.println(s"""      "fbi_code": "${escapeJSON(record.fbiCode)}",""")
        writer.println(s"""      "x_coordinate": "${escapeJSON(record.xCoordinate)}",""")
        writer.println(s"""      "y_coordinate": "${escapeJSON(record.yCoordinate)}",""")
        writer.println(s"""      "year": "${escapeJSON(record.year)}",""")
        writer.println(s"""      "updated_on": "${escapeJSON(record.updatedOn)}",""")
        writer.println(s"""      "latitude": "${escapeJSON(record.latitude)}",""")
        writer.println(s"""      "longitude": "${escapeJSON(record.longitude)}",""")
        writer.println(s"""      "location": "${escapeJSON(record.location)}"""")
        
        if (index < records.length - 1) {
          writer.println("    },")
        } else {
          writer.println("    }")
        }
      }
      
      writer.println("  ]")
      writer.println("}")
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
