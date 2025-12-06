(defproject homicides-analysis "0.1.0-SNAPSHOT"
  :description "Functional analysis of Baltimore homicides dataset in Clojure"
  :url "https://github.com/professor-jon-white/COSC_352_FALL_2025"
  :license {:name "MIT"}
  :dependencies [[org.clojure/clojure "1.11.1"]
                 [org.clojure/data.csv "1.0.0"]]
  :main homicides-analysis.core
  :aot [homicides-analysis.core]
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all
                       :jvm-opts ["-Dclojure.compiler.direct-linking=true"]}})
