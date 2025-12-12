import java.net.URL
import scala.io.Source
import scala.util.matching.Regex
import java.io.PrintWriter
import java.io.File

object Main {
  def main(args: Array[String]): Unit = {
    val outputFormat = if (args.length > 0) args(0).toLowerCase else "stdout"
    
    val url = "https://chamspage.blogspot.com/"
    println(s"Fetching data from: $url")

    val html = fetchUrl(url)

    val tableOpt = extractBestTable(html)
    if (tableOpt.isEmpty) {
      System.err.println("ERROR: Could not find a suitable table on the page.")
      System.exit(2)
    }

    val rows = parseTableRows(tableOpt.get)
    if (rows.isEmpty) {
      System.err.println("ERROR: No rows parsed from the table.")
      System.exit(2)
    }

    val header = rows.head
    val dataRows = rows.tail

    val weaponIdx = findColumnIndex(header, List("weapon", "method", "manner", "type", "cause"))
    val statusIdx = findColumnIndex(header, List("status", "case", "disposition", "investigation", "cleared"))

    var total = 0
    var stabbing = 0
    var shooting = 0
    var stabbingClosed = 0
    var shootingClosed = 0

    for (r <- dataRows) {
      total += 1
      val cells = r
      val weaponRaw = weaponIdx.flatMap(i => safeGet(cells, i)).getOrElse(cells.mkString(" ")).toLowerCase
      val statusRaw = statusIdx.flatMap(i => safeGet(cells, i)).getOrElse("unknown").toLowerCase

      val isStab = containsAny(weaponRaw, Seq("stab", "knife", "stabbing"))
      val isShoot = containsAny(weaponRaw, Seq("shoot", "shot", "gun", "firearm"))

      if (isStab) {
        stabbing += 1
        if (isClosed(statusRaw)) stabbingClosed += 1
      } else if (isShoot) {
        shooting += 1
        if (isClosed(statusRaw)) shootingClosed += 1
      }
    }

    val other = total - stabbing - shooting
    val violent = stabbing + shooting
    val closed = stabbingClosed + shootingClosed

    // Generate output based on format
    outputFormat match {
      case "csv" => outputCSV(total, stabbing, shooting, other, violent, closed, stabbingClosed, shootingClosed)
      case "json" => outputJSON(total, stabbing, shooting, other, violent, closed, stabbingClosed, shootingClosed)
      case _ => outputStdout(total, stabbing, shooting, other, violent, closed, stabbingClosed, shootingClosed)
    }
  }

  def outputStdout(total: Int, stabbing: Int, shooting: Int, other: Int, 
                   violent: Int, closed: Int, stabbingClosed: Int, shootingClosed: Int): Unit = {
    println("\nQuestion 1: What is the ratio of stabbing victims and shooting victims compared to the total?\n")
    println(f"Total victims: $total%d")
    if (total > 0) {
      println(f"Stabbing victims: $stabbing%d (${percentage(stabbing, total)}%.2f%%)")
      println(f"Shooting victims: $shooting%d (${percentage(shooting, total)}%.2f%%)")
      println(f"Other/Unclassified: $other%d (${percentage(other, total)}%.2f%%)")
    }

    println("\nQuestion 2: Of these victims (stabbing or shooting), what is the ratio of closed cases?\n")
    println(f"Total stabbing/shooting victims: $violent%d")
    if (violent > 0) {
      println(f"Closed cases total: $closed%d (${percentage(closed, violent)}%.2f%%)")
      println(f" - Closed stabbing: $stabbingClosed%d of $stabbing%d (${if (stabbing > 0) percentage(stabbingClosed, stabbing) else 0.0}%.2f%%)")
      println(f" - Closed shooting: $shootingClosed%d of $shooting%d (${if (shooting > 0) percentage(shootingClosed, shooting) else 0.0}%.2f%%)")
    } else {
      println("No stabbing or shooting victims detected.")
    }
  }

  def outputCSV(total: Int, stabbing: Int, shooting: Int, other: Int,
                violent: Int, closed: Int, stabbingClosed: Int, shootingClosed: Int): Unit = {
    val filename = "homicide_analysis.csv"
    val writer = new PrintWriter(new File(filename))
    
    try {
      // Write CSV header
      writer.println("category,subcategory,count,percentage,description")
      
      // Question 1 data
      writer.println(f"total_victims,all,$total%d,100.00,Total number of victims")
      writer.println(f"victim_type,stabbing,$stabbing%d,${percentage(stabbing, total)}%.2f,Victims of stabbing")
      writer.println(f"victim_type,shooting,$shooting%d,${percentage(shooting, total)}%.2f,Victims of shooting")
      writer.println(f"victim_type,other,$other%d,${percentage(other, total)}%.2f,Other/Unclassified victims")
      
      // Question 2 data
      writer.println(f"violent_crimes,total,$violent%d,100.00,Total stabbing and shooting victims")
      writer.println(f"case_status,closed,$closed%d,${percentage(closed, violent)}%.2f,Total closed cases (stabbing + shooting)")
      writer.println(f"case_status,open,${violent - closed}%d,${percentage(violent - closed, violent)}%.2f,Total open cases (stabbing + shooting)")
      writer.println(f"stabbing_status,closed,$stabbingClosed%d,${if (stabbing > 0) percentage(stabbingClosed, stabbing) else 0.0}%.2f,Closed stabbing cases")
      writer.println(f"stabbing_status,open,${stabbing - stabbingClosed}%d,${if (stabbing > 0) percentage(stabbing - stabbingClosed, stabbing) else 0.0}%.2f,Open stabbing cases")
      writer.println(f"shooting_status,closed,$shootingClosed%d,${if (shooting > 0) percentage(shootingClosed, shooting) else 0.0}%.2f,Closed shooting cases")
      writer.println(f"shooting_status,open,${shooting - shootingClosed}%d,${if (shooting > 0) percentage(shooting - shootingClosed, shooting) else 0.0}%.2f,Open shooting cases")
      
      println(s"CSV output written to: $filename")
    } finally {
      writer.close()
    }
  }

