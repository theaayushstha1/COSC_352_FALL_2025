(ns homicide-tool.core
  (:require [clojure.string :as str]
            [clojure.java.io :as io]))

;; --- Helpers ---
(defn safe-parse-int [s]
  (try
    (when (and s (not (str/blank? s)))
      (Integer/parseInt s))
    (catch Exception _ nil)))

(defn normalize-weapon [w]
  (cond
    (nil? w) "Unknown"
    (re-find #"(?i)shoot" w) "Firearm"
    (re-find #"(?i)stab" w) "Stabbing"
    (re-find #"(?i)blunt|assault" w) "Blunt Object"
    (re-find #"(?i)strangle|choke" w) "Strangulation"
    :else "Other"))

;; --- Data & Types ---
(defn parse-line [line]
  ;; CSV columns: Case,Date,Victim Name,Age,Address,Cause/Weapon,Notes,...,Link,Year,Lat,Lon
  (let [[case-num date name age address weapon & more] (str/split line #"," -1)]
    (if (and date (str/includes? date "/"))
      (let [[month day year-str] (str/split date #"/")]
        {:case case-num
         :date date
         :year (safe-parse-int year-str)
         :month (safe-parse-int month)
         :victim-name (or name "Unknown")
         :victim-age (safe-parse-int age)
         :address (or address "Unknown")
         :weapon-raw (or weapon "Unknown")
         :weapon (normalize-weapon weapon)})
      ;; fallback if date is missing or malformed
      {:case case-num
       :date (or date "Unknown")
       :year nil
       :month nil
       :victim-name (or name "Unknown")
       :victim-age (safe-parse-int age)
       :address (or address "Unknown")
       :weapon-raw (or weapon "Unknown")
       :weapon (normalize-weapon weapon)})))

(defn load-data [filename]
  (with-open [rdr (io/reader filename)]
    (doall
      (map parse-line (rest (line-seq rdr)))))) ; skip header row

;; --- Analysis 1: Seasonal homicide distribution ---
(defn month->season [month]
  (cond
    (nil? month) "Unknown"
    (#{12 1 2} month) "Winter"
    (#{3 4 5} month) "Spring"
    (#{6 7 8} month) "Summer"
    (#{9 10 11} month) "Fall"
    :else "Unknown"))

(defn homicides-by-season [records]
  (->> records
       (map #(month->season (:month %)))
       (frequencies)
       (sort-by key)))

;; --- Analysis 2: Average victim age by weapon type ---
(defn avg [nums]
  (if (seq nums)
    (/ (reduce + nums) (count nums))
    0.0))

(defn avg-age-by-weapon [records]
  (->> records
       (filter :victim-age)
       (group-by :weapon) ;; use normalized weapon
       (map (fn [[w hs]]
              [w (avg (map :victim-age hs))]))
       (sort-by second >)))

;; --- Main Program ---
(defn -main [& args]
  (let [data (load-data "baltimore_homicides_combined.csv")]
    (println "Homicides by Season:")
    (doseq [[season cnt] (homicides-by-season data)]
      (println season ":" cnt))

    (println "\nAverage Victim Age by Weapon:")
    (doseq [[weapon age] (avg-age-by-weapon data)]
      (println weapon ":" (format "%.1f" (double age))))))