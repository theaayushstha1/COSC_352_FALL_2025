{-
  Baltimore Homicides Analysis - Functional Programming Assignment
  COSC 352 Fall 2025 - Project 8
-}

module Main where

import Data.List (sortBy, maximumBy)
import Data.Ord (comparing)
import Data.Char (isDigit, toLower)
import Data.Maybe (mapMaybe, catMaybes)
import Text.Printf (printf)
import System.Environment (getArgs)

data Homicide = Homicide
  { victimNumber     :: Int
  , victimName       :: String
  , victimSex        :: String
  , victimAge        :: Maybe Int
  , address          :: String
  , notes            :: String
  , noViolentHistory :: Bool
  , cameraPresent    :: Bool
  , caseStatus       :: String
  , reportYear       :: Int
  , reportMonth      :: Int
  } deriving (Show, Eq)

data YearStats = YearStats
  { yearVal     :: Int
  , totalCount  :: Int
  , openCount   :: Int
  , closedCount :: Int
  , solveRate   :: Double
  } deriving (Show)

data AgeGroupStats = AgeGroupStats
  { ageGroup      :: String
  , ageGroupTotal :: Int
  , ageGroupOpen  :: Int
  , ageGroupRate  :: Double
  } deriving (Show)

parseField :: String -> (String, String)
parseField [] = ("", "")
parseField ('"':rest) = 
  let (field, remainder) = parseQuoted rest
  in (field, dropWhile (== ',') remainder)
parseField str = 
  let (field, remainder) = break (== ',') str
  in (field, drop 1 remainder)

parseQuoted :: String -> (String, String)
parseQuoted [] = ("", "")
parseQuoted ('"':'"':rest) = 
  let (field, remainder) = parseQuoted rest
  in ('"':field, remainder)
parseQuoted ('"':rest) = ("", rest)
parseQuoted (c:rest) = 
  let (field, remainder) = parseQuoted rest
  in (c:field, remainder)

parseCSVLine :: String -> [String]
parseCSVLine [] = []
parseCSVLine str = 
  let (field, rest) = parseField str
  in field : if null rest then [] else parseCSVLine rest

safeReadInt :: String -> Maybe Int
safeReadInt s = 
  let cleaned = filter isDigit s
  in if null cleaned then Nothing else Just (read cleaned)

parseMonth :: String -> Int
parseMonth dateStr = 
  case safeReadInt (takeWhile (/= '/') dateStr) of
    Just m  -> if m >= 1 && m <= 12 then m else 1
    Nothing -> 1

parseHomicide :: [String] -> Maybe Homicide
parseHomicide fields
  | length fields >= 10 = Just Homicide
      { victimNumber     = maybe 0 id $ safeReadInt (fields !! 0)
      , victimName       = fields !! 1
      , victimSex        = fields !! 2
      , victimAge        = safeReadInt (fields !! 3)
      , address          = fields !! 4
      , notes            = fields !! 5
      , noViolentHistory = map toLower (fields !! 6) `elem` ["yes", "y", "true", "1"]
      , cameraPresent    = map toLower (fields !! 7) `elem` ["yes", "y", "true", "1"]
      , caseStatus       = fields !! 8
      , reportYear       = maybe 2024 id $ safeReadInt (fields !! 9)
      , reportMonth      = if length fields > 10 then parseMonth (fields !! 10) else 1
      }
  | otherwise = Nothing

parseCSV :: String -> [Homicide]
parseCSV content = 
  let rows = drop 1 $ lines content
      parsed = map parseCSVLine rows
  in mapMaybe parseHomicide parsed

calculateSolveRate :: Int -> Int -> Double
calculateSolveRate closed total
  | total == 0 = 0.0
  | otherwise  = (fromIntegral closed / fromIntegral total) * 100.0

isClosed :: Homicide -> Bool
isClosed h = map toLower (caseStatus h) == "closed"

groupByYear :: [Homicide] -> [(Int, [Homicide])]
groupByYear = foldr insertByYear []
  where
    insertByYear h [] = [(reportYear h, [h])]
    insertByYear h ((y, hs):rest)
      | reportYear h == y = (y, h:hs) : rest
      | otherwise         = (y, hs) : insertByYear h rest

calculateYearStats :: (Int, [Homicide]) -> YearStats
calculateYearStats (year, homicides) =
  let total  = length homicides
      closed = length $ filter isClosed homicides
      open   = total - closed
      rate   = calculateSolveRate closed total
  in YearStats year total open closed rate

analyzeByYear :: [Homicide] -> [YearStats]
analyzeByYear homicides =
  let grouped = groupByYear homicides
      stats   = map calculateYearStats grouped
  in sortBy (comparing yearVal) stats

calculateTrend :: [YearStats] -> [(Int, Int, String)]
calculateTrend [] = []
calculateTrend [_] = []
calculateTrend (s1:s2:rest) =
  let change = totalCount s2 - totalCount s1
      trend  = if change > 0 then "[UP] +" ++ show change
               else if change < 0 then "[DOWN] " ++ show change
               else "[SAME] 0"
  in (yearVal s2, totalCount s2, trend) : calculateTrend (s2:rest)

ageToGroup :: Maybe Int -> String
ageToGroup Nothing  = "Unknown"
ageToGroup (Just age)
  | age < 18   = "Under 18"
  | age < 25   = "18-24"
  | age < 35   = "25-34"
  | age < 45   = "35-44"
  | age < 55   = "45-54"
  | otherwise  = "55+"

groupByAgeGroup :: [Homicide] -> [(String, [Homicide])]
groupByAgeGroup homicides =
  let groups = ["Under 18", "18-24", "25-34", "35-44", "45-54", "55+", "Unknown"]
  in [(g, [h | h <- homicides, ageToGroup (victimAge h) == g]) | g <- groups]

