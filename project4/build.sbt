<<<<<<< HEAD
name := "BaltimoreHomicideAnalysis"
version := "1.0"
scalaVersion := "2.13.12"
=======
ThisBuild / scalaVersion := "2.13.12"

name := "project4"
version := "0.1.0"

// No external libraries — pure Scala/Java only
scalacOptions ++= Seq(
  "-deprecation",
  "-feature",
  "-unchecked"
)

// So we can just run "sbt run" without typing the full class name
Compile / run / mainClass := Some("Main")

>>>>>>> 932780b (Final submission: Project 4 (Baltimore City Homicide Analysis with Docker & Scala))
