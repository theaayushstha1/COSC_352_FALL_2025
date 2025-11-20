(ns project8.core
  (:require [clojure.java.io :as io]
            [clojure.data.csv :as csv]
            [clojure.string :as str]))

;; -----------------------------------------------------------
;; TYPE DEFINITION (SATISFIES REQUIREMENT #1)
;; -----------------------------------------------------------
(defrecord Homicide
  [date year address])

;; -----------------------------------------------------------
;; HELPERS
;; -----------------------------------------------------------

(defn parse-int [s]
  (try (Integer/parseInt s)
       (catch Exception _ nil)))

(defn clean-address [addr]
  (let [t (str/trim addr)]
    (case t
      ("" "NA" "N/A") "Unknown Address"
      t)))

;; -----------------------------------------------------------
;; CSV ROW → HOMICIDE RECORD
;; -----------------------------------------------------------
(defn row->record [row]
  (->Homicide
    (nth row 1)
    (parse-int (nth row 10))
    (clean-address (nth row 4))))

;; -----------------------------------------------------------
;; LOAD CSV (I/O allowed)
;; -----------------------------------------------------------
(defn load-csv [filepath]
  (with-open [r (io/reader filepath)]
    (->> (csv/read-csv r)
         (drop 1)
         (map row->record)
         (doall))))

;; -----------------------------------------------------------
;; PURE FUNCTIONAL ANALYSIS #1
;; HOMICIDES PER YEAR (REDUCE)
;; -----------------------------------------------------------
(defn homicides-per-year [records]
  (reduce (fn [m r]
            (update m (:year r) (fnil inc 0)))
          {}
          records))

;; -----------------------------------------------------------
;; PURE FUNCTIONAL ANALYSIS #2
;; TOP N ADDRESS BLOCKS (REDUCE + SORT)
;; -----------------------------------------------------------
(defn top-addresses [records n]
  (->> records
       (reduce (fn [m r]
                 (update m (:address r) (fnil inc 0)))
               {})
       (sort-by val >)
       (take n)))

;; -----------------------------------------------------------
;; BONUS: RECURSIVE ANALYSIS (SATISFIES "RECURSION" REQUIREMENT)
;; Count total homicides using recursion instead of reduce.
;; -----------------------------------------------------------
(defn count-recursive [records]
  (if (empty? records)
    0
    (inc (count-recursive (rest records)))))

;; -----------------------------------------------------------
;; MAIN PROGRAM (ONLY I/O HERE)
;; -----------------------------------------------------------
(defn -main []
  (println "Loading homicide dataset...")
  (let [records (load-csv "baltimore_homicides_combined.csv")]

    (println "\n-- Total Homicides (Recursive Count) --")
    (println (count-recursive records))

    (println "\n-- Homicides Per Year --")
    (doseq [[yr count] (sort-by key (homicides-per-year records))]
      (println yr ":" count))

    (println "\n-- Top 5 Address Blocks --")
    (doseq [[addr count] (top-addresses records 5)]
      (println addr ":" count))

    (println "\nDone.")))