calculateAgeStats :: (String, [Homicide]) -> AgeGroupStats
calculateAgeStats (grp, homicides) =
  let total  = length homicides
      open   = length $ filter (not . isClosed) homicides
      rate   = calculateSolveRate (total - open) total
  in AgeGroupStats grp total open rate

analyzeByAge :: [Homicide] -> [AgeGroupStats]
analyzeByAge homicides =
  let grouped = groupByAgeGroup homicides
      stats   = map calculateAgeStats grouped
  in filter (\s -> ageGroupTotal s > 0) stats

averageAge :: [Homicide] -> Double
averageAge homicides =
  let ages = catMaybes $ map victimAge homicides
      total = sum ages
      count = length ages
  in if count == 0 then 0 else fromIntegral total / fromIntegral count

mostCommonAgeGroup :: [AgeGroupStats] -> String
mostCommonAgeGroup [] = "N/A"
mostCommonAgeGroup stats = ageGroup $ maximumBy (comparing ageGroupTotal) stats

formatYearStats :: YearStats -> String
formatYearStats s = printf "  %d    |    %4d    |    %4d   |   %4d   |  %5.1f%%"
  (yearVal s) (totalCount s) (openCount s) (closedCount s) (solveRate s)

formatTrend :: (Int, Int, String) -> String
formatTrend (year, count, trend) = printf "  %d -> %d  (%s)" year count trend

formatAgeStats :: AgeGroupStats -> String
formatAgeStats s = printf "  %-12s |   %4d   |   %4d   |  %5.1f%%"
  (ageGroup s) (ageGroupTotal s) (ageGroupOpen s) (ageGroupRate s)

myUnless :: Bool -> IO () -> IO ()
myUnless True  _ = return ()
myUnless False a = a

printYearAnalysis :: [YearStats] -> IO ()
printYearAnalysis stats = do
  putStrLn ""
  putStrLn "+======================================================================+"
  putStrLn "|        ANALYSIS 1: Homicides Per Year with Trend Analysis            |"
  putStrLn "+======================================================================+"
  putStrLn ""
  putStrLn "  +--------------------------------------------------------------+"
  putStrLn "  |  Year   |   Total   |   Open   |  Closed  |  Solve Rate      |"
  putStrLn "  +--------------------------------------------------------------+"
  mapM_ (putStrLn . ("  |" ++) . (++ " |")) $ map formatYearStats stats
  putStrLn "  +--------------------------------------------------------------+"
  putStrLn ""
  let trends = calculateTrend stats
  myUnless (null trends) $ do
    putStrLn "  Year-Over-Year Trend:"
    putStrLn "  ----------------------"
    mapM_ (putStrLn . formatTrend) trends
    putStrLn ""
  let totalHomicides = foldr (\s acc -> totalCount s + acc) 0 stats
      totalClosed = foldr (\s acc -> closedCount s + acc) 0 stats
      overallRate = calculateSolveRate totalClosed totalHomicides
  putStrLn $ printf "  Summary: %d total homicides across %d years" totalHomicides (length stats)
  putStrLn $ printf "           Overall solve rate: %.1f%%" overallRate
  putStrLn ""

printAgeAnalysis :: [AgeGroupStats] -> Double -> IO ()
printAgeAnalysis stats avgAge = do
  putStrLn ""
  putStrLn "+======================================================================+"
  putStrLn "|       ANALYSIS 2: Victim Age Demographics and Patterns               |"
  putStrLn "+======================================================================+"
  putStrLn ""
  putStrLn "  +------------------------------------------------------------+"
  putStrLn "  |  Age Group   |  Total  |   Open   |  Solve Rate            |"
  putStrLn "  +------------------------------------------------------------+"
  mapM_ (putStrLn . ("  |" ++) . (++ " |")) $ map formatAgeStats stats
  putStrLn "  +------------------------------------------------------------+"
  putStrLn ""
  putStrLn "  Demographic Insights:"
  putStrLn "  ----------------------"
  putStrLn $ printf "  * Average victim age: %.1f years" avgAge
  putStrLn $ printf "  * Most affected age group: %s" (mostCommonAgeGroup stats)
  let knownStats = filter (\s -> ageGroup s /= "Unknown" && ageGroupTotal s > 5) stats
  myUnless (null knownStats) $ do
    let highestRate = maximumBy (comparing ageGroupRate) knownStats
    putStrLn $ printf "  * Highest solve rate: %s (%.1f%%)" (ageGroup highestRate) (ageGroupRate highestRate)
  putStrLn ""

main :: IO ()
main = do
  args <- getArgs
  let csvFile = if null args then "baltimore_homicides_combined.csv" else head args
  putStrLn ""
  putStrLn "+======================================================================+"
  putStrLn "|              BALTIMORE HOMICIDES ANALYSIS - HASKELL                  |"
  putStrLn "|                   COSC 352 - Project 8                               |"
  putStrLn "|                                                                      |"
  putStrLn "|  Pure Functional Implementation using:                               |"
  putStrLn "|  * Immutable data structures    * Pattern matching                   |"
  putStrLn "|  * map, filter, fold            * List comprehensions                |"
  putStrLn "+======================================================================+"
  content <- readFile csvFile
  let homicides = parseCSV content
  putStrLn ""
  putStrLn $ printf "  Loaded %d homicide records from %s" (length homicides) csvFile
  let yearStats = analyzeByYear homicides
  printYearAnalysis yearStats
  let ageStats = analyzeByAge homicides
      avgVictimAge = averageAge homicides
  printAgeAnalysis ageStats avgVictimAge
  putStrLn "========================================================================"
  putStrLn "  Analysis complete. All computations performed using pure functions."
  putStrLn "========================================================================"