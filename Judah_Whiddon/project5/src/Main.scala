import java.net.http.{HttpClient, HttpRequest, HttpResponse}
import java.net.URI
import java.util.regex.Pattern
import scala.collection.mutable
import java.nio.file.{Files, Paths}
import java.nio.charset.StandardCharsets
import java.io.File

object Main {
  // Years to analyze
  val Years = Seq("2024", "2025")
  def urlFor(year: String): String =
    s"https://chamspage.blogspot.com/$year/01/$year-baltimore-city-homicide-list.html"

  // HTTP fetch
  def fetch(url: String): String = {
    val client = HttpClient.newHttpClient()
    val req = HttpRequest.newBuilder(URI.create(url)).GET().build()
    val res = client.send(req, HttpResponse.BodyHandlers.ofString())
    if (res.statusCode() != 200) throw new RuntimeException(s"HTTP ${res.statusCode()} fetching $url")
    res.body()
  }

  // Parsed row (we only need date + "Closed" tag for this project)
  final case class Row(dateStr: Option[String], closedTag: Option[String])

  // Parse blog text for entries: capture number + date; sniff for "Closed" nearby
  def parseRows(html: String): Seq[Row] = {
    val text = html
      .replaceAll("(?s)<script.*?</script>", "")
      .replaceAll("(?s)<style.*?</style>", "")
      .replaceAll("<[^>]+>", " ")
      .replaceAll("&nbsp;", " ")
      .replaceAll("\\s+", " ")
      .trim

    val entryRegex = Pattern.compile("(?:^|\\s)(\\d{1,3})\\s+(\\d{2}/\\d{2}/\\d{2})", Pattern.CASE_INSENSITIVE)
    val m = entryRegex.matcher(text)

    val rows = mutable.ArrayBuffer[Row]()
    while (m.find()) {
      val dateStr = m.group(2)
      val tailStart = m.end(2)
      val tailEnd = Math.min(tailStart + 250, text.length)
      val tail = text.substring(tailStart, tailEnd)
      val closed = if (tail.matches(".*\\bClosed\\b.*")) Some("Closed") else None
      rows += Row(Some(dateStr), closed)
    }
    rows.toSeq
  }

  // Month helpers
  def monthName(mm: String): String = mm match {
    case "01" => "January"; case "02" => "February"; case "03" => "March"
    case "04" => "April";   case "05" => "May";      case "06" => "June"
    case "07" => "July";    case "08" => "August";   case "09" => "September"
    case "10" => "October"; case "11" => "November"; case "12" => "December"
    case _    => "Unknown"
  }
  def emptyMonthCounts(): mutable.LinkedHashMap[String,Int] = mutable.LinkedHashMap(
    "January"->0,"February"->0,"March"->0,"April"->0,"May"->0,"June"->0,
    "July"->0,"August"->0,"September"->0,"October"->0,"November"->0,"December"->0
  )

  // Compute monthly counts for a given year
  def monthlyCountsFor(year: String): Seq[(String, Int)] = {
    val rows = parseRows(fetch(urlFor(year)))
    val monthCounts = emptyMonthCounts()
    rows.foreach(_.dateStr.foreach { ds =>
      val mm = ds.take(2)
      val mn = monthName(mm)
      if (monthCounts.contains(mn)) monthCounts.update(mn, monthCounts(mn) + 1)
    })
    monthCounts.toSeq.sortBy(-_._2)
  }

  // Compute closure stats for 2024
  final case class Closure(year: String, closed: Int, open: Int, total: Int) {
    def closedPct: Double = if (total > 0) (closed.toDouble * 100.0 / total) else 0.0
  }
  def closure2024(): Closure = {
    val year = "2024"
    val rows = parseRows(fetch(urlFor(year)))
    val closed = rows.count(_.closedTag.contains("Closed"))
    val total = rows.size
    Closure(year, closed, total - closed, total)
  }

  // ---- Output formatters ----

