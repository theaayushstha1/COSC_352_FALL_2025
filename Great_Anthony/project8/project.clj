(defproject homicide-analyzer "1.0.0"
  :description "Baltimore Homicide Data Analysis Tool"
  :dependencies [[org.clojure/clojure "1.11.1"]
                 [org.clojure/data.csv "1.0.1"]]
  :main homicide-analyzer.core
  :aot [homicide-analyzer.core])
