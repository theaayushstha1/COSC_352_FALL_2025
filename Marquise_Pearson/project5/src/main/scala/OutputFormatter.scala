import java.nio.file.{Files, Paths}
import java.nio.charset.StandardCharsets

object OutputFormatter {
  sealed trait Format
  case object Stdout extends Format
  case object Csv extends Format
  case object Json extends Format

  final case class Config(format: Format, outDir: String = "output", baseName: String = "results")

  def write(records: Seq[Map[String, Any]], cfg: Config): Unit = {
    cfg.format match {
      case Stdout => printStdout(records)
      case Csv    => writeCsv(records, cfg)
      case Json   => writeJson(records, cfg)
    }
  }

  private def printStdout(records: Seq[Map[String, Any]]): Unit = {
    if (records.isEmpty) { println("No records."); return }
    val headers = headersFrom(records)
    val colWidths = headers.map(h =>
      math.max(h.length, records.map(r => r.getOrElse(h, "").toString.length).max)
    )
    def row(values: Seq[String]) =
      values.zip(colWidths).map { case (v, w) => v.padTo(w, ' ') }.mkString(" | ")

    println(row(headers))
    println(colWidths.map("-" * _).mkString("-+-"))
    records.foreach { r => println(row(headers.map(h => r.getOrElse(h, "").toString))) }
  }

  private def writeCsv(records: Seq[Map[String, Any]], cfg: Config): Unit = {
    ensureDir(cfg.outDir)
    val path = Paths.get(cfg.outDir, s"${cfg.baseName}.csv")
    if (records.isEmpty) { Files.write(path, Array.emptyByteArray); return }
    val headers = headersFrom(records)
    val sb = new StringBuilder
    sb.append(headers.mkString(",")).append("\n")
    records.foreach { r =>
      sb.append(headers.map(h => r.getOrElse(h, "").toString).mkString(",")).append("\n")
    }
    Files.write(path, sb.toString.getBytes(StandardCharsets.UTF_8))
    println(s"Wrote CSV: ${path}")
  }

  private def writeJson(records: Seq[Map[String, Any]], cfg: Config): Unit = {
    ensureDir(cfg.outDir)
    val path = Paths.get(cfg.outDir, s"${cfg.baseName}.json")
    val json = records.map { r =>
      r.map { case (k, v) => s""""$k": "${v.toString}"""" }.mkString("{", ", ", "}")
    }.mkString("[\n  ", ",\n  ", "\n]")
    Files.write(path, json.getBytes(StandardCharsets.UTF_8))
    println(s"Wrote JSON: ${path}")
  }

  private def headersFrom(records: Seq[Map[String, Any]]): Seq[String] =
    records.foldLeft(Seq.empty[String])((acc, m) => acc ++ m.keys.filterNot(acc.contains))

  private def ensureDir(dir: String): Unit = {
    val p = Paths.get(dir)
    if (!Files.exists(p)) Files.createDirectories(p)
  }
}
