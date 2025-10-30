import scala.io.Source
import scala.util.Try
import java.io.{File, PrintWriter}

object Main {
  def main(args: Array[String]): Unit = {
    val outputFormat = args.find(_.startsWith("--output=")).map(_.split("=")(1)).getOrElse("stdout")
    val lines = Source.fromFile("data/homicides.csv").getLines().drop(1).toList
    val records = lines.map(parseLine).flatten
    val records2024 = records.filter(_.year == 2024)

    val collegeAged = records2024.filter(r => r.age >= 18 && r.age <= 23)
    val noHistory = records2024.filter(r => r.criminalHistory.equalsIgnoreCase("None"))

    outputFormat match {
      case "csv"  => writeCSV(collegeAged, noHistory)
      case "json" => writeJSON(collegeAged, noHistory)
      case _      => printStdout(collegeAged, noHistory, records2024.size)
    }
  }

  case class Homicide(year: Int, age: Int, criminalHistory: String)

  def parseLine(line: String): Option[Homicide] = {
    val cols = line.split(",").map(_.trim)
    if (cols.length < 3) return None
    Try {
      Homicide(cols(0).toInt, cols(1).toInt, cols(2))
    }.toOption
  }

  def printStdout(collegeAged: List[Homicide], noHistory: List[Homicide], total: Int): Unit = {
    println("Question 1: How many homicide victims in 2024 were college-aged (18–23)?")
    collegeAged.foreach(r => println(s"Year: ${r.year}, Age: ${r.age}, History: ${r.criminalHistory}"))
    val percent1 = (collegeAged.size.toDouble / total * 100).formatted("%.2f")
    println(s"Total: ${collegeAged.size}")
    println(s"Percentage of total: $percent1%")

    println("\nQuestion 2: How many homicide victims in 2024 had no prior violent criminal history?")
    noHistory.foreach(r => println(s"Year: ${r.year}, Age: ${r.age}, History: ${r.criminalHistory}"))
    val percent2 = (noHistory.size.toDouble / total * 100).formatted("%.2f")
    println(s"Total: ${noHistory.size}")
    println(s"Percentage of total: $percent2%")
  }

  def writeCSV(collegeAged: List[Homicide], noHistory: List[Homicide]): Unit = {
    val writer = new PrintWriter(new File("output.csv"))
    writer.println("Question,Year,Age,History")
    collegeAged.foreach(r => writer.println(s"College-aged,${r.year},${r.age},${r.criminalHistory}"))
    noHistory.foreach(r => writer.println(s"No criminal history,${r.year},${r.age},${r.criminalHistory}"))
    writer.close()
  }

  def writeJSON(collegeAged: List[Homicide], noHistory: List[Homicide]): Unit = {
    val allRecords = collegeAged.map(r => s"""{"question":"College-aged","year":${r.year},"age":${r.age},"history":"${r.criminalHistory}"}""") ++
                     noHistory.map(r => s"""{"question":"No criminal history","year":${r.year},"age":${r.age},"history":"${r.criminalHistory}"}""")
    val jsonArray = "[\n" + allRecords.mkString(",\n") + "\n]"
    val writer = new PrintWriter(new File("output.json"))
    writer.println(jsonArray)
    writer.close()
  }
}
