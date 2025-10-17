import org.jsoup.Jsoup
import scala.jdk.CollectionConverters._

case class Homicide(no: String, date: String, name: String, age: Option[Int], address: String, notes: String, criminalHistory: String, camera: String, caseClosed: String)

object Main {
  val url = "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"

  def parseAge(s: String): Option[Int] = {
    val trimmed = s.trim
    if (trimmed.isEmpty) None
    else {
      try Some(trimmed.toInt)
      catch { case _: Throwable => None }
    }
  }

  def main(args: Array[String]): Unit = {
    val doc = Jsoup.connect(url).userAgent("Mozilla/5.0").get()
    val rows = doc.select("#homicidelist tbody tr").asScala

    val entries = rows.flatMap { tr =>
      val tds = tr.select("td").asScala.map(_.text())
      if (tds.isEmpty) None
      else {
        // Skip header row which contains "No." or similar
        if (tds.exists(_.toLowerCase.contains("no.")) || tds.exists(_.toLowerCase.contains("date died"))) None
        else {
          val no = if (tds.isDefinedAt(0)) tds(0).trim else ""
          val date = if (tds.isDefinedAt(1)) tds(1).trim else ""
          val name = if (tds.isDefinedAt(2)) tds(2).trim else ""
          val age = if (tds.isDefinedAt(3)) parseAge(tds(3)) else None
          val address = if (tds.isDefinedAt(4)) tds(4).trim else ""
          val notes = if (tds.isDefinedAt(5)) tds(5).trim else ""
          val criminalHistory = if (tds.isDefinedAt(6)) tds(6).trim else ""
          val camera = if (tds.isDefinedAt(7)) tds(7).trim else ""
          val caseClosed = if (tds.isDefinedAt(8)) tds(8).trim else ""
          Some(Homicide(no, date, name, age, address, notes, criminalHistory, camera, caseClosed))
        }
      }
    }.toList

    // Question 1: Top address blocks by homicide count (hotspots)
    println("Question 1: Top homicide hotspots (address block) in 2025")
    val byAddress = entries.groupBy(_.address).view.mapValues(_.size).toList.sortBy(-_._2)
    val top = byAddress.filter(_._1.nonEmpty).take(10)
    if (top.isEmpty) println("No data found for hotspots.")
    else {
      println("Address Block | Count")
      top.foreach { case (addr, cnt) => println(s"$addr | $cnt") }

      println()
      top.foreach { case (addr, _) =>
        println(s"Victims at $addr:")
        entries.filter(_.address == addr).take(5).foreach { e =>
          val ageStr = e.age.map(_.toString).getOrElse("")
          println(s"${e.no} | ${e.date} | ${e.name} | ${ageStr}")
        }
        println()
      }
    }

    // Question 2: Are homicides with surveillance cameras more likely to be closed?
    println("Question 2: Do homicides with surveillance cameras have higher closure rates?")
    val withCamera = entries.filter(e => e.camera.nonEmpty)
    val withoutCamera = entries.filter(e => e.camera.isEmpty)

    def closedRate(list: List[Homicide]): (Int, Int, Double) = {
      val total = list.size
      val closed = list.count(e => e.caseClosed.equalsIgnoreCase("Closed") || e.caseClosed.toLowerCase.contains("closed"))
      val pct = if (total == 0) 0.0 else (closed.toDouble / total.toDouble) * 100.0
      (closed, total, pct)
    }

    val (c1, t1, p1) = closedRate(withCamera)
    val (c2, t2, p2) = closedRate(withoutCamera)

    println(f"With camera: $c1/$t1 closed (${p1}%.1f%%)")
    println(f"Without camera: $c2/$t2 closed (${p2}%.1f%%)")

    println()
    println("Examples of camera cases that remain open (if any):")
    withCamera.filterNot(e => e.caseClosed.equalsIgnoreCase("Closed")).take(10).foreach { e =>
      println(s"${e.no} | ${e.date} | ${e.name} | ${e.address} | camera:${e.camera} | caseClosed:'${e.caseClosed}'")
    }

  }
}
