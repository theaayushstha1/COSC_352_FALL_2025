(defproject baltimore-homicides "0.1.0"
  :description "Functional programming analysis of Baltimore homicides data"
  :license {:name "MIT License"
            :url "https://opensource.org/licenses/MIT"}
  :dependencies [[org.clojure/clojure "1.11.1"]]
  :main ^:skip-aot baltimore-homicides.core
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all
                       :jvm-opts ["-Dclojure.compiler.direct-linking=true"]}})