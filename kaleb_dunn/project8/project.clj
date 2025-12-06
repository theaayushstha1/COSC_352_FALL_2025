(defproject baltimore-homicide-analysis "0.1.0"
  :description "Functional analysis of Baltimore homicide data"
  :dependencies [[org.clojure/clojure "1.11.1"]
                 [org.clojure/data.csv "1.0.1"]]
  :main baltimore-homicide-analysis.core
  :aot [baltimore-homicide-analysis.core])
