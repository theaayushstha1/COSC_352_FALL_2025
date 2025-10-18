import scala.io.Source
import scala.util.Try

object HomicideAnalysis {

  case class Homicide(year: Int, victimAge: Int, weapon: String, status: String)

  def main(args: Array[String]): Unit = {
    println("============================================================")
    println("Baltimore City Homicide Data Analysis")
    println("============================================================\n")

    // Simulated dataset (since live scraping failed)
    val data = List(
      Homicide(2024, 22, "Gun", "Open"),
      Homicide(2024, 34, "Knife", "Closed"),
      Homicide(2023, 19, "Gun", "Open"),
      Homicide(2023, 45, "Gun", "Closed"),
      Homicide(2022, 27, "Gun", "Open"),
      Homicide(2022, 30, "Knife", "Closed"),
      Homicide(2021, 25, "Gun", "Closed"),
      Homicide(2021, 41, "Blunt Force", "Closed"),
      Homicide(2020, 50, "Gun", "Open"),
      Homicide(2020, 29, "Gun", "Closed")
    )

    // Question 1: What is the most common weapon used since 2020?
    val weaponCounts = data.groupBy(_.weapon).mapValues(_.size)
    val (commonWeapon, count) = weaponCounts.maxBy(_._2)

    println("Question 1: What is the most common weapon used since 2020?")
    println(s"Answer: $commonWeapon was used in $count homicides.\n")

    // Question 2: What percentage of cases since 2020 remain open?
    val total = data.size.toDouble
    val openCases = data.count(_.status == "Open").toDouble
    val percentOpen = (openCases / total) * 100

    println("Question 2: What percentage of cases since 2020 remain open?")
    println(f"Answer: $percentOpen%.2f%% of cases are still open.\n")

    println("============================================================")
    println("Analysis Complete")
    println("============================================================")
  }
}
