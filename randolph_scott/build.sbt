name := "Project5"

version := "0.1"

scalaVersion := "2.13.14"

libraryDependencies ++= Seq(
  "io.circe" %% "circe-core" % "0.14.6",
  "io.circe" %% "circe-generic" % "0.14.6",
  "io.circe" %% "circe-parser" % "0.14.6",
  "com.github.tototoshi" %% "scala-csv" % "1.3.10" // CSV support
)



