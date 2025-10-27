ThisBuild / scalaVersion := "2.13.12"

name := "baltimore-homicide-insights-project5"

libraryDependencies += "org.jsoup" % "jsoup" % "1.15.4"

// Assembly plugin not required but left out to keep Docker build simple; sbt run is used
