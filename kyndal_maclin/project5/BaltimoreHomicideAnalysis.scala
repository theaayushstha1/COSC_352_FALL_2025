//> using scala "3.3.1"
//> using dep "org.jsoup:jsoup:1.21.2"
//> using dep "com.lihaoyi:ujson_3:4.4.0"

import org.jsoup._
import org.jsoup.nodes._
import scala.jdk.CollectionConverters._
import scala.util.{Try, Success, Failure}
import java.io.{File, PrintWriter}

case class Incident(
  name: String,
  age: String,
  gender: String,
  race: String,
  date: String,
  cause: String,
  weapon: String,
  district: String,
  location: String
)

object BaltimoreHomicideAnalysis:

  /** Fetch homicide data from the blog for a given year */
  def fetchYear(year: Int): List[Incident] =
    // ✅ Use correct URLs for each year
    val url = year match
      case 2025 => "https://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
      case 2024 => "https://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html"
      case 2023 => "https://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html"
      case 2022 => "https://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html"
      case 2021 => "https://chamspage.blogspot.com/2021/01/2021-baltimore-city-homicides-list.html"
      case 2020 => "https://chamspage.blogspot.com/2020/01/2020-baltimore-city-homicides-list.html"
      case _    => s"https://chamspage.blogspot.com/$year/"
    
    println(s"🔎 Fetching: $url")

    Try(Jsoup.connect(url).timeout(10000).get()) match
      case Failure(ex) =>
        println(s"⚠️ Failed to fetch data for $year: ${ex.getMessage}")
        Nil
      case Success(doc) =>
        val rows = doc.select("table tr").asScala.toList
        rows.drop(1).flatMap { row =>
          val cols = row.select("td").asScala.map(_.text()).toList
          if cols.length >= 9 then
            Some(Incident(
              cols(0), cols(1), cols(2), cols(3),
              cols(4), cols(5), cols(6), cols(7), cols(8)
            ))
          else None
        }

  /** Compute summary statistics */
  def analyze(incidents: List[Incident]): Map[String, Any] =
    val total = incidents.size
    val byGender = incidents.groupBy(_.gender).map { case (k, v) => k -> v.size }.toMap
    val byRace = incidents.groupBy(_.race).map { case (k, v) => k -> v.size }.toMap
    val byDistrict = incidents.groupBy(_.district).map { case (k, v) => k -> v.size }.toMap

    Map(
      "total" -> total,
      "byGender" -> byGender,
      "byRace" -> byRace,
      "byDistrict" -> byDistrict
    )

  /** Recursively convert Scala maps and primitives to ujson.Value */
  private def toUjson(value: Any): ujson.Value = value match
    case m: Map[?, ?] =>
      ujson.Obj.from(m.asInstanceOf[Map[String, Any]].view.mapValues(toUjson).toMap)
    case i: Int => ujson.Num(i)
    case s: String => ujson.Str(s)
    case other => ujson.Str(other.toString)

  /** Save summary statistics as JSON */
  def writeJson(results: Map[String, Any], filename: String): Unit =
    val json = toUjson(results)
    val pretty = ujson.write(json, indent = 2)
    val out = new PrintWriter(new File(filename))
    out.write(pretty)
    out.close()
    println(s"💾 JSON saved as $filename")

  /** Save all incidents as CSV */
  def writeCsv(incidents: List[Incident], filename: String): Unit =
    val pw = new PrintWriter(new File(filename))
    pw.println("Name,Age,Gender,Race,Date,Cause,Weapon,District,Location")
    incidents.foreach { i =>
      pw.println(s"${i.name},${i.age},${i.gender},${i.race},${i.date},${i.cause},${i.weapon},${i.district},${i.location}")
    }
    pw.close()
    println(s"💾 CSV saved as $filename")

  /** Entry point */
  @main def main(args: String*): Unit =
    println("🕵️ Baltimore Homicide Analysis Started")

    val years = List(2025, 2024, 2023)
    val all = years.flatMap(fetchYear)

    if all.isEmpty then
      println("❌ No incidents fetched. Exiting.")
      return

    val stats = analyze(all)

    if args.contains("--output=json") then
      writeJson(stats, "baltimore_output.json")
    else if args.contains("--output=csv") then
      writeCsv(all, "baltimore_output.csv")
    else
      println(s"📊 Total incidents: ${stats("total")}")
      println("By Gender:")
      stats("byGender").asInstanceOf[Map[String, Int]].foreach((k, v) => println(f"  $k%-10s -> $v"))
      println("By Race:")
      stats("byRace").asInstanceOf[Map[String, Int]].foreach((k, v) => println(f"  $k%-10s -> $v"))
      println("By District:")
      stats("byDistrict").asInstanceOf[Map[String, Int]].foreach((k, v) => println(f"  $k%-10s -> $v"))

    println("✅ Analysis complete.")

