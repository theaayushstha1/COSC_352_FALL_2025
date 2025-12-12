name := "HomicideAnalysis"
version := "2.0"
scalaVersion := "2.13.6"

// Set main class for sbt run
Compile / mainClass := Some("HomicideAnalysis")

// No external dependencies - using only Scala standard library
libraryDependencies ++= Seq()
