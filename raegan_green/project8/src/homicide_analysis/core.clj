(ns homicide-analysis.core
  (:require [clojure.string :as str]
            [clojure.java.io :as io]))

;; ============================================================================
;; PURE FUNCTIONAL CORE - No I/O, No Mutation
;; ============================================================================

;; Type Definition: Homicide Record
(defrecord HomicideRecord [no date-died name age address notes 
                           no-criminal-history surveillance-camera 
                           case-closed source-page year lat lon])

;; Parser: Parse a single CSV row into a HomicideRecord
(defn parse-row
  "Pure function: Convert CSV row vector to HomicideRecord"
  [row]
  (when (and (seq row) (>= (count row) 13))
    (let [[no date-died name age address notes criminal-history 
           surveillance case-closed source-page year lat lon] row
          parsed-age (try (Integer/parseInt (str/replace age #"[^\d]" ""))
                         (catch Exception _ 0))
          parsed-year (try (Integer/parseInt year)
                          (catch Exception _ 0))
          parsed-lat (try (Double/parseDouble lat)
                         (catch Exception _ 0.0))
          parsed-lon (try (Double/parseDouble lon)
                         (catch Exception _ 0.0))]
      (->HomicideRecord no date-died name parsed-age address notes
                       criminal-history surveillance case-closed 
                       source-page parsed-year parsed-lat parsed-lon))))

;; Parser: Split CSV line respecting quoted fields
(defn parse-csv-line
  "Pure function: Parse CSV line with quoted field handling"
  [line]
  (let [parts (str/split line #",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)")]
    (mapv #(str/replace % #"^\"|\"$" "") parts)))

;; ============================================================================
;; ANALYSIS 1: Homicides by Year with Trend Analysis
;; ============================================================================

(defn homicides-by-year
  "Pure function: Count homicides per year using reduce"
  [records]
  (->> records
       (filter #(> (:year %) 0))
       (map :year)
       (reduce (fn [acc year]
                 (update acc year (fnil inc 0)))
               {})
       (sort-by first)))

(defn calculate-year-trends
  "Pure function: Calculate year-over-year changes"
  [year-counts]
  (let [years (vec year-counts)]
    (map-indexed
     (fn [idx [year count]]
       (if (= idx 0)
         {:year year :count count :change nil :change-pct nil}
         (let [[prev-year prev-count] (nth years (dec idx))
               change (- count prev-count)
               change-pct (if (zero? prev-count) 
                           0 
                           (* 100.0 (/ change prev-count)))]
           {:year year :count count :change change :change-pct change-pct})))
     years)))

(defn find-deadliest-year
  "Pure function: Find year with most homicides using reduce"
  [year-counts]
  (when (seq year-counts)
    (reduce (fn [[max-year max-count] [year count]]
              (if (> count max-count)
                [year count]
                [max-year max-count]))
            (first year-counts)
            (rest year-counts))))

(defn find-safest-year
  "Pure function: Find year with least homicides using reduce"
  [year-counts]
  (when (seq year-counts)
    (reduce (fn [[min-year min-count] [year count]]
              (if (< count min-count)
                [year count]
                [min-year min-count]))
            (first year-counts)
            (rest year-counts))))

;; ============================================================================
;; ANALYSIS 2: Geographic Hotspot Analysis
;; ============================================================================

(defn extract-street-name
  "Pure function: Extract street name from address"
  [address]
  (when address
    (let [cleaned (-> address
                     str/trim
                     (str/replace #"^\d+\s+" "")  ; Remove house number
                     str/upper-case)]
      (if (> (count cleaned) 0)
        cleaned
        "Unknown"))))

(defn top-n-hotspots
  "Pure function: Find top N locations using map, filter, reduce"
  [records n]
  (->> records
       (map :address)
       (filter #(and % (not= % "")))
       (map extract-street-name)
       (reduce (fn [acc street]
                 (update acc street (fnil inc 0)))
               {})
       (sort-by second >)
       (take n)))

(defn calculate-hotspot-percentage
  "Pure function: Calculate what % of total homicides occur in top N spots"
  [hotspots total-records]
  (let [hotspot-total (reduce + (map second hotspots))]
    (* 100.0 (/ hotspot-total total-records))))

(defn group-by-street-type
  "Pure function: Categorize streets by type (Avenue, Street, Road, etc.)"
  [hotspots]
  (->> hotspots
       (map first)
       (map (fn [addr]
              (cond
                (str/includes? addr "AVENUE") "Avenue"
                (str/includes? addr "STREET") "Street"
                (str/includes? addr "ROAD") "Road"
                (str/includes? addr "DRIVE") "Drive"
                (str/includes? addr "COURT") "Court"
                (str/includes? addr "BOULEVARD") "Boulevard"
                :else "Other")))
       (reduce (fn [acc type]
                 (update acc type (fnil inc 0)))
               {})
       (sort-by second >)))

;; ============================================================================
;; ADDITIONAL PURE FUNCTIONS
;; ============================================================================

(defn case-closure-rate
  "Pure function: Calculate percentage of closed cases"
  [records]
  (let [total (count records)
        closed (count (filter #(= (:case-closed %) "Closed") records))]
    (if (zero? total)
      0.0
      (* 100.0 (/ closed total)))))

(defn average-victim-age
  "Pure function: Calculate average age using reduce"
  [records]
  (let [valid-ages (filter #(> % 0) (map :age records))
        total (reduce + valid-ages)
        count (count valid-ages)]
    (if (zero? count)
      0.0
      (double (/ total count)))))

;; ============================================================================
;; I/O LAYER - Only place with side effects
;; ============================================================================

(defn read-csv-file
  "Impure: Read CSV file and parse into records"
  [filepath]
  (with-open [reader (io/reader filepath)]
    (let [lines (line-seq reader)
          data-lines (rest lines)]  ; Skip header
      (doall
       (->> data-lines
            (map parse-csv-line)
            (map parse-row)
            (filter some?))))))

(defn print-separator
  "Print visual separator"
  []
  (println (apply str (repeat 80 "="))))

(defn print-analysis-header
  "Print analysis section header"
  [title]
  (println)
  (print-separator)
  (println title)
  (print-separator)
  (println))

(defn format-percentage
  "Format number as percentage"
  [n]
  (format "%.1f%%" n))

(defn format-number
  "Format number with commas"
  [n]
  (format "%,d" n))

;; ============================================================================
;; MAIN PROGRAM
;; ============================================================================

(defn -main
  [& args]
  (println "\nBALTIMORE HOMICIDE ANALYSIS")
  (println "Functional Programming - Pure Functions Only")
  (print-separator)
  
  ;; I/O: Read data
  (let [filepath "baltimore_homicides_combined.csv"
        _ (println "\nLoading data from:" filepath)
        records (read-csv-file filepath)
        total-records (count records)]
    
    (println "Total records loaded:" (format-number total-records))
    
    ;; Analysis 1: Year Trends (Pure Functional)
    (print-analysis-header "ANALYSIS 1: HOMICIDES BY YEAR WITH TRENDS")
    
    (let [year-counts (homicides-by-year records)
          trends (calculate-year-trends year-counts)
          [deadliest-year deadliest-count] (find-deadliest-year year-counts)
          [safest-year safest-count] (find-safest-year year-counts)]
      
      (println "Homicides by Year:")
      (println "Year  | Count  | Change | Change %")
      (println (apply str (repeat 45 "-")))
      
      (doseq [{:keys [year count change change-pct]} trends]
        (if change
          (println (format "%4d  | %,6d | %+6d | %+7.1f%%" 
                          year count change change-pct))
          (println (format "%4d  | %,6d |      - |       -" 
                          year count))))
      
      (println)
      (println "Key Findings:")
      (println "• Deadliest Year:" deadliest-year "with" (format-number deadliest-count) "homicides")
      (println "• Safest Year:" safest-year "with" (format-number safest-count) "homicides")
      (println "• Total Homicides (all years):" (format-number total-records)))
    
    ;; Analysis 2: Geographic Hotspots (Pure Functional)
    (print-analysis-header "ANALYSIS 2: GEOGRAPHIC HOTSPOT ANALYSIS")
    
    (let [top-15-spots (top-n-hotspots records 15)
          hotspot-pct (calculate-hotspot-percentage top-15-spots total-records)
          street-types (group-by-street-type top-15-spots)]
      
      (println "Top 15 Most Dangerous Locations:")
      (println "Rank | Location                              | Count")
      (println (apply str (repeat 65 "-")))
      
      (doseq [[idx [location cnt]] (map-indexed vector top-15-spots)]
        (println (format "%2d.  | %-37s | %,5d" 
                        (inc idx) 
                        (subs location 0 (min 37 (count location))) 
                        cnt)))
      
      (println)
      (println "Geographic Insights:")
      (println "• Top 15 locations account for" (format-percentage hotspot-pct) "of all homicides")
      (println "• Total unique locations:" (format-number (count (set (map :address records)))))
      
      (println)
      (println "Street Type Distribution:")
      (doseq [[street-type count] street-types]
        (println (format "  %-12s: %d locations" street-type count))))
    
    ;; Summary Statistics
    (print-analysis-header "SUMMARY STATISTICS")
    
    (let [closure-rate (case-closure-rate records)
          avg-age (average-victim-age records)]
      
      (println "Overall Case Closure Rate:" (format-percentage closure-rate))
      (println "Average Victim Age:" (format "%.1f years" avg-age))
      (println "Youth Victims (≤18):" 
               (format-number (count (filter #(<= (:age %) 18) records)))))
    
    (print-separator)
    (println "\nAnalysis Complete!")
    (println)))