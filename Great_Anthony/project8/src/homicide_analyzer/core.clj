(ns homicide-analyzer.core
  (:require [clojure.data.csv :as csv]
            [clojure.java.io :as io]
            [clojure.string :as str])
  (:gen-class))

;; ============================================================================
;; Data Type Definition
;; ============================================================================

(defrecord Homicide [id date name age address weapon year])

;; ============================================================================
;; Pure Functional Utilities
;; ============================================================================

(defn parse-csv-line
  "Parse a single CSV line into a Homicide record"
  [[id date name age address weapon year]]
  (->Homicide id date name age address weapon year))

(defn load-homicides
  "Load and parse CSV file into homicide records"
  [filename]
  (with-open [reader (io/reader filename)]
    (let [lines (csv/read-csv reader)]
      (doall (map parse-csv-line (rest lines))))))

;; ============================================================================
;; Analysis 1: Homicides per Year/Month - Trend Analysis
;; ============================================================================

(defn extract-year-month
  "Extract year and month from a homicide record"
  [homicide]
  (let [date-parts (str/split (:date homicide) #"/")
        month (first date-parts)
        year (:year homicide)]
    (str year "-" month)))

(defn count-by-year-month
  "Count homicides grouped by year-month using functional constructs"
  [homicides]
  (->> homicides
       (map extract-year-month)
       frequencies
       (sort-by first)))

(defn format-trend-analysis
  "Format trend analysis results"
  [counts]
  (reduce (fn [acc [period count]]
            (str acc (format "%-10s : %d homicides\n" period count)))
          "\n=== Homicides by Year-Month ===\n"
          counts))

;; ============================================================================
;; Analysis 2: Weapon Type Distribution
;; ============================================================================

(defn extract-weapon
  "Extract weapon type from homicide record"
  [homicide]
  (let [weapon (:weapon homicide)]
    (if (or (nil? weapon) (empty? weapon))
      "Unknown"
      weapon)))

(defn count-by-weapon
  "Count homicides by weapon type using pure functions"
  [homicides]
  (->> homicides
       (map extract-weapon)
       frequencies
       (sort-by second >)))

(defn calculate-percentage
  "Calculate percentage given part and total"
  [part total]
  (* 100.0 (/ part total)))

(defn format-weapon-distribution
  "Format weapon distribution results with percentages"
  [weapon-counts total]
  (let [header "\n=== Weapon Type Distribution ===\n"]
    (reduce (fn [acc [weapon count]]
              (let [percentage (calculate-percentage count total)]
                (str acc (format "%-15s : %3d (%5.1f%%)\n" weapon count percentage))))
            header
            weapon-counts)))

;; ============================================================================
;; Statistical Summary
;; ============================================================================

(defn compute-total
  "Compute total number of homicides"
  [homicides]
  (count homicides))

(defn compute-unique-count
  "Compute count of unique values using given extractor function"
  [extractor homicides]
  (->> homicides
       (map extractor)
       set
       count))

(defn format-summary
  "Format overall statistical summary"
  [homicides]
  (let [total (compute-total homicides)
        unique-years (compute-unique-count :year homicides)
        unique-weapons (compute-unique-count extract-weapon homicides)]
    (format "\n=== Summary Statistics ===\nTotal Homicides: %d\nYears Covered: %d\nWeapon Types: %d\n"
            total unique-years unique-weapons)))

;; ============================================================================
;; Main Program
;; ============================================================================

(defn -main
  "Main entry point for the homicide analysis tool"
  [& args]
  (let [filename (or (first args) "baltimore_homicides_combined.csv")
        homicides (load-homicides filename)
        total (compute-total homicides)
        year-month-counts (count-by-year-month homicides)
        weapon-counts (count-by-weapon homicides)]
    
    ;; Print Summary
    (println (format-summary homicides))
    
    ;; Print Trend Analysis
    (println (format-trend-analysis year-month-counts))
    
    ;; Print Weapon Distribution
    (println (format-weapon-distribution weapon-counts total))
    
    (println "\n=== Analysis Complete ===")))
