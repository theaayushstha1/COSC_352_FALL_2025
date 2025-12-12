import java.net.URL
import scala.io.Source
import java.io.PrintWriter
import javax.net.ssl.HttpsURLConnection
import java.net.HttpURLConnection
import java.io.File

object HtmlTableToCsv {

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

  def findAllTables(html: String): List[String] = {
    val tables = scala.collection.mutable.ListBuffer[String]()
    var pos = 0
    val htmlLower = html.toLowerCase
    
    while (pos < htmlLower.length) {
      val start = htmlLower.indexOf("<table", pos)
      if (start == -1) {
        pos = htmlLower.length
      } else {
        val end = htmlLower.indexOf("</table>", start)
        if (end == -1) {
          pos = htmlLower.length
        } else {
          tables += html.substring(start, end + 8)
          pos = end + 8
        }
      }
    }
    tables.toList
  }

  def parseTable(tableHtml: String): List[List[String]] = {
    val rows = scala.collection.mutable.ListBuffer[List[String]]()
    var pos = 0
    val tableLower = tableHtml.toLowerCase
    
    while (pos < tableLower.length) {
      val rowStart = tableLower.indexOf("<tr", pos)
      if (rowStart == -1) {
        pos = tableLower.length
      } else {
        val rowEnd = tableLower.indexOf("</tr>", rowStart)
        if (rowEnd == -1) {
          pos = tableLower.length
        } else {
          val rowHtml = tableHtml.substring(rowStart, rowEnd)
          val row = scala.collection.mutable.ListBuffer[String]()
          
          var cellPos = 0
          val rowLower = rowHtml.toLowerCase
          
          while (cellPos < rowLower.length) {
            val tdStart = rowLower.indexOf("<td", cellPos)
            val thStart = rowLower.indexOf("<th", cellPos)
            
            if (tdStart == -1 && thStart == -1) {
              cellPos = rowLower.length
            } else {
              val (tagEnd, start) = if (tdStart == -1 || (thStart != -1 && thStart < tdStart)) {
                ("</th>", thStart)
              } else {
                ("</td>", tdStart)
              }
              
              val contentStart = rowLower.indexOf(">", start) + 1
              val end = rowLower.indexOf(tagEnd, contentStart)
              
              if (end == -1) {
                cellPos = rowLower.length
              } else {
                val cellContent = rowHtml.substring(contentStart, end).trim
                row += cellContent
                cellPos = end + tagEnd.length
              }
            }
          }
          
          rows += row.toList
          pos = rowEnd + 5
        }
      }
    }
    rows.toList
  }

  def safeFilename(url: String, tableIndex: Int): String = {
    val parsed = new URL(url)
    val name = if (parsed.getHost != null && parsed.getPath != null) {
      parsed.getHost + parsed.getPath
    } else if (parsed.getHost != null) {
      parsed.getHost
    } else {
      "output"
    }
    
    val safeName = name
      .replace("/", "_")
      .replace("?", "_")
      .replace("=", "_")
      .replace("&", "_")
      .replace(":", "_")
    
    s"${safeName}_table_${tableIndex}.csv"
  }

  def exportToCsv(tableData: List[List[String]], filename: String): Unit = {
    val writer = new PrintWriter(new File(filename))
    try {
      tableData.foreach { row =>
        val csvRow = row.map { cell =>
          // Escape quotes and wrap in quotes if contains comma, quote, or newline
          if (cell.contains(",") || cell.contains("\"") || cell.contains("\n")) {
            "\"" + cell.replace("\"", "\"\"") + "\""
          } else {
            cell
          }
        }.mkString(",")
        writer.println(csvRow)
      }
    } finally {
      writer.close()
    }
  }

  def htmlTablesToCsv(url: String): Unit = {
    println(s"Fetching: $url")
    val html = fetchHtmlFromUrl(url)
    val tables = findAllTables(html)
    println(s"Found ${tables.length} tables")
    
    if (tables.isEmpty) {
      println("No tables found.")
      return
    }
    
    tables.zipWithIndex.foreach { case (table, index) =>
      val rows = parseTable(table)
      if (rows.nonEmpty) {
        val filename = safeFilename(url, index + 1)
        exportToCsv(rows, filename)
        println(s"Saved $filename")
      }
    }
  }

  def main(args: Array[String]): Unit = {
    val url = if (args.length > 0) {
      args(0)
    } else {
      print("Enter a URL (http:// or https://): ")
      scala.io.StdIn.readLine().trim
    }
    
    htmlTablesToCsv(url)
  }
}