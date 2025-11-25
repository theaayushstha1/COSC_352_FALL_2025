(ns baltimore-homicides.core
  (:require [clojure.string :as str]
            [clojure.java.io :as io])
  (:gen-class))



;; Type definition for Homicide record
(defrecord Homicide [date year month day age name address notes])

;; Pure function: Parse a single CSV row into a Homicide record
(defn parse-homicide-row
  "Parses a CSV row into a Homicide record. Returns nil for invalid rows."
  [row]
  (try
    (let [[no date-str name age-str address notes & _] row
          ;; Handle date format MM/DD/YY
          date-parts (str/split date-str #"/")
          month (Integer/parseInt (first date-parts))
          day (Integer/parseInt (second date-parts))
          year-short (Integer/parseInt (nth date-parts 2))
          ;; Convert 2-digit year to 4-digit (20 -> 2020)
          year (+ 2000 year-short)
          ;; Parse age, handling cases like "26, pic" or just "26"
          age-cleaned (-> age-str
                          str/trim
                          (str/split #",")
                          first
                          str/trim)
          age (when (and age-cleaned (not (str/blank? age-cleaned)))
                (try (Integer/parseInt age-cleaned)
                     (catch Exception _ nil)))]
      (->Homicide date-str year month day age name address notes))
    (catch Exception _ nil)))

;; Pure function: Parse CSV string into homicide records
(defn parse-csv
  "Parses CSV content into a sequence of Homicide records."
  [csv-content]
  (->> (str/split-lines csv-content)
       (drop 1) ; Skip header
       (map #(str/split % #","))
       (map parse-homicide-row)
       (remove nil?)))



;; Analysis 1: Homicides per year
(defn homicides-per-year
  "Counts homicides per year using reduce."
  [homicides]
  (->> homicides
       (map :year)
       (reduce (fn [acc year]
                 (update acc year (fnil inc 0)))
               {})
       (sort-by first)))

;; Analysis 2: Homicides per month (across all years)
(defn homicides-per-month
  "Counts homicides per month using group-by and map."
  [homicides]
  (->> homicides
       (map :month)
       (reduce (fn [acc month]
                 (update acc month (fnil inc 0)))
               {})
       (sort-by first)))

;; Analysis 3: Simple trend analysis using fold
(defn calculate-trend
  "Calculates year-over-year trend using reduce to fold over sorted years."
  [year-counts]
  (let [sorted-years (sort-by first year-counts)
        years (map first sorted-years)
        counts (map second sorted-years)]
    (if (< (count counts) 2)
      {:trend "insufficient-data" :change 0}
      (let [first-year-count (first counts)
            last-year-count (last counts)
            total-change (- last-year-count first-year-count)
            avg-change (/ total-change (dec (count counts)))
            trend-direction (cond
                              (pos? avg-change) "increasing"
                              (neg? avg-change) "decreasing"
                              :else "stable")]
        {:trend trend-direction
         :avg-change-per-year (double avg-change)
         :total-change total-change
         :first-year (first years)
         :last-year (last years)
         :first-count first-year-count
         :last-count last-year-count}))))

;; Analysis 4: Weapon-type distribution using reduce and map
(defn weapon-type-distribution
  "Analyzes weapon types used in homicides by parsing notes field."
  [homicides]
  (let [;; Extract weapon keywords from notes
        extract-weapon (fn [notes]
                        (when notes
                          (let [notes-lower (str/lower-case notes)]
                            (cond
                              (re-find #"shoot|shot|gun|firearm" notes-lower) "Shooting"
                              (re-find #"stab" notes-lower) "Stabbing"
                              (re-find #"blunt|beat|assault" notes-lower) "Blunt Force"
                              (re-find #"strangle|chok" notes-lower) "Strangulation"
                              (re-find #"vehicle|hit-and-run|struck" notes-lower) "Vehicle"
                              :else "Other/Unknown"))))
        weapons (->> homicides
                     (map :notes)
                     (map extract-weapon)
                     (remove nil?))
        weapon-counts (->> weapons
                          (reduce (fn [acc weapon]
                                    (update acc weapon (fnil inc 0)))
                                  {}))
        total-count (count weapons)
        sorted-weapons (->> weapon-counts
                           (sort-by second >))]
    {:weapons sorted-weapons
     :total total-count
     :breakdown (map (fn [[weapon count]]
                       [weapon count (double (* 100 (/ count total-count)))])
                     sorted-weapons)}))

;; Analysis 5: Age distribution using filter and map
(defn age-distribution
  "Analyzes age distribution by decade using filter and map."
  [homicides]
  (let [ages (->> homicides
                  (map :age)
                  (remove nil?))
        age-ranges {"0-17" [0 17]
                    "18-25" [18 25]
                    "26-35" [26 35]
                    "36-45" [36 45]
                    "46-55" [46 55]
                    "56+" [56 200]}
        in-range? (fn [age [min-age max-age]]
                    (and (>= age min-age) (<= age max-age)))]
    (->> age-ranges
         (map (fn [[range-name [min-age max-age]]]
                [range-name
                 (count (filter #(in-range? % [min-age max-age]) ages))]))
         (into {})
         (sort-by second >))))

;; Pure function: Format monthly trend with names
(defn format-monthly-data
  "Formats monthly data with month names."
  [month-counts]
  (let [month-names {1 "January" 2 "February" 3 "March" 4 "April"
                     5 "May" 6 "June" 7 "July" 8 "August"
                     9 "September" 10 "October" 11 "November" 12 "December"}]
    (->> month-counts
         (map (fn [[month count]]
                [(get month-names month (str "Month-" month)) count]))
         (sort-by second >))))

;; 

(defn read-csv-file
  "Reads CSV file from filesystem. I/O function."
  [filepath]
  (slurp filepath))

(defn print-results
  "Prints analysis results. I/O function."
  [homicides]
  (println "\n" (str (repeat 70 "=")) "\n")
  (println "BALTIMORE HOMICIDES FUNCTIONAL ANALYSIS")
  (println (str (repeat 70 "=")) "\n")
  
  (println "Total homicides in dataset:" (count homicides))
  (println)
  
  ;; Analysis 1: Homicides per year
  (println "━━━ HOMICIDES PER YEAR ━━━")
  (let [year-counts (homicides-per-year homicides)]
    (doseq [[year count] year-counts]
      (println (format "%d: %4d homicides" year count))))
  (println)
  
  ;; Trend analysis
  (println "━━━ TREND ANALYSIS ━━━")
  (let [year-counts (homicides-per-year homicides)
        trend (calculate-trend year-counts)]
    (if (= (:trend trend) "insufficient-data")
      (println "Insufficient data for trend analysis")
      (do
        (println (format "Trend: %s" (str/upper-case (:trend trend))))
        (println (format "Period: %d to %d" (:first-year trend) (:last-year trend)))
        (println (format "Change: %d → %d (total change: %+d)"
                        (:first-count trend)
                        (:last-count trend)
                        (:total-change trend)))
        (println (format "Average change per year: %+.1f homicides"
                        (:avg-change-per-year trend))))))
  (println)
  
  ;; Analysis 2: Homicides per month
  (println "━━━ HOMICIDES PER MONTH (All Years Combined) ━━━")
  (let [month-counts (homicides-per-month homicides)
        formatted (format-monthly-data month-counts)]
    (doseq [[month-name count] formatted]
      (println (format "%-10s: %4d homicides" month-name count))))
  (println)
  
  ;; Analysis 3: Weapon-type distribution
  (println "━━━ WEAPON-TYPE DISTRIBUTION ━━━")
  (let [weapon-result (weapon-type-distribution homicides)
        breakdown (:breakdown weapon-result)]
    (println (format "Total homicides analyzed: %d" (:total weapon-result)))
    (println)
    (doseq [[weapon count percentage] breakdown]
      (println (format "%-20s: %4d victims (%.1f%%)" weapon count percentage))))
  (println)
  
  ;; Age distribution
  (println "━━━ AGE DISTRIBUTION ━━━")
  (let [dist (age-distribution homicides)]
    (doseq [[range count] dist]
      (println (format "%-10s: %4d victims" range count))))
  (println)
  (println (str (repeat 70 "=")) "\n"))



(defn -main
  [& args]
  (let [filepath (or (first args) "baltimore_homicides_combined.csv")]
    (try
      (println "Reading CSV file:" filepath)
      (let [csv-content (read-csv-file filepath)
            homicides (parse-csv csv-content)]
        (if (empty? homicides)
          (println "Error: No valid homicide records found in file.")
          (print-results homicides)))
      (catch Exception e
        (println "Error reading file:" (.getMessage e))
        (println "Usage: java -jar baltimore-homicides.jar [path-to-csv]")
        (System/exit 1)))))