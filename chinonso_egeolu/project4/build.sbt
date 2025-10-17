name := "BaltimoreHomicideAnalysis"

version := "1.0"

scalaVersion := "2.13.6"

// Scala file is at root level
Compile / scalaSource := baseDirectory.value

// No external dependencies - using only native Scala/Java libraries
libraryDependencies ++= Seq()