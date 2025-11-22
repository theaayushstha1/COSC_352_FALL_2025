(ns core
  (:require [clojure.data.csv :as csv]
            [clojure.java.io :as io]
            [clojure.string :as str])
  (:gen-class))

;; ============================================================================
;; DATA STRUCTURES & PARSING
;; ============================================================================

(defrecord Homicide [no date-died name age address-block notes 
                     criminal-history surveillance case-closed year])

(defn parse-csv-line
  "Parse a single CSV line into a Homicide record"
  [line]
  (when (and (seq line) (>= (count line) 10))
    (let [[no date-died name age address notes history surveillance closed year] line]
      (->Homicide no date-died name age address notes history surveillance closed year))))

(defn load-homicides
  "Load homicides from CSV file path. Returns vector of Homicide records."
  [filepath]
  (with-open [reader (io/reader filepath)]
    (->> (csv/read-csv reader)
         rest  ; Skip header
         (map parse-csv-line)
         (filter some?)
         vec)))

;; ============================================================================
;; PURE FUNCTIONAL ANALYSIS - WEAPON TYPES
;; ============================================================================

(defn extract-weapon-type
  "Pure function to extract weapon type from notes field"
  [notes]
  (cond
    (or (str/includes? (str/lower-case notes) "shooting")
        (str/includes? (str/lower-case notes) "shot")
        (str/includes? (str/lower-case notes) "gunshot"))
    "Shooting"
    
    (or (str/includes? (str/lower-case notes) "stabbing")
        (str/includes? (str/lower-case notes) "stabbed"))
    "Stabbing"
    
    (or (str/includes? (str/lower-case notes) "blunt force")
        (str/includes? (str/lower-case notes) "trauma to the body"))
    "Blunt Force"
    
    (str/includes? (str/lower-case notes) "strangled")
    "Strangulation"
    
    (str/includes? (str/lower-case notes) "set on fire")
    "Arson"
    
    (str/includes? (str/lower-case notes) "asphyxiat")
    "Asphyxiation"
    
    (str/includes? (str/lower-case notes) "overdose")
    "Drug Overdose"
    
    (str/includes? (str/lower-case notes) "cutting")
    "Cutting"
    
    :else
    "Unknown/Other"))

(defn analyze-weapon-types
  "Pure functional analysis of weapon type distribution"
  [homicides]
  (->> homicides
       (map (fn [h] (extract-weapon-type (:notes h))))
       frequencies
       (sort-by val >)
       vec))

(defn calculate-weapon-percentages
  "Calculate percentages for weapon types"
  [weapon-freq total]
  (->> weapon-freq
       (map (fn [[weapon count]]
              [weapon count (* 100.0 (/ count total))]))
       vec))

;; ============================================================================
;; PURE FUNCTIONAL ANALYSIS - NEIGHBORHOOD COMPARISONS
;; ============================================================================

(defn normalize-address
  "Normalize address for comparison"
  [address]
  (when address
    (str/trim address)))

(defn analyze-neighborhoods
  "Pure functional analysis of homicides by neighborhood/street"
  [homicides]
  (->> homicides
       (map :address-block)
       (filter some?)
       (map normalize-address)
       frequencies
       (sort-by val >)
       vec))

(defn top-n-neighborhoods
  "Get top N most dangerous neighborhoods"
  [neighborhood-freq n]
  (take n neighborhood-freq))

;; ============================================================================
;; OUTPUT FORMATTING
;; ============================================================================

(defn format-weapon-analysis
  "Format weapon type analysis for display"
  [weapon-freq total]
  (let [percentages (calculate-weapon-percentages weapon-freq total)]
    (println "\n" (str/join "=" (repeat 70 "=")))
    (println "ANALYSIS 1: WEAPON TYPE DISTRIBUTION")
    (println (str/join "=" (repeat 70 "=")))
    (println (format "\nTotal Homicides Analyzed: %d\n" total))
    (println (format "%-25s %10s %12s" "Weapon Type" "Count" "Percentage"))
    (println (str/join "-" (repeat 50 "-")))
    (doseq [[weapon count pct] percentages]
      (println (format "%-25s %10d %11.2f%%" weapon count pct)))
    (println)))

(defn format-neighborhood-analysis
  "Format neighborhood analysis for display"
  [neighborhood-freq n]
  (println "\n" (str/join "=" (repeat 70 "=")))
  (println (format "ANALYSIS 2: TOP %d MOST DANGEROUS NEIGHBORHOODS" n))
  (println (str/join "=" (repeat 70 "=")))
  (println)
  (println (format "%-3s %-45s %10s" "Rank" "Address/Location" "Homicides"))
  (println (str/join "-" (repeat 65 "-")))
  (doseq [[idx [address num]] (map-indexed vector (top-n-neighborhoods neighborhood-freq n))]
    (println (format "%-3d %-45s %10d" 
                     (inc idx) 
                     (subs (str address) 0 (min 45 (count (str address)))) 
                     num)))
  (println))

;; ============================================================================
;; MAIN PROGRAM
;; ============================================================================

(defn -main
  "Main entry point for analysis"
  [& args]
  (println "\n╔════════════════════════════════════════════════════════════════════╗")
  (println "║  Baltimore Homicides Functional Analysis (2021-2025)             ║")
  (println "║  Functional Programming Project - Clojure                          ║")
  (println "╚════════════════════════════════════════════════════════════════════╝\n")
  
  (let [csv-file "baltimore_homicides_combined.csv"]
    (try
      (println (format "Loading data from: %s..." csv-file))
      (let [homicides (load-homicides csv-file)
            total-count (count homicides)]
        
        (println (format "✓ Successfully loaded %d homicide records\n" total-count))
        
        ;; Analysis 1: Weapon Types
        (let [weapon-freq (analyze-weapon-types homicides)]
          (format-weapon-analysis weapon-freq total-count))
        
        ;; Analysis 2: Neighborhood Comparisons
        (let [neighborhood-freq (analyze-neighborhoods homicides)]
          (format-neighborhood-analysis neighborhood-freq 20))
        
        (println "\n" (str/join "=" (repeat 70 "=")))
        (println "Analysis Complete!")
        (println (str/join "=" (repeat 70 "=")))
        (println "\nKey Findings:")
        (println "  • Weapon type distribution shows primary causes of homicides")
        (println "  • Neighborhood analysis identifies high-risk areas")
        (println))
      
      (catch Exception e
        (println (format "Error: %s" (.getMessage e)))
        (println "\nMake sure 'baltimore_homicides_combined.csv' is in the current directory")
        (System/exit 1)))))