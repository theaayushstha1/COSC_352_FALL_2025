(require '[clojure.java.io :as io])
(require '[clojure.string :as str])

(defn parse-int [s]
  (try (Integer/parseInt s) (catch Exception _ nil)))

(defn parse-row [line]
  (let [cols (str/split line #",")]
    {:year (parse-int (nth cols 10))
     :location (nth cols 4)}))

(defn load-data [file]
  (->> (io/reader file)
       line-seq
       rest
       (map parse-row)
       (filter :year)))

(defn homicides-per-year [rows]
  (->> rows
       (group-by :year)
       (map (fn [[y rs]] [y (count rs)]))
       (sort-by first)))

(defn top-locations [n rows]
  (->> rows
       (group-by :location)
       (map (fn [[loc rs]] [loc (count rs)]))
       (sort-by (comp - second))
       (take n)))

(defn -main [& args]
  (let [file (first args)
        rows (load-data file)]
    (println "=== Homicides per year ===")
    (doseq [[y c] (homicides-per-year rows)]
      (println y ":" c))
    (println)
    (println "=== Top 10 Locations ===")
    (doseq [[loc c] (top-locations 10 rows)]
      (println loc ":" c))))

(apply -main *command-line-args*)
