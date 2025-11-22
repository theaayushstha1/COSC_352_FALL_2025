(ns homicides-analysis.core
  (:require [clojure.data.csv :as csv]
            [clojure.java.io :as io]
            [clojure.string :as str])
  (:gen-class))

(defrecord Homicide 
  [no date-died name age address notes violence-history camera case-closed year lat lon])

(defn safe-parse-int
  [s]
  (try
    (when (and s (not (str/blank? s)))
      (Integer/parseInt (str/trim s)))
    (catch Exception _ nil)))

(defn safe-parse-double
  [s]
  (try
    (when (and s (not (str/blank? s)))
      (Double/parseDouble (str/trim s)))
    (catch Exception _ nil)))

(defn clean-string
  [s]
  (if (or (nil? s) (str/blank? s))
    ""
    (str/trim s)))

(defn parse-homicide
  [row]
  (->Homicide
    (clean-string (get row "No."))
    (clean-string (get row "Date Died"))
    (clean-string (get row "Name"))
    (safe-parse-int (get row "Age"))
    (clean-string (get row "Address Block Found"))
    (clean-string (get row "Notes"))
    (clean-string (get row "Victim Has No Violent Criminal History"))
    (clean-string (get row "Surveillance Camera At Intersection"))
    (clean-string (get row "Case Closed"))
    (safe-parse-int (get row "year"))
    (safe-parse-double (get row "lat"))
    (safe-parse-double (get row "lon"))))

(defn read-csv
  [filepath]
  (with-open [reader (io/reader filepath)]
    (doall (csv/read-csv reader))))

(defn load-homicides
  [filepath]
  (let [data (read-csv filepath)
        headers (first data)
        rows (rest data)]
    (->> rows
         (map (partial zipmap headers))
         (map parse-homicide)
         (filter (fn [h] (and (:year h) (:date-died h))))
         vec)))

(defn homicides-by-year
  [homicides]
  (->> homicides
       (group-by :year)
       (map (fn [[year group]] {:year year :count (count group)}))
       (sort-by :year)))

(defn year-trend
  [homicides]
  (let [by-year (homicides-by-year homicides)
        with-change (reduce
                      (fn [acc item]
                        (if (empty? acc)
                          [item]
                          (let [prev (last acc)
                                change (- (:count item) (:count prev))
                                pct-change (if (zero? (:count prev))
                                             0.0
                                             (float (/ change (:count prev))))]
                            (conj acc (assoc item :change change :pct-change pct-change)))))
                      []
                      by-year)]
    with-change))

