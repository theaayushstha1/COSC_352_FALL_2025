import java.net.URL
import scala.io.Source
import scala.util.matching.Regex

object Main {
  def main(args: Array[String]): Unit = {
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

    println("\nQuestion 1: What is the ratio of stabbing victims and shooting victims compared to the total?\n")
    println(f"Total victims: $total%d")
    if (total > 0) {
      println(f"Stabbing victims: $stabbing%d (${percentage(stabbing, total)}%.2f%%)")
      println(f"Shooting victims: $shooting%d (${percentage(shooting, total)}%.2f%%)")
      val other = total - stabbing - shooting
      println(f"Other/Unclassified: $other%d (${percentage(other, total)}%.2f%%)")
    }

    val violent = stabbing + shooting
    println("\nQuestion 2: Of these victims (stabbing or shooting), what is the ratio of closed cases?\n")
    println(f"Total stabbing/shooting victims: $violent%d")
    if (violent > 0) {
      val closed = stabbingClosed + shootingClosed
      println(f"Closed cases total: $closed%d (${percentage(closed, violent)}%.2f%%)")
      println(f" - Closed stabbing: $stabbingClosed%d of $stabbing%d (${if (stabbing > 0) percentage(stabbingClosed, stabbing) else 0.0}%.2f%%)")
      println(f" - Closed shooting: $shootingClosed%d of $shooting%d (${if (shooting > 0) percentage(shootingClosed, shooting) else 0.0}%.2f%%)")
    } else {
      println("No stabbing or shooting victims detected.")
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
