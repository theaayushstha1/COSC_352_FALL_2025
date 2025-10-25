import scala.io.Source
import java.io.{File, PrintWriter}

object BaltimoreHomicide {
  def main(args: Array[String]): Unit = {
    val outputType = sys.env.getOrElse("OUTPUT", "stdout").toLowerCase
    println(s"DEBUG OUTPUT=${sys.env.getOrElse("OUTPUT","<unset>")}")
    println(s"DEBUG CHOSEN=$outputType")

    val lines = Source.fromFile("data.csv").getLines().toList.drop(1)
    val data  = lines.map(_.split(",").map(_.trim)).filter(_.length > 5)

    val nearHome = data.count(r => r(5).toLowerCase.contains("home") || r(5).toLowerCase.contains("residence"))
    val q1 = "Question 1: How many homicide victims in 2025 were killed at or near their home?"
    val a1 = s"Answer: $nearHome cases"

    val youth = data.count(r => r(3).toIntOption.exists(_ < 25))
    val total = data.size
    val pct   = if (total > 0) (youth.toDouble / total) * 100 else 0.0
    val q2 = "Question 2: What percentage of 2025 homicide victims were under 25 years old?"
    val a2 = f"Answer: $pct%.2f%%"

    val stdout = s"$q1\n$a1\n\n$q2\n$a2\n"
    val csv    = s"Question,Answer\n\"$q1\",\"$a1\"\n\"$q2\",\"$a2\"\n"
    val json   =
      s"""{ "results": [
        { "question": "$q1", "answer": "$a1" },
        { "question": "$q2", "answer": "$a2" }
      ] }"""

    outputType match {
      case "csv"  => val pw = new PrintWriter(new File("/app/output.csv"));  pw.write(csv);  pw.close();  println("✅ Results written to output.csv")
      case "json" => val pw = new PrintWriter(new File("/app/output.json")); pw.write(json); pw.close(); println("✅ Results written to output.json")
      case _      => println(stdout)
    }
  }
}