(defn top-neighborhoods
  [homicides n]
  (->> homicides
       (filter #(not (str/blank? (:address %))))
       (group-by :address)
       (map (fn [[neighborhood group]]
              {:neighborhood neighborhood
               :count (count group)
               :percentage (float (/ (count group) (count homicides)))}))
       (sort-by :count)
       reverse
       (take n)))

(defn case-closure-analysis
  [homicides]
  (let [closed (->> homicides
                    (filter #(= (:case-closed %) "Closed"))
                    count)
        total (count homicides)
        closure-rate (float (/ closed total))]
    {:total total
     :closed closed
     :open (- total closed)
     :closure-rate closure-rate
     :closure-percentage (* 100 closure-rate)}))

(defn camera-impact-analysis
  [homicides]
  (let [with-camera (->> homicides
                         (filter #(not (str/blank? (:camera %))))
                         count)
        total (count homicides)
        camera-rate (float (/ with-camera total))]
    {:total total
     :with-camera with-camera
     :without-camera (- total with-camera)
     :camera-rate camera-rate
     :camera-percentage (* 100 camera-rate)}))

(defn victim-age-analysis
  [homicides]
  (let [ages (->> homicides
                  (map :age)
                  (filter number?))]
    (if (empty? ages)
      {:min nil :max nil :average nil :median nil :count 0}
      (let [sorted-ages (sort ages)
            count-ages (count ages)]
        {:min (apply min ages)
         :max (apply max ages)
         :average (float (/ (apply + ages) count-ages))
         :median (nth sorted-ages (quot count-ages 2))
         :count count-ages}))))

(defn closure-by-year
  [homicides]
  (->> homicides
       (group-by :year)
       (map (fn [[year group]]
              (let [closed (->> group
                               (filter #(= (:case-closed %) "Closed"))
                               count)
                    total (count group)]
                {:year year
                 :total total
                 :closed closed
                 :open (- total closed)
                 :closure-rate (float (/ closed total))
                 :closure-percentage (* 100.0 (/ closed total))})))
       (sort-by :year)))

(defn format-trend-analysis
  [trend]
  (println "\n╔════════════════════════════════════════════════════════════╗")
  (println "║     ANALYSIS 1: HOMICIDES PER YEAR WITH TREND              ║")
  (println "╚════════════════════════════════════════════════════════════╝")
  (doseq [item trend]
    (let [change-str (if (contains? item :change)
                       (format " | Change: %+3d (%+5.1f%%)" (:change item) (* 100 (:pct-change item)))
                       "")]
      (println (format "  Year %d: %3d homicides%s" (:year item) (:count item) change-str)))))

(defn format-neighborhoods
  [neighborhoods]
  (println "\n╔════════════════════════════════════════════════════════════╗")
  (println "║   ANALYSIS 2: TOP 10 NEIGHBORHOODS BY HOMICIDE COUNT       ║")
  (println "╚════════════════════════════════════════════════════════════╝")
  (doseq [[idx item] (map-indexed vector neighborhoods)]
    (println (format "  %2d. %-40s | %3d homicides (%.1f%%)" 
                     (inc idx) 
                     (if (> (count (:neighborhood item)) 38)
                       (str (subs (:neighborhood item) 0 35) "...")
                       (:neighborhood item))
                     (:count item)
                     (* 100 (:percentage item))))))

(defn format-case-closure
  [stats]
  (println "\n╔════════════════════════════════════════════════════════════╗")
  (println "║            CASE CLOSURE RATE ANALYSIS                      ║")
  (println "╚════════════════════════════════════════════════════════════╝")
  (println (format "  Total Cases:        %d" (:total stats)))
  (println (format "  Closed:             %d" (:closed stats)))
  (println (format "  Open:               %d" (:open stats)))
  (println (format "  Closure Rate:       %.1f%%" (:closure-percentage stats))))

(defn format-camera-analysis
  [stats]
  (println "\n╔════════════════════════════════════════════════════════════╗")
  (println "║       SURVEILLANCE CAMERA PRESENCE ANALYSIS                ║")
  (println "╚════════════════════════════════════════════════════════════╝")
  (println (format "  Total Cases:        %d" (:total stats)))
  (println (format "  With Camera:        %d (%.1f%%)" (:with-camera stats) (:camera-percentage stats)))
  (println (format "  Without Camera:     %d (%.1f%%)" (:without-camera stats) (- 100 (:camera-percentage stats)))))

(defn format-age-analysis
  [stats]
  (println "\n╔════════════════════════════════════════════════════════════╗")
  (println "║           VICTIM AGE STATISTICS                            ║")
  (println "╚════════════════════════════════════════════════════════════╝")
  (if (:count stats)
    (do
      (println (format "  Valid Age Records:  %d" (:count stats)))
      (println (format "  Minimum Age:        %d years" (:min stats)))
      (println (format "  Maximum Age:        %d years" (:max stats)))
      (println (format "  Average Age:        %.1f years" (:average stats)))
      (println (format "  Median Age:         %d years" (:median stats))))
    (println "  No age data available")))

(defn format-closure-by-year
  [data]
  (println "\n╔════════════════════════════════════════════════════════════╗")
  (println "║         CASE CLOSURE RATES BY YEAR                         ║")
  (println "╚════════════════════════════════════════════════════════════╝")
  (doseq [item data]
    (println (format "  Year %d: %3d/%3d closed (%.1f%%)" 
                     (:year item) 
                     (:closed item)
                     (:total item)
                     (:closure-percentage item)))))

(defn -main
  [& args]
  (let [csv-path (or (first args) "baltimore_homicides_combined.csv")]
    (println "\n" (apply str (repeat 64 "=")))
    (println "    BALTIMORE HOMICIDES FUNCTIONAL ANALYSIS - CLOJURE")
    (println (apply str (repeat 64 "=")))
    
    (try
      (println (format "\n📊 Loading data from: %s" csv-path))
      (let [homicides (load-homicides csv-path)
            total (count homicides)]
        
        (if (zero? total)
          (println "❌ ERROR: No homicide records loaded!")
          (do
            (println (format "✓ Successfully loaded %d homicide records\n" total))
            
            (let [trend (year-trend homicides)]
              (format-trend-analysis trend))
            
            (let [top-10 (top-neighborhoods homicides 10)]
              (format-neighborhoods top-10))
            
            (let [closure-stats (case-closure-analysis homicides)]
              (format-case-closure closure-stats))
            
            (let [camera-stats (camera-impact-analysis homicides)]
              (format-camera-analysis camera-stats))
            
            (let [age-stats (victim-age-analysis homicides)]
              (format-age-analysis age-stats))
            
            (let [closure-year (closure-by-year homicides)]
              (format-closure-by-year closure-year))
            
            (println "\n" (apply str (repeat 64 "="))))))
      
      (catch Exception e
        (println (format "\n❌ ERROR: %s" (.getMessage e)))
        (println "Please ensure baltimore_homicides_combined.csv is in the current directory")
        (System/exit 1)))
    
    (println (apply str (repeat 64 "=")))
    (println "✓ Analysis complete!\n")))
