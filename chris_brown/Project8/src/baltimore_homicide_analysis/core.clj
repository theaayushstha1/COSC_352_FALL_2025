(ns baltimore-homicide-analysis.core
  "Pure functional analysis of Baltimore homicide data"
  (:require [clojure.data.csv :as csv]
            [clojure.java.io :as io]
            [clojure.string :as str])
  (:gen-class))

;; ============================================================================
;; Type Definitions & Data Structures
;; ============================================================================

(defrecord Homicide
  [date district neighborhood age gender race cause disposition year month])

;; ============================================================================
;; Pure Functional Core - Data Parsing
;; ============================================================================

(defn parse-int
  "Safely parse string to integer, returns nil on failure"
  [s]
  (when (and s (not (str/blank? s)))
    (try
      (Integer/parseInt (str/trim s))
      (catch Exception _ nil))))

(defn parse-date-components
  "Extract year and month from date string (expected format: YYYY-MM-DD or MM/DD/YYYY)"
  [date-str]
  (when (and date-str (not (str/blank? date-str)))
    (let [date-str (str/trim date-str)]
      (cond
        ;; YYYY-MM-DD format
        (re-matches #"\d{4}-\d{2}-\d{2}" date-str)
        (let [[year month] (str/split date-str #"-")]
          {:year (parse-int year) :month (parse-int month)})
        
        ;; MM/DD/YYYY format
        (re-matches #"\d{1,2}/\d{1,2}/\d{4}" date-str)
        (let [[month _ year] (str/split date-str #"/")]
          {:year (parse-int year) :month (parse-int month)})
        
        ;; Default
        :else nil))))

(defn csv-row->homicide
  "Transform a CSV row into a Homicide record (pure function)"
  [row]
  (let [date-str (nth row 0 "")
        district (nth row 1 "")
        neighborhood (nth row 2 "")
        age-str (nth row 3 "")
        gender (nth row 4 "")
        race (nth row 5 "")
        cause (nth row 6 "")
        disposition (nth row 7 "")
        date-parts (parse-date-components date-str)]
    (map->Homicide
     {:date date-str
      :district district
      :neighborhood neighborhood
      :age (parse-int age-str)
      :gender gender
      :race race
      :cause cause
      :disposition disposition
      :year (:year date-parts)
      :month (:month date-parts)})))

(defn parse-csv-data
  "Parse CSV string into sequence of Homicide records (pure function)"
  [csv-string]
  (->> csv-string
       csv/read-csv
       rest  ; skip header
       (map csv-row->homicide)
       (filter #(and (:year %) (:district %)))))  ; filter invalid records

;; ============================================================================
;; Pure Functional Core - Analysis Functions
;; ============================================================================

;; Analysis 1: Temporal Trends - Homicides per Year and Month
;; ---------------------------------------------------------------

(defn count-by
  "Generic counting function using group-by and frequencies (pure)"
  [key-fn coll]
  (->> coll
       (map key-fn)
       frequencies
       (sort-by first)))

(defn homicides-by-year
  "Count homicides per year (pure function)"
  [homicides]
  (count-by :year homicides))

(defn homicides-by-month
  "Count homicides per month across all years (pure function)"
  [homicides]
  (count-by :month homicides))

(defn calculate-year-over-year-change
  "Calculate year-over-year percentage change (pure function)"
  [yearly-counts]
  (let [years (sort (keys yearly-counts))]
    (->> years
         (partition 2 1)
         (map (fn [[y1 y2]]
                (let [c1 (get yearly-counts y1)
                      c2 (get yearly-counts y2)
                      change (- c2 c1)
                      pct-change (if (zero? c1) 0.0
                                     (* 100.0 (/ change c1)))]
                  {:year y2
                   :count c2
                   :change change
                   :percent-change (format "%.1f%%" pct-change)}))))))

;; Analysis 2: Neighborhood Hot Spots - Top N Neighborhoods
;; ---------------------------------------------------------------

(defn top-n-by
  "Get top N items by frequency of a key function (pure function)"
  [n key-fn coll]
  (->> coll
       (map key-fn)
       frequencies
       (sort-by second >)
       (take n)))

(defn top-neighborhoods
  "Get top N neighborhoods by homicide count (pure function)"
  [n homicides]
  (top-n-by n :neighborhood homicides))

(defn neighborhood-statistics
  "Calculate detailed statistics for each neighborhood (pure function)"
  [homicides]
  (->> homicides
       (group-by :neighborhood)
       (map (fn [[neighborhood cases]]
              (let [total (count cases)
                    closed (count (filter #(str/includes? 
                                           (str/lower-case (:disposition %)) 
                                           "closed")
                                          cases))
                    clearance-rate (if (zero? total) 0.0
                                      (* 100.0 (/ closed total)))
                    avg-age (->> cases
                                 (map :age)
                                 (filter some?)
                                 (#(if (empty? %) 0
                                      (/ (reduce + %) (count %)))))]
                {:neighborhood neighborhood
                 :total total
                 :closed closed
                 :clearance-rate clearance-rate
                 :avg-age (format "%.1f" avg-age)})))
       (sort-by :total >)))

;; Additional Analysis: Weapon Distribution
;; ---------------------------------------------------------------

(defn weapon-distribution
  "Analyze distribution of weapons/causes (pure function)"
  [homicides]
  (->> homicides
       (map :cause)
       frequencies
       (sort-by second >)))

;; ============================================================================
;; Pure Functional Composition - Report Generation
;; ============================================================================

(defn format-temporal-analysis
  "Format temporal analysis results (pure function)"
  [yearly yoy-changes monthly]
  (str "\n"
       "=============================================================================\n"
       "ANALYSIS 1: TEMPORAL TRENDS - HOMICIDES OVER TIME\n"
       "=============================================================================\n\n"
       "Homicides by Year:\n"
       "-------------------\n"
       (str/join "\n" 
                 (map (fn [[year count]]
                        (format "  %d: %3d homicides" year count))
                      yearly))
       "\n\n"
       "Year-over-Year Changes:\n"
       "-----------------------\n"
       (str/join "\n"
                 (map (fn [change]
                        (format "  %d: %3d homicides (change: %+3d, %s)"
                                (:year change)
                                (:count change)
                                (:change change)
                                (:percent-change change)))
                      yoy-changes))
       "\n\n"
       "Monthly Distribution (All Years Combined):\n"
       "-------------------------------------------\n"
       (str/join "\n"
                 (map (fn [[month count]]
                        (format "  Month %2d: %3d homicides" month count))
                      monthly))
       "\n"))

(defn format-neighborhood-analysis
  "Format neighborhood hot spots analysis (pure function)"
  [top-neighborhoods all-stats]
  (str "\n"
       "=============================================================================\n"
       "ANALYSIS 2: NEIGHBORHOOD HOT SPOTS - TOP LOCATIONS\n"
       "=============================================================================\n\n"
       "Top 10 Neighborhoods by Homicide Count:\n"
       "----------------------------------------\n"
       (str/join "\n"
                 (map-indexed (fn [idx [neighborhood count]]
                                (format "%2d. %-40s %3d homicides"
                                        (inc idx) neighborhood count))
                              top-neighborhoods))
       "\n\n"
       "Detailed Neighborhood Statistics (Top 10):\n"
       "-------------------------------------------\n"
       (format "%-40s %6s %8s %10s %8s\n"
               "Neighborhood" "Total" "Closed" "Clear %" "Avg Age")
       (str/join ""
                 (repeat 80 "-"))
       "\n"
       (str/join "\n"
                 (map (fn [stat]
                        (format "%-40s %6d %8d %9.1f%% %8s"
                                (:neighborhood stat)
                                (:total stat)
                                (:closed stat)
                                (:clearance-rate stat)
                                (:avg-age stat)))
                      (take 10 all-stats)))
       "\n"))

(defn format-additional-insights
  "Format additional analysis results (pure function)"
  [weapon-dist]
  (str "\n"
       "=============================================================================\n"
       "ADDITIONAL INSIGHTS\n"
       "=============================================================================\n\n"
       "Weapon/Cause Distribution:\n"
       "--------------------------\n"
       (str/join "\n"
                 (map (fn [[cause count]]
                        (format "  %-20s %3d homicides" cause count))
                      weapon-dist))
       "\n"))

;; ============================================================================
;; Main Program - I/O Layer (separated from pure functions)
;; ============================================================================

(defn read-csv-file
  "Read CSV file (I/O - not pure)"
  [filename]
  (try
    (slurp filename)
    (catch Exception e
      (println "Error reading file:" (.getMessage e))
      nil)))

(defn run-analysis
  "Main analysis orchestration (pure function composition)"
  [homicides]
  (let [;; Analysis 1: Temporal Trends
        yearly (homicides-by-year homicides)
        yearly-map (into {} yearly)
        yoy-changes (calculate-year-over-year-change yearly-map)
        monthly (homicides-by-month homicides)
        
        ;; Analysis 2: Neighborhood Hot Spots
        top-10-neighborhoods (top-neighborhoods 10 homicides)
        neighborhood-stats (neighborhood-statistics homicides)
        
        ;; Additional Insights
        weapons (weapon-distribution homicides)]
    
    ;; Compose all reports (pure function composition)
    (str (format-temporal-analysis yearly yoy-changes monthly)
         (format-neighborhood-analysis top-10-neighborhoods neighborhood-stats)
         (format-additional-insights weapons))))

(defn -main
  "Main entry point - handles I/O"
  [& args]
  (let [filename (or (first args) "baltimore_homicides_combined.csv")]
    (println "=============================================================================")
    (println "BALTIMORE HOMICIDE FUNCTIONAL ANALYSIS")
    (println "Pure Functional Programming in Clojure")
    (println "=============================================================================")
    (println)
    (println "Reading CSV file:" filename)
    
    (if-let [csv-content (read-csv-file filename)]
      (let [homicides (parse-csv-data csv-content)]
        (println "Loaded" (count homicides) "homicide records")
        (println)
        (println (run-analysis homicides))
        (println)
        (println "=============================================================================")
        (println "Analysis Complete")
        (println "============================================================================="))
      (do
        (println "Failed to read CSV file. Exiting.")
        (System/exit 1)))))
