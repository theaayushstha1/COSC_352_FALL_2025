import org.jsoup.Jsoup
import org.jsoup.nodes.{Document, Element}
import scala.jdk.CollectionConverters._
import java.io.{PrintWriter, File}

object BaltimoreHomicideScraper {
  def main(args: Array[String]): Unit = {
    val doc: Document = Jsoup.connect("https://chamspage.blogspot.com/").get()
    
    val rows = doc.select("table tr").asScala.toList
    
    val writer = new PrintWriter(new File("csv/baltimore_cases.csv"))
    writer.println("Date,Victim,Age,Gender,Race,Cause,Location,Disposition")
    
    val homicides = rows.drop(1).flatMap { row =>
      val cells = row.select("td").asScala.map(_.text()).toList
      if (cells.length >= 8) {
        val data = Map(
          "date" -> cells(0),
          "victim" -> cells(1),
          "age" -> cells(2),
          "gender" -> cells(3),
          "race" -> cells(4),
          "cause" -> cells(5),
          "location" -> cells(6),
          "disposition" -> cells(7)
        )
        writer.println(s"${cells(0)},${cells(1)},${cells(2)},${cells(3)},${cells(4)},${cells(5)},${cells(6)},${cells(7)}")
        Some(data)
      } else None
    }
    
    writer.close()
    println(s"Scraped ${homicides.length} homicide records\n")
  }
}