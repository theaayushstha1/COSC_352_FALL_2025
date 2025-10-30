import org.jsoup.Jsoup
import org.jsoup.nodes.{Document, Element}
import scala.jdk.CollectionConverters._
import java.io.{PrintWriter, File}

object BaltimoreHomicideScraper {
  
  case class Homicide(
    date: String,
    victim: String,
    age: String,
    gender: String,
    race: String,
    cause: String,
    location: String,
    disposition: String
  )
  
  def main(args: Array[String]): Unit = {
    // Parse command line arguments
    val outputFormat = args.find(_.startsWith("--output="))
      .map(_.stripPrefix("--output=").toLowerCase)
      .getOrElse("stdout")
    
    // Scrape the data
    val homicides = scrapeData()
    
    // Output in the specified format
    outputFormat match {
      case "csv" => outputCsv(homicides)
      case "json" => outputJson(homicides)
      case "stdout" => outputStdout(homicides)
      case _ => 
        println(s"Unknown output format: $outputFormat")
        println("Valid formats: stdout, csv, json")
        sys.exit(1)
    }
  }
  
  def scrapeData(): List[Homicide] = {
    val doc: Document = Jsoup.connect("https://chamspage.blogspot.com/").get()
    val rows = doc.select("table tr").asScala.toList
    
    rows.drop(1).flatMap { row =>
      val cells = row.select("td").asScala.map(_.text()).toList
      if (cells.length >= 8) {
        Some(Homicide(
          date = cells(0),
          victim = cells(1),
          age = cells(2),
          gender = cells(3),
          race = cells(4),
          cause = cells(5),
          location = cells(6),
          disposition = cells(7)
        ))
      } else None
    }
  }
  
  def outputStdout(homicides: List[Homicide]): Unit = {
    println("Baltimore Homicide Data")
    println("=" * 80)
    println(f"${"Date"}%-12s ${"Victim"}%-25s ${"Age"}%-5s ${"Gender"}%-8s ${"Race"}%-10s")
    println("-" * 80)
    
    homicides.foreach { h =>
      println(f"${h.date}%-12s ${h.victim}%-25s ${h.age}%-5s ${h.gender}%-8s ${h.race}%-10s")
    }
    
    println("-" * 80)
    println(s"Total records: ${homicides.length}")
  }
  
  def outputCsv(homicides: List[Homicide]): Unit = {
    val outputDir = new File("output")
    if (!outputDir.exists()) outputDir.mkdirs()
    
    val writer = new PrintWriter(new File("output/baltimore_homicides.csv"))
    
    // Write header
    writer.println("date,victim,age,gender,race,cause,location,disposition")
    
    // Write data rows
    homicides.foreach { h =>
      writer.println(s""""${escapeCsv(h.date)}","${escapeCsv(h.victim)}","${escapeCsv(h.age)}","${escapeCsv(h.gender)}","${escapeCsv(h.race)}","${escapeCsv(h.cause)}","${escapeCsv(h.location)}","${escapeCsv(h.disposition)}"""")
    }
    
    writer.close()
    println(s"CSV file written: output/baltimore_homicides.csv")
    println(s"Total records: ${homicides.length}")
  }
  
  def outputJson(homicides: List[Homicide]): Unit = {
    val outputDir = new File("output")
    if (!outputDir.exists()) outputDir.mkdirs()
    
    val writer = new PrintWriter(new File("output/baltimore_homicides.json"))
    
    writer.println("{")
    writer.println(s"""  "metadata": {""")
    writer.println(s"""    "source": "Baltimore Homicide Data",""")
    writer.println(s"""    "total_records": ${homicides.length},""")
    writer.println(s"""    "generated_at": "${java.time.LocalDateTime.now()}"""")
    writer.println("  },")
    writer.println("""  "homicides": [""")
    
    homicides.zipWithIndex.foreach { case (h, idx) =>
      writer.println("    {")
      writer.println(s"""      "date": "${escapeJson(h.date)}",""")
      writer.println(s"""      "victim": "${escapeJson(h.victim)}",""")
      writer.println(s"""      "age": "${escapeJson(h.age)}",""")
      writer.println(s"""      "gender": "${escapeJson(h.gender)}",""")
      writer.println(s"""      "race": "${escapeJson(h.race)}",""")
      writer.println(s"""      "cause": "${escapeJson(h.cause)}",""")
      writer.println(s"""      "location": "${escapeJson(h.location)}",""")
      writer.println(s"""      "disposition": "${escapeJson(h.disposition)}"""")
      if (idx < homicides.length - 1) {
        writer.println("    },")
      } else {
        writer.println("    }")
      }
    }
    
    writer.println("  ]")
    writer.println("}")
    
    writer.close()
    println(s"JSON file written: output/baltimore_homicides.json")
    println(s"Total records: ${homicides.length}")
  }
  
  def escapeCsv(str: String): String = {
    str.replace("\"", "\"\"")
  }
  
  def escapeJson(str: String): String = {
    str.replace("\\", "\\\\")
       .replace("\"", "\\\"")
       .replace("\n", "\\n")
       .replace("\r", "\\r")
       .replace("\t", "\\t")
  }
}