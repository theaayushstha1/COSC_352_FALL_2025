(ns bmore-homicides.core
  (:require [clojure.data.csv :as csv]
            [clojure.java.io :as io]
            [clojure.string :as str]))

;; ------------------------------------------------------------
;; Helpers
;; ------------------------------------------------------------

(defn parse-int
  "Safely parse an integer from a string."
  [s]
  (when (and s (not (str/blank? s)))
    (try (Integer/parseInt (str/trim s))
         (catch Exception _ nil))))

(defn normalize-key
  "Normalize header names into dashed keywords.
   Example: \"Address Block Found\" -> :address-block-found"
  [s]
  (-> s
      str/lower-case
      str/trim
      (str/replace #"[^a-z0-9]+" "-")
      (str/replace #"^-+|-+$" "")
      keyword))

(defn row->map
  "Convert raw CSV row into a map with normalized keyword keys."
  [header row]
  (let [ks (map normalize-key header)]
    (zipmap ks row)))

;; ------------------------------------------------------------
;; Homicide record
;; ------------------------------------------------------------

(defrecord Homicide
  [incident-id
   date-died
   name
   age
   neighborhood
   notes
   year])

(defn ->homicide
  "Map a normalized row-map into a Homicide record.
   CSV headers include:
   :no, :date-died, :name, :age, :address-block-found, :notes, :year, :lat, :lon"
  [row-map]
  (->Homicide
   (:no row-map)
   (:date-died row-map)
   (:name row-map)
   (parse-int (:age row-map))
   (:address-block-found row-map)   ;; THIS WAS THE FIX ✔
   (:notes row-map)
   (parse-int (:year row-map))))

;; ------------------------------------------------------------
;; Load CSV
;; ------------------------------------------------------------

(defn load-homicides
  "Load CSV file and convert each row to a Homicide record."
  [path]
  (with-open [r (io/reader path)]
    (let [[header & rows] (csv/read-csv r)]
      (->> rows
           (map (partial row->map header))
           (map ->homicide)
           (remove nil?)
           doall))))

;; ------------------------------------------------------------
;; Analyses (PURE)
;; ------------------------------------------------------------

(defn homicides-per-year [homicides]
  (->> homicides
       (group-by :year)
       (map (fn [[y hs]] {:year y :count (count hs)}))
       (sort-by :year)))

(defn top-neighborhoods [homicides n]
  (->> homicides
       (filter #(some? (:neighborhood %)))
       (group-by :neighborhood)
       (map (fn [[loc hs]] {:neighborhood loc :count (count hs)}))
       (sort-by :count >)
       (take n)))

;; ------------------------------------------------------------
;; Printing helpers
;; ------------------------------------------------------------

(defn print-yearly [stats]
  (println "==== Homicides per Year ====")
  (doseq [{:keys [year count]} stats]
    (println (format "%4d : %d" year count))))

(defn print-top-locations [stats]
  (println)
  (println "==== Top Locations (Address Block Found) ====")
  (doseq [{:keys [neighborhood count]} stats]
    (println (format "%-40s %d" (or neighborhood "<missing>") count))))

;; ------------------------------------------------------------
;; Main (I/O only)
;; ------------------------------------------------------------

(defn -main [& args]
  (let [path (or (first args) "resources/baltimore_homicides_combined.csv")
        homicides (load-homicides path)
        yearly    (homicides-per-year homicides)
        toplocs   (top-neighborhoods homicides 5)]

    (println "Loaded" (count homicides) "records.")
    (println)
    (print-yearly yearly)
    (print-top-locations toplocs)
    (println)
    (println "Analysis complete.")))
