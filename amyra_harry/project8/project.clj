(defproject baltimore-homicides "0.1.0"
  :description "Functional analysis of Baltimore homicides data"
  :dependencies [[org.clojure/clojure "1.11.1"]]
  :main baltimore-homicides.core
  :aot [baltimore-homicides.core]
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all
                       :jvm-opts ["-Dclojure.compiler.direct-linking=true"]}})