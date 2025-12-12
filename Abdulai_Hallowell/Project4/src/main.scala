import scala.io.Source

object BaltimoreHomicide {
  def main(args: Array[String]): Unit = {
    val filename = "data.csv"
    val lines = Source.fromFile(filename).getLines().toList.drop(1)
    val data = lines.map(_.split(",").map(_.trim)).filter(_.length > 5)

    // Question 1
    val nearHome = data.count(row =>
      row(5).toLowerCase.contains("home") || row(5).toLowerCase.contains("residence")
    )
    println("Question 1: How many homicide victims in 2025 were killed at or near their home?")
    println(s"Answer: $nearHome cases\n")

    // Question 2
    val youthVictims = data.count(row => {
      val age = row(3).toIntOption.getOrElse(0)
      age < 25
    })
    val total = data.size
    val percentUnder25 = if (total > 0) (youthVictims.toDouble / total) * 100 else 0.0
    println("Question 2: What percentage of 2025 homicide victims were under 25 years old?")
    println(f"Answer: $percentUnder25%.2f%%")
  }
}

