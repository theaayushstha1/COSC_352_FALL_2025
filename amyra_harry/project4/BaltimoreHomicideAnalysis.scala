import java.net.URL
import scala.io.Source
import javax.net.ssl.HttpsURLConnection
import java.net.HttpURLConnection

object BaltimoreHomicideAnalysis {

  case class Homicide(
    number: String,
    date: String,
    name: String,
    age: String,
    location: String,
    notes: String
  )

  def fetchHtmlFromUrl(url: String): String = {
    val parsed = new URL(url)
    val scheme = Option(parsed.getProtocol).getOrElse("http")
    
    val connection = if (scheme == "https") {
      parsed.openConnection().asInstanceOf[HttpsURLConnection]
    } else {
      parsed.openConnection().asInstanceOf[HttpURLConnection]
    }
    
    connection.setRequestMethod("GET")
    connection.setRequestProperty("User-Agent", "Mozilla/5.0")
    
    val html = Source.fromInputStream(connection.getInputStream, "UTF-8").mkString
    connection.disconnect()
    html
  }

  def stripHtmlTags(text: String): String = {
    text.replaceAll("<[^>]*>", "").replaceAll("\\s+", " ").trim
  }

  def parseTableData(html: String): List[Homicide] = {
    val homicides = scala.collection.mutable.ListBuffer[Homicide]()
    
    // Split by table rows
    val rows = html.split("(?i)<tr[^>]*>")
    
    for (row <- rows.drop(1)) { // Skip header row
      if (row.contains("</tr>")) {
        val cells = scala.collection.mutable.ListBuffer[String]()
        
        // Extract all cells from the row
        var remaining = row
        while (remaining.contains("<td") || remaining.contains("<th")) {
          val tdIdx = if (remaining.toLowerCase.indexOf("<td") >= 0) remaining.toLowerCase.indexOf("<td") else Int.MaxValue
          val thIdx = if (remaining.toLowerCase.indexOf("<th") >= 0) remaining.toLowerCase.indexOf("<th") else Int.MaxValue
          
          if (tdIdx == Int.MaxValue && thIdx == Int.MaxValue) {
            remaining = ""
          } else {
            val startIdx = if (tdIdx < thIdx) tdIdx else thIdx
            val tagName = if (tdIdx < thIdx) "td" else "th"
            
            val contentStart = remaining.indexOf(">", startIdx) + 1
            val endTag = s"</$tagName>"
            val contentEnd = remaining.toLowerCase.indexOf(endTag, contentStart)
            
            if (contentEnd > contentStart) {
              val content = stripHtmlTags(remaining.substring(contentStart, contentEnd))
              cells += content
              remaining = remaining.substring(contentEnd + endTag.length)
            } else {
              remaining = ""
            }
          }
        }
        
        // Parse if we have enough cells
        if (cells.length >= 6) {
          val number = cells(0)
          val date = cells(1)
          val name = cells(2)
          val age = cells(3)
          val location = cells(4)
          val notes = cells(5)
          
          // Skip empty rows and header rows
          if (number.nonEmpty && !number.equalsIgnoreCase("No.") && date.nonEmpty) {
            homicides += Homicide(number, date, name, age, location, notes)
          }
        }
      }
    }
    
    homicides.toList
  }

  def analyzeData(homicides: List[Homicide]): Unit = {
    println(s"Total homicides found: ${homicides.length}")
    println()
    
    // Question 1: How many people were stabbing victims in 2025?
    println("Question 1: How many people were stabbing victims in 2025?")
    println("=" * 90)
    
    val stabbingVictims2025 = homicides.filter { h =>
      h.date.contains("/25") && 
      (h.notes.toLowerCase.contains("stab") || h.notes.toLowerCase.contains("cutting"))
    }
    
    println(f"${"No."}%-5s ${"Date"}%-12s ${"Name"}%-30s ${"Age"}%-5s ${"Location"}%-30s")
    println("-" * 90)
    stabbingVictims2025.foreach { h =>
      println(f"${h.number}%-5s ${h.date}%-12s ${h.name.take(30)}%-30s ${h.age}%-5s ${h.location.take(30)}%-30s")
    }
    println(s"\nTotal stabbing victims in 2025: ${stabbingVictims2025.length}")
    println()
    
    // Question 2: How many people were killed in East Baltimore?
    println("Question 2: How many people were killed in the East Baltimore region?")
    println("=" * 90)
    
    val eastBaltimoreVictims = homicides.filter { h =>
      val loc = h.location.toLowerCase
      loc.contains("east") || loc.contains(" e. ") || loc.contains("eastern")
    }
    
    println(f"${"No."}%-5s ${"Date"}%-12s ${"Name"}%-30s ${"Age"}%-5s ${"Location"}%-30s")
    println("-" * 90)
    eastBaltimoreVictims.foreach { h =>
      println(f"${h.number}%-5s ${h.date}%-12s ${h.name.take(30)}%-30s ${h.age}%-5s ${h.location.take(30)}%-30s")
    }
    println(s"\nTotal victims in East Baltimore region: ${eastBaltimoreVictims.length}")
  }

  def main(args: Array[String]): Unit = {
    val url = "http://chamspage.blogspot.com/"
    
    println("Fetching Baltimore Homicide Data...")
    println()
    
    try {
      val html = fetchHtmlFromUrl(url)
      val homicides = parseTableData(html)
      
      if (homicides.isEmpty) {
        println("Error: Could not parse homicide data.")
        println("The website structure may have changed.")
        return
      }
      
      analyzeData(homicides)
      
    } catch {
      case e: Exception =>
        println(s"Error: ${e.getMessage}")
        e.printStackTrace()
    }
  }
}