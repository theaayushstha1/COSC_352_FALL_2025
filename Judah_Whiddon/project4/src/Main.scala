import java.net.http.{HttpClient, HttpRequest, HttpResponse}
import java.net.URI
import java.util.regex.Pattern
import scala.collection.mutable

object Main {
  
  // URLs for both years
  
  val Years = Seq("2024", "2025")
  def urlFor(year: String): String =
    s"https://chamspage.blogspot.com/$year/01/$year-baltimore-city-homicide-list.html"

  // Download HTML
  def fetch(url: String): String = {
    val client = HttpClient.newHttpClient()
    val req = HttpRequest.newBuilder(URI.create(url)).GET().build()
    val res = client.send(req, HttpResponse.BodyHandlers.ofString())
    if (res.statusCode() != 200) throw new RuntimeException(s"HTTP ${res.statusCode()} fetching $url")
    res.body()
  }

  
  // Data holder
  
  final case class Row(dateStr: Option[String], closedTag: Option[String])

  // Parse rows from HTML
  def parseRows(html: String): Seq[Row] = {
    val text = html
      .replaceAll("(?s)<script.*?</script>", "")
      .replaceAll("(?s)<style.*?</style>", "")
      .replaceAll("<[^>]+>", " ")
      .replaceAll("&nbsp;", " ")
      .replaceAll("\\s+", " ")
      .trim

    val entryRegex = Pattern.compile(
      "(?:^|\\s)(\\d{1,3})\\s+(\\d{2}/\\d{2}/\\d{2})",
      Pattern.CASE_INSENSITIVE
    )
    val m = entryRegex.matcher(text)

    val rows = mutable.ArrayBuffer[Row]()
    while (m.find()) {
      val dateStr = m.group(2)
      val tailStart = m.end(2)
      val tailEnd = Math.min(tailStart + 250, text.length)
      val tail = text.substring(tailStart, tailEnd)
      val closed =
        if (tail.matches(".*\\bClosed\\b.*")) Some("Closed") else None
      rows += Row(Some(dateStr), closed)
    }
    rows.toSeq
  }

  
  // Month encoding
  
  def monthName(mm: String): String = mm match {
    case "01" => "January"
    case "02" => "February"
    case "03" => "March"
    case "04" => "April"
    case "05" => "May"
    case "06" => "June"
    case "07" => "July"
    case "08" => "August"
    case "09" => "September"
    case "10" => "October"
    case "11" => "November"
    case "12" => "December"
    case _    => "Unknown"
  }

  
  // Main program

  def main(args: Array[String]): Unit = {
    //QUESTION 1: Monthly counts 
    println("Question 1: Between 2024 and 2025, which months had the highest number of homicides?")
    for (year <- Years) {
      val html = fetch(urlFor(year))
      val rows = parseRows(html)

      // Count by month
      val monthCounts = mutable.LinkedHashMap[String, Int](
        "January" -> 0, "February" -> 0, "March" -> 0, "April" -> 0,
        "May" -> 0, "June" -> 0, "July" -> 0, "August" -> 0,
        "September" -> 0, "October" -> 0, "November" -> 0, "December" -> 0
      )
      rows.foreach { r =>
        r.dateStr.foreach { ds =>
          val mm = ds.take(2)
          val mn = monthName(mm)
          if (monthCounts.contains(mn)) monthCounts.update(mn, monthCounts(mn) + 1)
        }
      }

      val sorted = monthCounts.toSeq.sortBy(-_._2)
      val total = sorted.map(_._2).sum
      println(s"\n$year:")
      println("Month        | Count")
      println("----------------------")
      sorted.foreach { case (m, c) => if (c > 0) println(f"$m%-12s | $c") }
      println(s"Total homicides recorded: $total\n")
    }

    //  QUESTION 2: Closed vs Open 
    val year = "2024"
    println(s"Question 2: In $year, how many homicide cases are marked 'Closed' vs 'Open'?")
    val html = fetch(urlFor(year))
    val rows = parseRows(html)
    val closed = rows.count(_.closedTag.contains("Closed"))
    val open = rows.size - closed
    val total = rows.size
    val pct = if (total > 0) f"${closed.toDouble * 100.0 / total}%.1f%%" else "n/a"

    println("Status | Count | Share")
    println("----------------------")
    println(f"Closed | $closed%5d | $pct")
    println(f"Open   | $open%5d | ${100 - closed.toDouble * 100.0 / total}%.1f%%")
    println(s"Total cases analyzed: $total")
  }
}

