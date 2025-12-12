import java.io.{File, PrintWriter}
import scala.util.parsing.json.JSONObject

object p5Main {
  def main(args: Array[String]): Unit = {
    val outputFormat = if (args.nonEmpty) args(0).toLowerCase else "stdout"

    // Sample data — replace this with your actual data extraction logic
    val crimeData = List(
      Map("date" -> "2023-01-01", "type" -> "Burglary", "location" -> "Downtown"),
      Map("date" -> "2023-01-02", "type" -> "Assault", "location" -> "Uptown")
    )

    outputFormat match {
      case "csv"  => writeCSV(crimeData, "output.csv")
      case "json" => writeJSON(crimeData, "output.json")
      case _      => printStdout(crimeData)
    }
  }

  def writeCSV(data: List[Map[String, String]], filename: String): Unit = {
    val writer = new PrintWriter(new File(filename))
    val headers = data.head.keys.toList
    writer.println(headers.mkString(","))
    data.foreach { row =>
      writer.println(headers.map(h => row.getOrElse(h, "")).mkString(","))
    }
    writer.close()
  }

  def writeJSON(data: List[Map[String, String]], filename: String): Unit = {
    val writer = new PrintWriter(new File(filename))
    val jsonList = data.map(JSONObject(_).toString())
    writer.println("[" + jsonList.mkString(",") + "]")
    writer.close()
  }

  def printStdout(data: List[Map[String, String]]): Unit = {
    data.foreach { row =>
      println(row.map { case (k, v) => s"$k: $v" }.mkString(", "))
    }
  }
}
