(defproject baltimore-homicide-analysis "1.0.0"
  :description "Pure functional analysis of Baltimore homicide data"
  :dependencies [[org.clojure/clojure "1.11.1"]
                 [org.clojure/data.csv "1.0.1"]]
  :main baltimore-homicide-analysis.core
  :aot [baltimore-homicide-analysis.core]
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all}})
