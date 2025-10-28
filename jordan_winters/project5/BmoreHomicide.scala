import scala.io.Source
import scala.util.Try
import scala.collection.mutable
import java.io.{File, PrintWriter}

case class HomicideRecord(
  caseNumber: String,
  year: Int,
  month: Int,
  day: Int,
  age: Option[Int],
  gender: String,
  race: String,
  ethnicity: String,
  district: String,
  premise: String,
  weapon: String,
  disposition: String,
  outside: String
)

sealed trait OutputFormat
case object StdOut extends OutputFormat
case object CSV extends OutputFormat
case object JSON extends OutputFormat

object BmoreHomicide {
  
  def main(args: Array[String]): Unit = {
    // Parse command line arguments for output format
    val outputFormat = parseArgs(args)
    
    val url = "https://chamspage.blogspot.com/"
    
    // Parse homicide data
    val records = parseHomicideData()
    
    if (records.isEmpty) {
      System.err.println("Warning: No data loaded.")
    }
    
    // Output in the specified format
    outputFormat match {
      case StdOut => outputToStdOut(records)
      case CSV => outputToCsv(records)
      case JSON => outputToJson(records)
    }
  }
  
  def parseArgs(args: Array[String]): OutputFormat = {
    args.find(_.startsWith("--output=")) match {
      case Some(arg) =>
        val format = arg.split("=", 2)(1).toLowerCase
        format match {
          case "csv" => CSV
          case "json" => JSON
          case "stdout" => StdOut
          case other =>
            System.err.println(s"Unknown output format: $other. Using stdout.")
            StdOut
        }
      case None => StdOut // Default
    }
  }
  
  def parseHomicideData(): List[HomicideRecord] = {
    // Sample data structure - in production this would parse CSV/HTML from the blog
    List(
      HomicideRecord("2023-001", 2023, 1, 15, Some(34), "M", "B", "N", "Eastern", "Street", "Gun", "Open", "N"),
      HomicideRecord("2023-002", 2023, 1, 18, Some(28), "M", "B", "N", "Eastern", "Street", "Gun", "Open", "N"),
      HomicideRecord("2023-003", 2023, 1, 22, Some(31), "M", "B", "N", "Eastern", "Street", "Firearm", "Open", "N"),
      HomicideRecord("2023-004", 2023, 2, 3, Some(25), "M", "W", "N", "Western", "Residence", "Gun", "Closed", "N"),
      HomicideRecord("2023-005", 2023, 5, 14, Some(45), "M", "B", "N", "Northeast", "Street", "Firearm", "Open", "N"),
      HomicideRecord("2023-006", 2023, 5, 20, Some(38), "M", "B", "N", "Northeast", "Street", "Gun", "Open", "N"),
      HomicideRecord("2023-007", 2023, 5, 25, Some(41), "M", "B", "N", "Northeast", "Street", "Gun", "Open", "N"),
      HomicideRecord("2023-008", 2023, 6, 5, Some(52), "F", "B", "N", "Central", "Residence", "Knife", "Closed", "N"),
      HomicideRecord("2023-009", 2023, 7, 12, Some(22), "M", "H", "Y", "Southwest", "Street", "Firearm", "Open", "N"),
      HomicideRecord("2023-010", 2023, 7, 19, Some(19), "M", "H", "Y", "Southwest", "Street", "Gun", "Open", "N"),
      HomicideRecord("2024-001", 2024, 3, 10, Some(33), "M", "B", "N", "Eastern", "Street", "Firearm", "Open", "N"),
      HomicideRecord("2024-002", 2024, 3, 15, Some(29), "M", "B", "N", "Eastern", "Street", "Gun", "Open", "N"),
      HomicideRecord("2024-003", 2024, 8, 23, Some(50), "M", "B", "N", "Southeast", "Street", "Firearm", "Open", "N"),
      HomicideRecord("2024-004", 2024, 9, 2, Some(27), "F", "B", "N", "Southeast", "Residence", "Gun", "Closed", "N")
    )
  }
  
  // ========== OUTPUT FUNCTIONS ==========
  
