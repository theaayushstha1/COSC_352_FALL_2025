name := "HomicideAnalysis"
version := "1.0"
scalaVersion := "2.13.6"

mainClass in Compile := Some("HomicideAnalysis")

// Add JSoup dependency for HTML parsing
libraryDependencies ++= Seq(
  "org.jsoup" % "jsoup" % "1.15.4"
)