  def outputJSON(total: Int, stabbing: Int, shooting: Int, other: Int,
                 violent: Int, closed: Int, stabbingClosed: Int, shootingClosed: Int): Unit = {
    val filename = "homicide_analysis.json"
    val writer = new PrintWriter(new File(filename))
    
    try {
      writer.println("{")
      writer.println("  \"analysis_metadata\": {")
      writer.println("    \"source\": \"https://chamspage.blogspot.com/\",")
      writer.println(s"    \"total_victims_analyzed\": $total")
      writer.println("  },")
      writer.println("  \"question_1\": {")
      writer.println("    \"question\": \"What is the ratio of stabbing victims and shooting victims compared to the total?\",")
      writer.println("    \"total_victims\": {")
      writer.println(s"      \"count\": $total,")
      writer.println("      \"percentage\": 100.0")
      writer.println("    },")
      writer.println("    \"victim_breakdown\": {")
      writer.println("      \"stabbing\": {")
      writer.println(s"        \"count\": $stabbing,")
      writer.println(f"        \"percentage\": ${percentage(stabbing, total)}%.2f")
      writer.println("      },")
      writer.println("      \"shooting\": {")
      writer.println(s"        \"count\": $shooting,")
      writer.println(f"        \"percentage\": ${percentage(shooting, total)}%.2f")
      writer.println("      },")
      writer.println("      \"other\": {")
      writer.println(s"        \"count\": $other,")
      writer.println(f"        \"percentage\": ${percentage(other, total)}%.2f")
      writer.println("      }")
      writer.println("    }")
      writer.println("  },")
      writer.println("  \"question_2\": {")
      writer.println("    \"question\": \"Of these victims (stabbing or shooting), what is the ratio of closed cases?\",")
      writer.println("    \"violent_crimes_total\": {")
      writer.println(s"      \"count\": $violent,")
      writer.println("      \"percentage\": 100.0")
      writer.println("    },")
      writer.println("    \"case_status_summary\": {")
      writer.println("      \"closed\": {")
      writer.println(s"        \"count\": $closed,")
      writer.println(f"        \"percentage\": ${percentage(closed, violent)}%.2f")
      writer.println("      },")
      writer.println("      \"open\": {")
      writer.println(s"        \"count\": ${violent - closed},")
      writer.println(f"        \"percentage\": ${percentage(violent - closed, violent)}%.2f")
      writer.println("      }")
      writer.println("    },")
      writer.println("    \"detailed_breakdown\": {")
      writer.println("      \"stabbing\": {")
      writer.println(s"        \"total\": $stabbing,")
      writer.println(s"        \"closed\": $stabbingClosed,")
      writer.println(s"        \"open\": ${stabbing - stabbingClosed},")
      writer.println(f"        \"closed_percentage\": ${if (stabbing > 0) percentage(stabbingClosed, stabbing) else 0.0}%.2f")
      writer.println("      },")
      writer.println("      \"shooting\": {")
      writer.println(s"        \"total\": $shooting,")
      writer.println(s"        \"closed\": $shootingClosed,")
      writer.println(s"        \"open\": ${shooting - shootingClosed},")
      writer.println(f"        \"closed_percentage\": ${if (shooting > 0) percentage(shootingClosed, shooting) else 0.0}%.2f")
      writer.println("      }")
      writer.println("    }")
      writer.println("  }")
      writer.println("}")
      
      println(s"JSON output written to: $filename")
    } finally {
      writer.close()
    }
  }

  def fetchUrl(url: String): String = {
    val conn = new URL(url).openConnection()
    conn.setRequestProperty("User-Agent", "ScalaHomicideParser/1.0")
    val src = Source.fromInputStream(conn.getInputStream)(scala.io.Codec.UTF8)
    try src.mkString finally src.close()
  }

  def extractBestTable(html: String): Option[String] = {
    val tableRegex = new Regex("(?s)<table.*?>.*?</table>", "table")
    val candidates = tableRegex.findAllIn(html).toList
    if (candidates.isEmpty) None
    else Some(candidates.maxBy(_.length))
  }

  def parseTableRows(tableHtml: String): List[List[String]] = {
    val rowRegex = new Regex("(?s)<tr.*?>.*?</tr>")
    val cellRegex = new Regex("(?s)<t[dh].*?>(.*?)</t[dh]>", "cell")

    rowRegex.findAllIn(tableHtml).toList.map { rowHtml =>
      cellRegex.findAllMatchIn(rowHtml).map(m => stripTags(m.group(1)).trim).toList
    }.filter(_.nonEmpty)
  }

  def stripTags(s: String): String = s.replaceAll("(?s)<.*?>", "").replaceAll("&nbsp;", " ")

  def findColumnIndex(header: List[String], candidates: List[String]): Option[Int] = {
    val lower = header.map(_.toLowerCase)
    lower.zipWithIndex.find { case (h, _) => candidates.exists(c => h.contains(c)) }.map(_._2)
  }

  def safeGet(lst: List[String], idx: Int): Option[String] =
    if (idx >= 0 && idx < lst.length) Some(lst(idx)) else None

  def containsAny(s: String, patterns: Seq[String]): Boolean =
    patterns.exists(p => s.contains(p))

  def isClosed(status: String): Boolean =
    containsAny(status, Seq("closed", "cleared", "solved", "arrest", "charge"))

  def percentage(part: Int, total: Int): Double =
    if (total == 0) 0.0 else (part.toDouble / total.toDouble) * 100.0
}