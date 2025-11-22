(ns baltimore-homicide-analysis
  (:require [clojure.string :as str]
            [clojure.java.io :as io]))

;; ============================================================================
;; DATA TYPES & PARSING (Pure Functions)
;; ============================================================================

(defrecord Homicide [date year month day 
                     victim-name victim-race victim-sex victim-age
                     location neighborhood district
                     weapon cause disposition])

(defn parse-date
  "Parse date string into year, month, day components"
  [date-str]
  (when (and date-str (not (str/blank? date-str)))
    (let [parts (str/split date-str #"/")]
      (when (= 3 (count parts))
        {:month (Integer/parseInt (first parts))
         :day (Integer/parseInt (second parts))
         :year (Integer/parseInt (nth parts 2))}))))

(defn parse-age
  "Parse age string to integer, handling invalid values"
  [age-str]
  (try
    (when (and age-str (not (str/blank? age-str)))
      (Integer/parseInt age-str))
    (catch Exception _ nil)))

(defn csv-line->homicide
  "Convert CSV line to Homicide record (Pure function)"
  [line]
  (let [fields (str/split line #",")
        date-str (nth fields 0 "")
        date-parts (parse-date date-str)]
    (map->Homicide
     {:date date-str
      :year (:year date-parts)
      :month (:month date-parts)
      :day (:day date-parts)
      :victim-name (nth fields 1 "")
      :victim-race (nth fields 2 "")
      :victim-sex (nth fields 3 "")
      :victim-age (parse-age (nth fields 4 ""))
      :location (nth fields 5 "")
      :neighborhood (nth fields 6 "")
      :district (nth fields 7 "")
      :weapon (nth fields 8 "")
      :cause (nth fields 9 "")
      :disposition (nth fields 10 "")})))

(defn parse-csv
  "Parse CSV file into list of Homicide records (Pure function on data)"
  [csv-content]
  (->> (str/split-lines csv-content)
       rest  ; Skip header
       (map csv-line->homicide)
       (filter #(and (:year %) (:month %))))) ; Filter valid records

;; ============================================================================
;; ANALYSIS 1: Temporal Patterns - Homicides per Year with Trend Analysis
;; ============================================================================

(defn homicides-per-year
  "Group homicides by year and count (Pure function using map/reduce)"
  [homicides]
  (->> homicides
       (group-by :year)
       (map (fn [[year cases]] {:year year :count (count cases)}))
       (sort-by :year)))

(defn calculate-year-over-year-change
  "Calculate year-over-year percentage change (Pure function)"
  [yearly-data]
  (map (fn [curr prev]
         (let [change (- (:count curr) (:count prev))
               pct-change (if (zero? (:count prev))
                           0.0
                           (* 100.0 (/ change (:count prev))))]
           (assoc curr 
                  :change change
                  :pct-change pct-change)))
       (rest yearly-data)
       yearly-data))

(defn identify-trend
  "Identify overall trend direction (Pure function using reduce)"
  [yearly-changes]
  (let [increases (count (filter #(pos? (:change %)) yearly-changes))
        total (count yearly-changes)
        increase-rate (if (zero? total) 0 (/ increases total))]
    (cond
      (> increase-rate 0.6) :increasing
      (< increase-rate 0.4) :decreasing
      :else :stable)))

(defn analyze-temporal-patterns
  "Complete temporal analysis (Composition of pure functions)"
  [homicides]
  (let [yearly (homicides-per-year homicides)
        with-changes (calculate-year-over-year-change yearly)
        trend (identify-trend with-changes)
        total (reduce + (map :count yearly))
        avg (/ total (count yearly))]
    {:yearly-data with-changes
     :trend trend
     :total-homicides total
     :average-per-year avg}))

;; ============================================================================
;; ANALYSIS 2: Weapon Distribution & Lethality Analysis
;; ============================================================================

(defn normalize-weapon
  "Normalize weapon names for consistent grouping (Pure function)"
  [weapon]
  (let [w (str/lower-case (or weapon "unknown"))]
    (cond
      (str/includes? w "gun") "Firearm"
      (str/includes? w "handgun") "Firearm"
      (str/includes? w "rifle") "Firearm"
      (str/includes? w "firearm") "Firearm"
      (str/includes? w "knife") "Knife/Blade"
      (str/includes? w "blade") "Knife/Blade"
      (str/includes? w "hands") "Hands/Fists/Feet"
      (str/includes? w "fist") "Hands/Fists/Feet"
      (str/includes? w "blunt") "Blunt Object"
      (str/includes? w "asphyxiation") "Asphyxiation"
      (str/includes? w "unknown") "Unknown"
      :else "Other")))

(defn weapon-distribution
  "Calculate weapon type distribution (Pure function using map/reduce)"
  [homicides]
  (->> homicides
       (map #(normalize-weapon (:weapon %)))
       frequencies
       (map (fn [[weapon count]] 
              {:weapon weapon 
               :count count
               :percentage (* 100.0 (/ count (count homicides)))}))
       (sort-by :count >)))

(defn weapon-by-year
  "Analyze weapon usage trends over time (Pure function)"
  [homicides]
  (->> homicides
       (group-by :year)
       (map (fn [[year cases]]
              (let [firearm-count (count (filter #(= "Firearm" (normalize-weapon (:weapon %))) cases))
                    total (count cases)]
                {:year year
                 :total total
                 :firearm-count firearm-count
                 :firearm-percentage (* 100.0 (/ firearm-count total))})))
       (sort-by :year)))

(defn analyze-weapon-patterns
  "Complete weapon analysis (Composition of pure functions)"
  [homicides]
  (let [distribution (weapon-distribution homicides)
        by-year (weapon-by-year homicides)
        most-common (first distribution)
        firearm-dominance (first (filter #(= "Firearm" (:weapon %)) distribution))]
    {:weapon-distribution distribution
     :weapon-trends-by-year by-year
     :most-common-weapon most-common
     :firearm-statistics firearm-dominance}))

;; ============================================================================
;; OUTPUT FORMATTING (Pure functions for display)
;; ============================================================================

(defn format-temporal-results
  "Format temporal analysis for display (Pure function)"
  [results]
  (let [{:keys [yearly-data trend total-homicides average-per-year]} results]
    (str "\n" (str/join "" (repeat 80 "=")) "\n"
         "ANALYSIS 1: TEMPORAL PATTERNS - Homicides Over Time\n"
         (str/join "" (repeat 80 "=")) "\n\n"
         "YEARLY HOMICIDE COUNTS:\n"
         (str/join "" (repeat 80 "-")) "\n"
         (format "%-10s %10s %15s %20s\n" "Year" "Count" "YoY Change" "% Change")
         (str/join "" (repeat 80 "-")) "\n"
         (str/join "\n"
                   (concat
                    [(format "%-10d %10d %15s %20s"
                            (:year (first yearly-data))
                            (:count (first yearly-data))
                            "N/A"
                            "N/A")]
                    (map (fn [data]
                           (format "%-10d %10d %15s %19.1f%%"
                                   (:year data)
                                   (:count data)
                                   (if (pos? (:change data)) 
                                     (str "+" (:change data))
                                     (str (:change data)))
                                   (:pct-change data)))
                         yearly-data)))
         "\n\n"
         "SUMMARY:\n"
         (format "  • Total homicides analyzed: %d\n" total-homicides)
         (format "  • Average per year: %.1f\n" (double average-per-year))
         (format "  • Overall trend: %s\n" (name trend))
         (case trend
           :increasing "  • Recommendation: Increase violence prevention programs\n"
           :decreasing "  • Recommendation: Continue current strategies and evaluate success factors\n"
           :stable     "  • Recommendation: Maintain current resource allocation\n")
         "\n")))

(defn format-weapon-results
  "Format weapon analysis for display (Pure function)"
  [results]
  (let [{:keys [weapon-distribution most-common-weapon firearm-statistics]} results]
    (str "\n" (str/join "" (repeat 80 "=")) "\n"
         "ANALYSIS 2: WEAPON PATTERNS - Distribution & Trends\n"
         (str/join "" (repeat 80 "=")) "\n\n"
         "WEAPON TYPE DISTRIBUTION:\n"
         (str/join "" (repeat 80 "-")) "\n"
         (format "%-25s %12s %15s\n" "Weapon Type" "Count" "Percentage")
         (str/join "" (repeat 80 "-")) "\n"
         (str/join "\n"
                   (map (fn [w]
                          (format "%-25s %12d %14.1f%%"
                                  (:weapon w)
                                  (:count w)
                                  (:percentage w)))
                        weapon-distribution))
         "\n\n"
         "KEY FINDINGS:\n"
         (format "  • Most common weapon: %s (%d incidents, %.1f%%)\n"
                 (:weapon most-common-weapon)
                 (:count most-common-weapon)
                 (:percentage most-common-weapon))
         (when firearm-statistics
           (format "  • Firearm-involved homicides: %d (%.1f%% of all cases)\n"
                   (:count firearm-statistics)
                   (:percentage firearm-statistics)))
         "\n"
         "RECOMMENDATIONS:\n"
         "  • Focus gun violence prevention programs in high-incident areas\n"
         "  • Implement community-based intervention strategies\n"
         "  • Enhance illegal firearm tracking and removal programs\n"
         "\n")))

;; ============================================================================
;; MAIN PROGRAM (I/O Boundary - Not Pure)
;; ============================================================================

(defn load-csv-file
  "Load CSV file content (I/O - Not a pure function)"
  [filename]
  (try
    (slurp filename)
    (catch Exception e
      (println (str "Error reading file: " (.getMessage e)))
      nil)))

(defn -main
  "Main entry point (I/O boundary)"
  [& args]
  (println "\n" (str/join "" (repeat 80 "="))
           "\nBALTIMORE CITY HOMICIDE ANALYSIS - Functional Programming Approach"
           "\n" (str/join "" (repeat 80 "=")) "\n")
  
  (let [filename "baltimore_homicides_combined.csv"
        csv-content (load-csv-file filename)]
    
    (if csv-content
      (let [homicides (parse-csv csv-content)
            _ (println (format "Successfully loaded %d homicide records\n" (count homicides)))
            
            ;; Pure functional analyses
            temporal-results (analyze-temporal-patterns homicides)
            weapon-results (analyze-weapon-patterns homicides)]
        
        ;; Display results
        (println (format-temporal-results temporal-results))
        (println (format-weapon-results weapon-results))
        (println (str/join "" (repeat 80 "="))
                 "\nAnalysis complete!"
                 "\n" (str/join "" (repeat 80 "="))))
      
      (println "ERROR: Could not load CSV file. Please ensure baltimore_homicides_combined.csv exists."))))

;; Run main function
(-main)