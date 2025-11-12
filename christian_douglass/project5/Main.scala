import org.jsoup.Jsoup
import scala.jdk.CollectionConverters._
import java.io._

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

  def writeCsv(entries: List[Homicide], path: String): Unit = {
    val pw = new PrintWriter(new File(path))
    try {
      // header
      pw.println("no,date,name,age,address,notes,criminalHistory,camera,caseClosed")
      entries.foreach { e =>
        val ageStr = e.age.map(_.toString).getOrElse("")
        // escape double quotes by doubling them and wrap fields that contain commas/quotes/newlines in quotes
        def esc(s: String) = {
          if (s == null) ""
          else if (s.contains(",") || s.contains("\"") || s.contains("\n")) {
            val inner = s.replace("\"", "\"\"")
            s"\"$inner\""
          } else s
        }
        val line = List(e.no, e.date, e.name, ageStr, e.address, e.notes, e.criminalHistory, e.camera, e.caseClosed).map(esc).mkString(",")
        pw.println(line)
      }
    } finally pw.close()
  }

  def writeJson(entries: List[Homicide], path: String): Unit = {
    val pw = new PrintWriter(new File(path))
    try {
      pw.println("[")
      entries.zipWithIndex.foreach { case (e, idx) =>
        def jq(s: String) = {
          if (s == null) "" else s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n")
        }
        val agePart = e.age.map(a => a.toString).getOrElse("null")
        val obj = s"  {\"no\": \"${jq(e.no)}\", \"date\": \"${jq(e.date)}\", \"name\": \"${jq(e.name)}\", \"age\": ${agePart}, \"address\": \"${jq(e.address)}\", \"notes\": \"${jq(e.notes)}\", \"criminalHistory\": \"${jq(e.criminalHistory)}\", \"camera\": \"${jq(e.camera)}\", \"caseClosed\": \"${jq(e.caseClosed)}\" }"
        val suf = if (idx == entries.size - 1) "" else ","
        pw.println(obj + suf)
      }
      pw.println("]")
    } finally pw.close()
  }

  def main(args: Array[String]): Unit = {
    // parse optional --output=csv or --output=json and optional --out-file=PATH (use '-' for stdout)
    val outputArg = args.find(_.startsWith("--output="))
    val outputMode = outputArg.map(_.substring("--output=".length)).getOrElse("stdout")
    val outFileArg = args.find(_.startsWith("--out-file="))
    val outFileOpt = outFileArg.map(_.substring("--out-file=".length))

    val doc = Jsoup.connect(url).userAgent("Mozilla/5.0").get()
    val rows = doc.select("#homicidelist tbody tr").asScala

    val entries = rows.flatMap { tr =>
      val tds = tr.select("td").asScala.map(_.text())
      if (tds.isEmpty) None
      else {
        // Skip header row which contains "No." or similar
        if (tds.exists(_.toLowerCase.contains("no.")) || tds.exists(_.toLowerCase.contains("date died"))) None
        else {
          // Some rows may have nested tables; using text() above gets readable content
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

    // If outputMode is csv or json, write the parsed entries to file (outFileOpt) or default file and exit
    def writeByMode(mode: String, entries: List[Homicide], outPathOpt: Option[String]): Unit = {
      val default = if (mode == "csv") "homicides_2025.csv" else "homicides_2025.json"
      outPathOpt match {
        case Some("-") =>
          // write to stdout
          if (mode == "csv") {
            println("no,date,name,age,address,notes,criminalHistory,camera,caseClosed")
            entries.foreach { e =>
              val ageStr = e.age.map(_.toString).getOrElse("")
              def esc(s: String) = {
                if (s == null) ""
                else if (s.contains(",") || s.contains("\"") || s.contains("\n")) {
                  val inner = s.replace("\"", "\"\"")
                  s"\"$inner\""
                } else s
              }
              val line = List(e.no, e.date, e.name, ageStr, e.address, e.notes, e.criminalHistory, e.camera, e.caseClosed).map(esc).mkString(",")
              println(line)
            }
          } else {
            print("[")
            entries.zipWithIndex.foreach { case (e, idx) =>
              def jq(s: String) = if (s == null) "" else s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n")
              val agePart = e.age.map(a => a.toString).getOrElse("null")
              val obj = s"{\"no\": \"${jq(e.no)}\", \"date\": \"${jq(e.date)}\", \"name\": \"${jq(e.name)}\", \"age\": ${agePart}, \"address\": \"${jq(e.address)}\", \"notes\": \"${jq(e.notes)}\", \"criminalHistory\": \"${jq(e.criminalHistory)}\", \"camera\": \"${jq(e.camera)}\", \"caseClosed\": \"${jq(e.caseClosed)}\" }"
              val suf = if (idx == entries.size - 1) "" else ","
              print(obj + suf)
            }
            println("]")
          }
        case Some(path) =>
          if (mode == "csv") writeCsv(entries, path) else writeJson(entries, path)
          println(s"Wrote ${entries.size} records to $path")
        case None =>
          val out = default
          if (mode == "csv") writeCsv(entries, out) else writeJson(entries, out)
          println(s"Wrote ${entries.size} records to $out")
      }
    }

    outputMode.toLowerCase match {
      case "csv" => writeByMode("csv", entries, outFileOpt); return
      case "json" => writeByMode("json", entries, outFileOpt); return
      case _ => // continue with existing stdout analysis
    }

    // Question 1: Top address blocks by homicide count (hotspots)
    println("Question 1: Top homicide hotspots (address block) in 2025")
    val byAddress = entries.groupBy(_.address).view.mapValues(_.size).toList.sortBy(-_._2)
    val top = byAddress.filter(_._1.nonEmpty).take(10)
    if (top.isEmpty) println("No data found for hotspots.")
    else {
      println("Address Block | Count")
      top.foreach { case (addr, cnt) => println(s"$addr | $cnt") }

      // show sample victims for each top address
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
