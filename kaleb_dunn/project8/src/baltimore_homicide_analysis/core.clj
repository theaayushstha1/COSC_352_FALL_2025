(ns baltimore-homicide-analysis.core
  (:require [clojure.data.csv :as csv]
            [clojure.java.io :as io]
            [clojure.string :as str])
  (:gen-class))

;; ============================================================================
;; DATA TYPES
;; ============================================================================

(defrecord HomicideRecord
  [case-number
   date
   time
   location
   district
   neighborhood
   weapon
   victim-name
   victim-race
   victim-sex
   victim-age
   year
   month])

;; ============================================================================
;; PURE FUNCTIONAL PARSING
;; ============================================================================

(defn parse-int
  "Safely parse integer, return nil if invalid"
  [s]
  (when (and s (not (str/blank? s)))
    (try
      (Integer/parseInt (str/trim s))
      (catch Exception _ nil))))

(defn parse-year
  "Extract year from date string (MM/DD/YYYY)"
  [date-str]
  (when date-str
    (let [parts (str/split date-str #"/")]
      (when (= 3 (count parts))
        (parse-int (nth parts 2))))))

(defn parse-month
  "Extract month from date string (MM/DD/YYYY)"
  [date-str]
  (when date-str
    (let [parts (str/split date-str #"/")]
      (when (= 3 (count parts))
        (parse-int (nth parts 0))))))

(defn csv-row->homicide-record
  "Pure function to transform CSV row vector into HomicideRecord"
  [row]
  (when (and (vector? row) (>= (count row) 11))
    (let [[case-num date time location district neighborhood
           weapon victim-name victim-race victim-sex victim-age] row]
      (->HomicideRecord
        case-num
        date
        time
        location
        district
        neighborhood
        weapon
        victim-name
        victim-race
        victim-sex
        (parse-int victim-age)
        (parse-year date)
        (parse-month date)))))

(defn parse-csv-data
  "Pure function to parse CSV string into list of HomicideRecords"
  [csv-string]
  (->> (csv/read-csv csv-string)
       (rest)  ; Skip header row
       (map vec)
       (map csv-row->homicide-record)
       (filter some?)))  ; Remove nil records

;; ============================================================================
;; PURE FUNCTIONAL ANALYSIS FUNCTIONS
;; ============================================================================

;; Analysis 1: Homicides by Year with Trend Analysis
;; ----------------------------------------------------------------------------

(defn group-by-year
  "Pure function to group homicides by year"
  [records]
  (->> records
       (filter :year)
       (group-by :year)))

(defn count-by-year
  "Pure function to count homicides per year"
  [records]
  (->> (group-by-year records)
       (map (fn [[year recs]] [year (count recs)]))
       (into (sorted-map))))

(defn calculate-year-over-year-change
  "Pure function to calculate percentage change between consecutive years"
  [year-counts]
  (let [sorted-years (sort (keys year-counts))
        pairs (partition 2 1 sorted-years)]
    (map (fn [[y1 y2]]
           (let [count1 (get year-counts y1)
                 count2 (get year-counts y2)
                 change (- count2 count1)
                 pct-change (* 100.0 (/ change count1))]
             {:from-year y1
              :to-year y2
              :from-count count1
              :to-count count2
              :change change
              :percent-change (double pct-change)}))
         pairs)))

(defn calculate-average-change
  "Pure function to calculate average year-over-year change"
  [changes]
  (if (empty? changes)
    0.0
    (/ (reduce + (map :percent-change changes))
       (count changes))))

(defn analyze-yearly-trends
  "Pure function to perform complete yearly trend analysis"
  [records]
  (let [year-counts (count-by-year records)
        yoy-changes (calculate-year-over-year-change year-counts)
        avg-change (calculate-average-change yoy-changes)
        total (reduce + (vals year-counts))
        years (keys year-counts)]
    {:year-counts year-counts
     :year-over-year-changes yoy-changes
     :average-annual-change avg-change
     :total-homicides total
     :years-covered (count years)
     :year-range [(first years) (last years)]}))

;; Analysis 2: Neighborhood Analysis
;; ----------------------------------------------------------------------------

(defn group-by-neighborhood
  "Pure function to group homicides by neighborhood"
  [records]
  (->> records
       (filter #(not (str/blank? (:neighborhood %))))
       (group-by :neighborhood)))

(defn count-by-neighborhood
  "Pure function to count homicides per neighborhood"
  [records]
  (->> (group-by-neighborhood records)
       (map (fn [[neighborhood recs]] 
              {:neighborhood neighborhood
               :count (count recs)}))
       (sort-by :count >)))

(defn top-n-neighborhoods
  "Pure function to get top N neighborhoods by homicide count"
  [n records]
  (take n (count-by-neighborhood records)))

(defn calculate-neighborhood-percentage
  "Pure function to calculate each neighborhood's percentage of total"
  [neighborhood-counts total]
  (map (fn [{:keys [neighborhood count]}]
         {:neighborhood neighborhood
          :count count
          :percentage (* 100.0 (/ count total))})
       neighborhood-counts))

(defn analyze-weapon-types-by-neighborhood
  "Pure function to analyze weapon distribution in top neighborhoods"
  [records top-neighborhoods]
  (let [top-names (set (map :neighborhood top-neighborhoods))]
    (->> records
         (filter #(contains? top-names (:neighborhood %)))
         (group-by :neighborhood)
         (map (fn [[neighborhood recs]]
                (let [weapons (->> recs
                                  (filter #(not (str/blank? (:weapon %))))
                                  (group-by :weapon)
                                  (map (fn [[weapon wrecs]]
                                         {:weapon weapon
                                          :count (count wrecs)}))
                                  (sort-by :count >))]
                  {:neighborhood neighborhood
                   :total-count (count recs)
                   :weapons weapons
                   :most-common-weapon (:weapon (first weapons))})))
         (sort-by :total-count >))))

(defn analyze-neighborhoods
  "Pure function to perform complete neighborhood analysis"
  [records n]
  (let [total (count records)
        top-n (top-n-neighborhoods n records)
        with-percentages (calculate-neighborhood-percentage top-n total)
        weapon-analysis (analyze-weapon-types-by-neighborhood records top-n)]
    {:top-neighborhoods with-percentages
     :total-neighborhoods (count (distinct (map :neighborhood records)))
     :weapon-analysis weapon-analysis}))

;; ============================================================================
;; OUTPUT FORMATTING (Pure Functions)
;; ============================================================================

(defn format-yearly-trends-report
  "Pure function to format yearly trends as string"
  [analysis]
  (let [{:keys [year-counts year-over-year-changes average-annual-change
                total-homicides years-covered year-range]} analysis]
    (str
      "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
      "ANALYSIS 1: YEARLY TRENDS & TEMPORAL PATTERNS\n"
      "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
      
      "📊 SUMMARY STATISTICS\n"
      "  • Total homicides: " total-homicides "\n"
      "  • Years covered: " years-covered " (" (first year-range) "-" (last year-range) ")\n"
      "  • Average year-over-year change: " (format "%.2f" average-annual-change) "%\n\n"
      
      "📈 HOMICIDES BY YEAR\n"
      (str/join "\n" 
        (map (fn [[year count]]
               (format "  %d: %4d homicides %s"
                      year count
                      (apply str (repeat (/ count 10) "█"))))
             year-counts))
      "\n\n"
      
      "📉 YEAR-OVER-YEAR CHANGES\n"
      (str/join "\n"
        (map (fn [{:keys [from-year to-year change percent-change]}]
               (format "  %d → %d: %+4d (%+.1f%%) %s"
                      from-year to-year change percent-change
                      (if (pos? change) "📈" "📉")))
             year-over-year-changes))
      "\n\n"
      
      "💡 KEY INSIGHTS\n"
      (let [max-year (apply max-key val year-counts)
            min-year (apply min-key val year-counts)
            trend (if (pos? average-annual-change) "increasing" "decreasing")]
        (str
          "  • Worst year: " (key max-year) " (" (val max-year) " homicides)\n"
          "  • Best year: " (key min-year) " (" (val min-year) " homicides)\n"
          "  • Overall trend: " trend " (" (format "%.2f" average-annual-change) "% per year)\n"))
      "\n")))

(defn format-neighborhood-report
  "Pure function to format neighborhood analysis as string"
  [analysis n]
  (let [{:keys [top-neighborhoods total-neighborhoods weapon-analysis]} analysis]
    (str
      "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
      "ANALYSIS 2: NEIGHBORHOOD HOT SPOTS & WEAPON PATTERNS\n"
      "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
      
      "📍 TOP " n " NEIGHBORHOODS BY HOMICIDE COUNT\n"
      (str/join "\n"
        (map-indexed
          (fn [idx {:keys [neighborhood count percentage]}]
            (format "  %2d. %-30s %4d (%5.2f%%) %s"
                   (inc idx)
                   neighborhood
                   count
                   percentage
                   (apply str (repeat (int (/ percentage 2)) "█"))))
          top-neighborhoods))
      "\n\n"
      
      "🔫 WEAPON ANALYSIS FOR TOP NEIGHBORHOODS\n"
      (str/join "\n"
        (map (fn [{:keys [neighborhood total-count most-common-weapon weapons]}]
               (str
                 "  • " neighborhood " (" total-count " total)\n"
                 "    Most common: " most-common-weapon "\n"
                 "    Top weapons:\n"
                 (str/join "\n"
                   (map (fn [{:keys [weapon count]}]
                          (format "      - %-20s %3d (%5.1f%%)"
                                 weapon count
                                 (* 100.0 (/ count total-count))))
                        (take 3 weapons)))
                 "\n"))
             weapon-analysis))
      "\n"
      
      "💡 KEY INSIGHTS\n"
      (let [top-3 (take 3 top-neighborhoods)
            top-3-pct (reduce + (map :percentage top-3))]
        (str
          "  • Total neighborhoods with incidents: " total-neighborhoods "\n"
          "  • Top 3 neighborhoods account for: " (format "%.1f%%" top-3-pct) " of all homicides\n"
          "  • Most dangerous neighborhood: " (:neighborhood (first top-neighborhoods))
          " (" (:count (first top-neighborhoods)) " homicides)\n"))
      "\n")))

;; ============================================================================
;; I/O LAYER (Impure - separated from analysis logic)
;; ============================================================================

(defn load-csv-file
  "Impure I/O function to load CSV file"
  [filepath]
  (try
    (slurp filepath)
    (catch Exception e
      (println "Error loading file:" (.getMessage e))
      nil)))

(defn download-csv-from-url
  "Impure I/O function to download CSV from URL"
  [url]
  (try
    (slurp url)
    (catch Exception e
      (println "Error downloading from URL:" (.getMessage e))
      nil)))

(defn print-report
  "Impure I/O function to print report"
  [report]
  (println report))

;; ============================================================================
;; MAIN PROGRAM
;; ============================================================================

(defn -main
  [& args]
  (println "\n╔══════════════════════════════════════════════════════════════╗")
  (println "║  Baltimore Homicide Analysis - Functional Programming       ║")
  (println "║  Language: Clojure                                           ║")
  (println "╚══════════════════════════════════════════════════════════════╝\n")
  
  ;; I/O: Load data
  (println "📥 Loading data...")
  (let [url "https://raw.githubusercontent.com/professor-jon-white/COSC_352_FALL_2025/be5df82c2e4aea13f2becf14f11fab1eac549baa/professor_jon_white/func_prog/baltimore_homicides_combined.csv"
        csv-data (or (download-csv-from-url url)
                    (load-csv-file "baltimore_homicides_combined.csv"))]
    
    (if csv-data
      (do
        (println "✓ Data loaded successfully\n")
        
        ;; Pure functional processing
        (let [records (parse-csv-data csv-data)
              _ (println "✓ Parsed" (count records) "homicide records\n")
              
              ;; Pure analysis
              yearly-analysis (analyze-yearly-trends records)
              neighborhood-analysis (analyze-neighborhoods records 10)
              
              ;; Pure formatting
              report1 (format-yearly-trends-report yearly-analysis)
              report2 (format-neighborhood-report neighborhood-analysis 10)]
          
          ;; I/O: Print results
          (print-report report1)
          (print-report report2)
          
          (println "╔══════════════════════════════════════════════════════════════╗")
          (println "║  Analysis Complete                                           ║")
          (println "╚══════════════════════════════════════════════════════════════╝\n")))
      
      (println "❌ Failed to load data. Exiting."))))
