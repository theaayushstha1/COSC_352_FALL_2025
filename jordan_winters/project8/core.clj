(ns baltimore-homicides.core
  (:require [clojure.string :as str]
            [clojure.java.io :as io])
  (:gen-class))

;; =============================================================================
;; TYPES & DATA STRUCTURES
;; =============================================================================

(defrecord Homicide [no date-died name age address-block year lat lon])

;; =============================================================================
;; PURE FUNCTIONS - CSV PARSING
;; =============================================================================

(defn parse-date
  "Parse date string and extract year and month."
  [date-str]
  (when (and date-str (not (str/blank? date-str)))
    (try
      (let [parts (str/split date-str #"[/]")]
        (when (>= (count parts) 3)
          {:month (Integer/parseInt (first parts))
           :day (Integer/parseInt (second parts))
           :year (Integer/parseInt (nth parts 2))}))
      (catch Exception _ nil))))

(defn parse-csv-line
  "Parse a single CSV line into a Homicide record.
   CSV format: No.,Date Died,Name,Age,Address Block Found,Notes,Victim Has No Violent Criminal History,Surveillance Camera At Intersection,Case Closed,source_page,year,lat,lon"
  [line]
  (let [fields (str/split line #",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)") ; Handle quoted fields
        clean-field (fn [s] (str/trim (str/replace s #"\"" "")))]
    (when (>= (count fields) 13)
      (try
        (->Homicide
          (clean-field (nth fields 0))
          (clean-field (nth fields 1))
          (clean-field (nth fields 2))
          (let [age-str (clean-field (nth fields 3))]
            (try (Integer/parseInt (re-find #"\d+" age-str))
                 (catch Exception _ nil)))
          (clean-field (nth fields 4))
          (try (Integer/parseInt (clean-field (nth fields 10)))
               (catch Exception _ nil))
          (try (Double/parseDouble (clean-field (nth fields 11)))
               (catch Exception _ nil))
          (try (Double/parseDouble (clean-field (nth fields 12)))
               (catch Exception _ nil)))
        (catch Exception _ nil)))))

(defn parse-csv
  "Parse CSV content into a sequence of Homicide records."
  [csv-content]
  (->> (str/split-lines csv-content)
       (drop 1) ; Skip header
       (map parse-csv-line)
       (filter some?)))

;; =============================================================================
;; PURE FUNCTIONS - ANALYSIS 1: TEMPORAL ANALYSIS
;; =============================================================================

(defn group-by-year
  "Group homicides by year using reduce."
  [homicides]
  (reduce
    (fn [acc h]
      (if (:year h)
        (update acc (:year h) (fnil conj []) h)
        acc))
    {}
    homicides))

(defn count-by-year
  "Count homicides per year."
  [homicides]
  (->> (group-by-year homicides)
       (map (fn [[year hs]] [year (count hs)]))
       (into (sorted-map))))

(defn group-by-month
  "Group homicides by month using reduce."
  [homicides]
  (reduce
    (fn [acc h]
      (if (:month h)
        (update acc (:month h) (fnil conj []) h)
        acc))
    {}
    homicides))

(defn count-by-month
  "Count homicides per month across all years."
  [homicides]
  (->> (group-by-month homicides)
       (map (fn [[month hs]] [month (count hs)]))
       (into (sorted-map))))

(defn calculate-year-trend
  "Calculate simple trend (difference between first and last year)."
  [year-counts]
  (let [years (keys year-counts)
        first-year (apply min years)
        last-year (apply max years)
        first-count (get year-counts first-year)
        last-count (get year-counts last-year)]
    {:first-year first-year
     :last-year last-year
     :first-count first-count
     :last-count last-count
     :change (- last-count first-count)
     :percent-change (if (pos? first-count)
                       (* 100.0 (/ (- last-count first-count) first-count))
                       0.0)}))

;; =============================================================================
;; PURE FUNCTIONS - ANALYSIS 2: NEIGHBORHOOD ANALYSIS
;; =============================================================================

(defn group-by-neighborhood
  "Group homicides by neighborhood using reduce."
  [homicides]
  (reduce
    (fn [acc h]
      (let [neighborhood (if (str/blank? (:neighborhood h))
                          "Unknown"
                          (:neighborhood h))]
        (update acc neighborhood (fnil conj []) h)))
    {}
    homicides))

(defn count-by-neighborhood
  "Count homicides per neighborhood."
  [homicides]
  (->> (group-by-neighborhood homicides)
       (map (fn [[neighborhood hs]] [neighborhood (count hs)]))
       (into {})))

(defn top-n-neighborhoods
  "Get top N neighborhoods by homicide count."
  [homicides n]
  (->> (count-by-neighborhood homicides)
       (sort-by second >)
       (take n)))

;; =============================================================================
;; PURE FUNCTIONS - ANALYSIS 3: WEAPON DISTRIBUTION
;; =============================================================================

(defn group-by-weapon
  "Group homicides by weapon type using reduce."
  [homicides]
  (reduce
    (fn [acc h]
      (let [weapon (if (str/blank? (:weapon h))
                    "Unknown"
                    (:weapon h))]
        (update acc weapon (fnil conj []) h)))
    {}
    homicides))

(defn weapon-distribution
  "Calculate weapon type distribution as percentages."
  [homicides]
  (let [total (count homicides)
        weapon-counts (->> (group-by-weapon homicides)
                          (map (fn [[weapon hs]] [weapon (count hs)]))
                          (into {}))]
    (map
      (fn [[weapon count]]
        [weapon count (* 100.0 (/ count total))])
      (sort-by second > weapon-counts))))

;; =============================================================================
;; PURE FUNCTIONS - ANALYSIS 4: VICTIM DEMOGRAPHICS
;; =============================================================================

(defn group-by-gender
  "Group homicides by victim gender."
  [homicides]
  (reduce
    (fn [acc h]
      (let [gender (if (str/blank? (:victim-gender h))
                    "Unknown"
                    (:victim-gender h))]
        (update acc gender (fnil conj []) h)))
    {}
    homicides))

(defn gender-distribution
  "Calculate gender distribution."
  [homicides]
  (->> (group-by-gender homicides)
       (map (fn [[gender hs]] [gender (count hs)]))
       (sort-by second >)))

(defn calculate-age-statistics
  "Calculate age statistics for victims."
  [homicides]
  (let [ages (->> homicides
                  (map :victim-age)
                  (filter some?)
                  (filter pos?))
        total (count ages)]
    (if (pos? total)
      {:min (apply min ages)
       :max (apply max ages)
       :mean (double (/ (reduce + ages) total))
       :median (let [sorted (sort ages)
                     mid (quot total 2)]
                 (if (odd? total)
                   (nth sorted mid)
                   (/ (+ (nth sorted mid) (nth sorted (dec mid))) 2.0)))}
      {:min 0 :max 0 :mean 0.0 :median 0.0})))

;; =============================================================================
;; OUTPUT FORMATTING
;; =============================================================================

(defn format-temporal-analysis
  "Format temporal analysis results."
  [homicides]
  (let [year-counts (count-by-year homicides)
        month-counts (count-by-month homicides)
        trend (calculate-year-trend year-counts)]
    (str "\n========================================\n"
         "TEMPORAL ANALYSIS\n"
         "========================================\n\n"
         "Homicides by Year:\n"
         (str/join "\n" (map (fn [[year count]]
                              (format "  %d: %d homicides" year count))
                            year-counts))
         "\n\nHomicides by Month (Aggregated):\n"
         (str/join "\n" (map (fn [[month count]]
                              (format "  Month %02d: %d homicides" month count))
                            month-counts))
         "\n\nTrend Analysis:\n"
         (format "  Period: %d to %d\n" (:first-year trend) (:last-year trend))
         (format "  Change: %+d homicides (%.1f%%)\n"
                (:change trend)
                (:percent-change trend)))))

(defn format-neighborhood-analysis
  "Format neighborhood analysis results."
  [homicides]
  (let [top-10 (top-n-neighborhoods homicides 10)
        total (count homicides)]
    (str "\n========================================\n"
         "TOP 10 NEIGHBORHOODS BY HOMICIDE COUNT\n"
         "========================================\n\n"
         (str/join "\n" (map-indexed
                          (fn [idx [neighborhood count]]
                            (format "%2d. %-30s: %4d (%.1f%%)"
                                   (inc idx)
                                   neighborhood
                                   count
                                   (* 100.0 (/ count total))))
                          top-10)))))

(defn format-weapon-analysis
  "Format weapon distribution analysis."
  [homicides]
  (let [distribution (weapon-distribution homicides)]
    (str "\n========================================\n"
         "WEAPON TYPE DISTRIBUTION\n"
         "========================================\n\n"
         (str/join "\n" (map (fn [[weapon count pct]]
                              (format "  %-25s: %4d (%.1f%%)"
                                     weapon count pct))
                            distribution)))))

(defn format-demographic-analysis
  "Format demographic analysis."
  [homicides]
  (let [gender-dist (gender-distribution homicides)
        age-stats (calculate-age-statistics homicides)]
    (str "\n========================================\n"
         "VICTIM DEMOGRAPHIC ANALYSIS\n"
         "========================================\n\n"
         "Gender Distribution:\n"
         (str/join "\n" (map (fn [[gender count]]
                              (format "  %-10s: %d" gender count))
                            gender-dist))
         "\n\nAge Statistics:\n"
         (format "  Minimum:  %d years\n" (:min age-stats))
         (format "  Maximum:  %d years\n" (:max age-stats))
         (format "  Mean:     %.1f years\n" (:mean age-stats))
         (format "  Median:   %.1f years\n" (:median age-stats)))))

;; =============================================================================
;; MAIN PROGRAM (I/O)
;; =============================================================================

(defn -main
  [& args]
  (let [csv-file (or (first args) "baltimore_homicides_combined.csv")]
    (try
      (println "\nBaltimore Homicides Analysis Tool")
      (println "==================================")
      (println (format "Reading data from: %s\n" csv-file))
      
      (let [csv-content (slurp csv-file)
            homicides (parse-csv csv-content)
            total-count (count homicides)]
        
        (println (format "Total homicides loaded: %d\n" total-count))
        
        ;; Analysis 1: Temporal Analysis
        (println (format-temporal-analysis homicides))
        
        ;; Analysis 2: Top Neighborhoods
        (println (format-neighborhood-analysis homicides))
        
        ;; Additional analyses
        (println (format-weapon-analysis homicides))
        (println (format-demographic-analysis homicides))
        
        (println "\n========================================")
        (println "Analysis complete!")
        (println "========================================\n"))
      
      (catch java.io.FileNotFoundException e
        (println (format "Error: Could not find file '%s'" csv-file))
        (println "Please ensure the CSV file is in the current directory.")
        (System/exit 1))
      (catch Exception e
        (println (format "Error during analysis: %s" (.getMessage e)))
        (System/exit 1)))))