  def outputToStdOut(records: List[HomicideRecord]): Unit = {
    // Original Project 4 stdout format
    println("Baltimore City Homicide Data")
    println("=" * 80)
    
    records.foreach { record =>
      println(s"Case Number: ${record.caseNumber}")
      println(s"  Date: ${record.year}-${"%02d".format(record.month)}-${"%02d".format(record.day)}")
      val ageStr = record.age.map(_.toString).getOrElse("Unknown")
      println(s"  Victim: ${record.gender}, Age ${ageStr}, Race: ${record.race}, Ethnicity: ${record.ethnicity}")
      println(s"  Location: ${record.district} District, ${record.premise}")
      println(s"  Weapon: ${record.weapon}")
      println(s"  Status: ${record.disposition}, Outside: ${record.outside}")
      println("-" * 80)
    }
    
    println(s"\nTotal Records: ${records.length}")
  }
  
  def outputToCsv(records: List[HomicideRecord]): Unit = {
    val filename = "baltimore_homicides.csv"
    val writer = new PrintWriter(new File(filename))
    
    Try {
      // Write header row
      writer.println("case_number,year,month,day,age,gender,race,ethnicity,district,premise,weapon,disposition,outside")
      
      // Write data rows
      records.foreach { record =>
        val ageStr = record.age.map(_.toString).getOrElse("")
        
        writer.println(
          s""""${escapeCsv(record.caseNumber)}",""" +
          s"${record.year},${record.month},${record.day}," +
          s"$ageStr," +
          s""""${escapeCsv(record.gender)}",""" +
          s""""${escapeCsv(record.race)}",""" +
          s""""${escapeCsv(record.ethnicity)}",""" +
          s""""${escapeCsv(record.district)}",""" +
          s""""${escapeCsv(record.premise)}",""" +
          s""""${escapeCsv(record.weapon)}",""" +
          s""""${escapeCsv(record.disposition)}",""" +
          s""""${escapeCsv(record.outside)}""""
        )
      }
      
    } match {
      case scala.util.Success(_) =>
        writer.close()
        println(s"CSV output written to $filename (${records.length} records)")
      case scala.util.Failure(e) =>
        writer.close()
        System.err.println(s"Error writing CSV: ${e.getMessage}")
    }
  }
  
  def outputToJson(records: List[HomicideRecord]): Unit = {
    val filename = "baltimore_homicides.json"
    val writer = new PrintWriter(new File(filename))
    
    Try {
      writer.println("{")
      writer.println(s"""  "source": "Baltimore City Homicide Data",""")
      writer.println(s"""  "url": "https://chamspage.blogspot.com/",""")
      writer.println(s"""  "total_records": ${records.length},""")
      writer.println(s"""  "records": [""")
      
      records.zipWithIndex.foreach { case (record, index) =>
        writer.println("    {")
        writer.println(s"""      "case_number": "${escapeJson(record.caseNumber)}",""")
        writer.println(s"""      "year": ${record.year},""")
        writer.println(s"""      "month": ${record.month},""")
        writer.println(s"""      "day": ${record.day},""")
        
        record.age match {
          case Some(age) => writer.println(s"""      "age": $age,""")
          case None => writer.println(s"""      "age": null,""")
        }
        
        writer.println(s"""      "gender": "${escapeJson(record.gender)}",""")
        writer.println(s"""      "race": "${escapeJson(record.race)}",""")
        writer.println(s"""      "ethnicity": "${escapeJson(record.ethnicity)}",""")
        writer.println(s"""      "district": "${escapeJson(record.district)}",""")
        writer.println(s"""      "premise": "${escapeJson(record.premise)}",""")
        writer.println(s"""      "weapon": "${escapeJson(record.weapon)}",""")
        writer.println(s"""      "disposition": "${escapeJson(record.disposition)}",""")
        writer.println(s"""      "outside": "${escapeJson(record.outside)}"""")
        
        if (index < records.length - 1) {
          writer.println("    },")
        } else {
          writer.println("    }")
        }
      }
      
      writer.println("  ]")
      writer.println("}")
    } match {
      case scala.util.Success(_) =>
        writer.close()
        println(s"JSON output written to $filename (${records.length} records)")
      case scala.util.Failure(e) =>
        writer.close()
        System.err.println(s"Error writing JSON: ${e.getMessage}")
    }
  }
  
  // Escape special characters for CSV
  def escapeCsv(str: String): String = {
    str.replace("\"", "\"\"")
  }
  
  // Escape special characters for JSON
  def escapeJson(str: String): String = {
    str
      .replace("\\", "\\\\")
      .replace("\"", "\\\"")
      .replace("\n", "\\n")
      .replace("\r", "\\r")
      .replace("\t", "\\t")
  }
}