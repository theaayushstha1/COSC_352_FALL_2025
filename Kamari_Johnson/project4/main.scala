import scala.io.Source

object Main {
  def main(args: Array[String]): Unit = {
    val filePath = "data/baltimore_homicides.csv"

    // Attempt to read the file
    val lines = try {
      Source.fromFile(filePath).getLines().drop(1).toList
    } catch {
      case e: Exception =>
        println(s"Error reading file: $e")
        return
    }

    val records = lines.map(_.split(",").map(_.trim))

    // Question 1: How many victims were above the age of 18?
    val over18Count = records.count { r =>
      r.length > 2 && r(2).nonEmpty && r(2).forall(_.isDigit) && r(2).toInt > 18
    }

    println("Question 1: How many homicide victims in Baltimore were over the age of 18?")
    println(s"Answer: $over18Count victims\n")

    // Question 2: How many of these crimes were shootings?
    val shootingCount = records.count { r =>
      r.length > 5 && r(5).toLowerCase.contains("gun")
    }

    println("Question 2: How many of these homicides were committed using firearms?")
    println(s"Answer: $shootingCount cases")
  }
}