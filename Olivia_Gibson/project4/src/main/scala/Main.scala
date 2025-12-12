import scala.io.Source
import scala.util.Try

object Main {
  def main(args: Array[String]): Unit = {
    val lines = Source.fromFile("data/homicides.csv").getLines().drop(1).toList
    val records = lines.map(parseLine).flatten
    val records2024 = records.filter(_.year == 2024)

    println("Question 1: How many homicide victims in 2024 were college-aged (18–23), and what percentage of total victims do they represent?")
    answerCollegeAged(records2024)

    println("\nQuestion 2: How many homicide victims in 2024 had no prior violent criminal history and what percentage of total victims do they represent?")
    answerNoCriminalHistory(records2024)
  }

  case class Homicide(year: Int, age: Int, criminalHistory: String)

  def parseLine(line: String): Option[Homicide] = {
    val cols = line.split(",").map(_.trim)
    if (cols.length < 3) return None
    Try {
      Homicide(
        year = cols(0).toInt,
        age = cols(1).toInt,
        criminalHistory = cols(2)
      )
    }.toOption
  }

  def answerCollegeAged(records: List[Homicide]): Unit = {
    val collegeAged = records.filter(r => r.age >= 18 && r.age <= 23)
    collegeAged.foreach(r => println(s"Year: ${r.year}, Age: ${r.age}, History: ${r.criminalHistory}"))
    val percent = if (records.nonEmpty) (collegeAged.size.toDouble / records.size * 100).formatted("%.2f") else "0.00"
    println(s"Total: ${collegeAged.size}")
    println(s"Percentage of total: $percent%")
  }

  def answerNoCriminalHistory(records: List[Homicide]): Unit = {
    val noHistory = records.filter(r => r.criminalHistory.equalsIgnoreCase("None"))
    noHistory.foreach(r => println(s"Year: ${r.year}, Age: ${r.age}, History: ${r.criminalHistory}"))
    val percent = if (records.nonEmpty) (noHistory.size.toDouble / records.size * 100).formatted("%.2f") else "0.00"
    println(s"Total: ${noHistory.size}")
    println(s"Percentage of total: $percent%")
  }
}
