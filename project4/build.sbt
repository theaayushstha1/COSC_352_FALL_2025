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

