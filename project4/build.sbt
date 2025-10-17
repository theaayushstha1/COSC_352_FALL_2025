ThisBuild / scalaVersion := "2.13.12"

name := "baltimore-homicide-insights"

libraryDependencies += "org.jsoup" % "jsoup" % "1.18.3"

enablePlugins(AssemblyPlugin)
ThisBuild / assembly / mainClass := Some("Main")