  // CSV (single file): rows for monthly per year + two rows for closure
  def toCSV(monthlyByYear: Map[String, Seq[(String,Int)]], closure: Closure): String = {
    val sb = new StringBuilder
    sb.append("section,year,field,value\n") // header
    monthlyByYear.foreach { case (year, seq) =>
      seq.filter(_._2 > 0).foreach { case (month, count) =>
        sb.append(s"monthly,$year,$month,$count\n")
      }
    }
    sb.append(s"closure,${closure.year},Closed,${closure.closed}\n")
    sb.append(s"closure,${closure.year},Open,${closure.open}\n")
    sb.toString()
  }

  // JSON (single object): {"monthlyByYear":{"2024":[{"month":"Jan","count":..},...],"2025":[...]},
  //                        "closure2024":{"closed":..,"open":..,"closedShare":..}}
  def toJSON(monthlyByYear: Map[String, Seq[(String,Int)]], closure: Closure): String = {
    def arrFor(seq: Seq[(String,Int)]): String =
      seq.filter(_._2 > 0).map{ case (m,c) => s"""{"month":"$m","count":$c}""" }.mkString("[",",","]")
    val monthlyJson = monthlyByYear.map{ case (y, seq) => s""""$y":${arrFor(seq)}""" }.mkString("{",",","}")
    val closedShare = if (closure.total>0) (closure.closed.toDouble/closure.total) else 0.0
    val closureJson = s"""{"year":"${closure.year}","closed":${closure.closed},"open":${closure.open},"closedShare":$closedShare}"""
    s"""{"monthlyByYear":$monthlyJson,"closure2024":$closureJson}"""
  }

  // Write helper -> prefers /out (mounted by run.sh), falls back to cwd
  def writeFile(name: String, content: String): File = {
    val mounted = new File("/out")
    val targetDir = if (mounted.exists() && mounted.isDirectory) mounted else new File(".")
    val path = Paths.get(targetDir.getPath, name)
    Files.write(path, content.getBytes(StandardCharsets.UTF_8))
    path.toFile
  }

  def main(args: Array[String]): Unit = {
    // Parse optional flag: --output=csv|json  (default: stdout)
    val fmt = args.find(_.startsWith("--output=")).map(_.substring("--output=".length)).getOrElse("stdout").toLowerCase

    // Build results
    val monthlyByYear: Map[String, Seq[(String,Int)]] =
      Years.map(y => y -> monthlyCountsFor(y)).toMap
    val closure = closure2024()

    fmt match {
      case "csv" =>
        val csv = toCSV(monthlyByYear, closure)
        val f = writeFile("project4_output.csv", csv)
        println(s"CSV written to ${f.getAbsolutePath}")

      case "json" =>
        val json = toJSON(monthlyByYear, closure)
        val f = writeFile("project4_output.json", json)
        println(s"JSON written to ${f.getAbsolutePath}")

      case _ => // stdout (pretty print)
        println("Question 1: Between 2024 and 2025, which months had the highest number of homicides?")
        Years.foreach { year =>
          val seq = monthlyByYear(year)
          val total = seq.map(_._2).sum
          println(s"\n$year:")
          println(f"${"Month"}%-12s | Count")
          println("----------------------")
          seq.foreach { case (m,c) => if (c > 0) println(f"$m%-12s | $c%5d") }
          println(s"Total homicides recorded: $total")
        }

        println(s"\nQuestion 2: In 2024, how many homicide cases are marked 'Closed' vs 'Open'?")
        val pct = if (closure.total>0) f"${closure.closedPct}%.1f%%" else "n/a"
        println(f"${"Status"}%-6s | ${"Count"}%-5s | Share")
        println("----------------------")
        println(f"Closed  | ${closure.closed}%5d | $pct")
        val openShare = if (closure.total>0) f"${100.0 - closure.closedPct}%.1f%%" else "n/a"
        println(f"Open    | ${closure.open}%5d | $openShare")
        println(s"Total cases analyzed: ${closure.total}")
    }
  }
}

