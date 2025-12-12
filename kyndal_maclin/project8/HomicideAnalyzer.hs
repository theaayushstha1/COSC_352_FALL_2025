{-# LANGUAGE OverloadedStrings #-}

module Main where

import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Data.List (sortBy, group, sort)
import Data.Ord (comparing, Down(..))
import Data.Maybe (mapMaybe, catMaybes)
import Text.Read (readMaybe)
import Data.Char (toLower)

-- Data Types
data Homicide = Homicide
  { hNo :: Int
  , hDateDied :: T.Text
  , hName :: T.Text
  , hAge :: Maybe Int
  , hAddressBlock :: T.Text
  , hNotes :: T.Text
  , hVictimHas :: T.Text
  , hSurveillance :: T.Text
  , hCaseStatus :: T.Text
  , hSourcePage :: T.Text
  , hYear :: Int
  , hLat :: Maybe Double
  , hLon :: Maybe Double
  } deriving (Show)

data MonthCount = MonthCount
  { mcMonth :: Int
  , mcYear :: Int
  , mcCount :: Int
  } deriving (Show, Eq)

data WeaponType = WeaponType
  { wtType :: T.Text
  , wtCount :: Int
  } deriving (Show, Eq)

-- Pure Functions for Analysis

-- Parse a single CSV line into a Homicide record
parseHomicide :: T.Text -> Maybe Homicide
parseHomicide line = 
  case T.splitOn "," line of
    (no:dateDied:name:age:addrBlock:notes:victimHas:surveillance:caseStatus:sourcePage:year:lat:lon:_) ->
      Just $ Homicide
        { hNo = maybe 0 id (readMaybe $ T.unpack no)
        , hDateDied = dateDied
        , hName = name
        , hAge = readMaybe (T.unpack age)
        , hAddressBlock = addrBlock
        , hNotes = notes
        , hVictimHas = victimHas
        , hSurveillance = surveillance
        , hCaseStatus = caseStatus
        , hSourcePage = sourcePage
        , hYear = maybe 2020 id (readMaybe $ T.unpack year)
        , hLat = readMaybe (T.unpack lat)
        , hLon = readMaybe (T.unpack lon)
        }
    _ -> Nothing

-- Extract month from date string (format: M/D/YYYY)
extractMonth :: T.Text -> Maybe Int
extractMonth dateStr =
  case T.splitOn "/" dateStr of
    (month:_) -> readMaybe (T.unpack month)
    _ -> Nothing

-- Analysis 1: Count homicides by month
analyzeByMonth :: [Homicide] -> [MonthCount]
analyzeByMonth homicides =
  let monthYearPairs = mapMaybe (\h -> do
        month <- extractMonth (hDateDied h)
        return (month, hYear h)) homicides
      grouped = group . sort $ monthYearPairs
      counts = map (\g@((m,y):_) -> MonthCount m y (length g)) grouped
  in sortBy (comparing (\mc -> (mcYear mc, mcMonth mc))) counts

-- Extract weapon type from notes field
extractWeaponType :: T.Text -> T.Text
extractWeaponType notes =
  let lowerNotes = T.toLower notes
  in if T.isInfixOf "shooting" lowerNotes then "Shooting"
     else if T.isInfixOf "stabbing" lowerNotes then "Stabbing"
     else if T.isInfixOf "beating" lowerNotes then "Beating"
     else if T.isInfixOf "blunt" lowerNotes then "Blunt Force"
     else if T.isInfixOf "strangulation" lowerNotes then "Strangulation"
     else if T.isInfixOf "fire" lowerNotes then "Fire"
     else "Other/Unknown"

-- Analysis 2: Count homicides by weapon type
analyzeByWeaponType :: [Homicide] -> [WeaponType]
analyzeByWeaponType homicides =
  let weaponTypes = map (extractWeaponType . hNotes) homicides
      grouped = group . sort $ weaponTypes
      counts = map (\g@(t:_) -> WeaponType t (length g)) grouped
  in sortBy (comparing (Down . wtCount)) counts

-- Calculate percentage
percentage :: Int -> Int -> Double
percentage part total = (fromIntegral part / fromIntegral total) * 100

-- Format output functions
formatMonthlyAnalysis :: [MonthCount] -> Int -> T.Text
formatMonthlyAnalysis counts total =
  let header = "\n=== ANALYSIS 1: HOMICIDES BY MONTH ===\n\n"
      monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
      formatRow mc = 
        let monthName = if mcMonth mc > 0 && mcMonth mc <= 12 
                       then monthNames !! (mcMonth mc - 1) 
                       else "Unknown"
            pct = percentage (mcCount mc) total
        in T.pack $ monthName ++ " " ++ show (mcYear mc) ++ ": " 
           ++ show (mcCount mc) ++ " homicides (" 
           ++ show (round pct :: Int) ++ "%)\n"
      rows = T.concat $ map formatRow counts
      summary = T.pack $ "\nTotal homicides analyzed: " ++ show total ++ "\n"
  in T.concat [header, rows, summary]

formatWeaponAnalysis :: [WeaponType] -> Int -> T.Text
formatWeaponAnalysis weapons total =
  let header = "\n=== ANALYSIS 2: WEAPON TYPE DISTRIBUTION ===\n\n"
      formatRow wt =
        let pct = percentage (wtCount wt) total
            bar = T.replicate (round (pct / 2)) "█"
        in T.concat [ wtType wt, ": ", T.pack (show (wtCount wt))
                    , " (", T.pack (show (round pct :: Int)), "%) "
                    , bar, "\n" ]
      rows = T.concat $ map formatRow weapons
      summary = T.pack $ "\nTotal homicides analyzed: " ++ show total ++ "\n"
  in T.concat [header, rows, summary]

-- Main program (handles I/O)
main :: IO ()
main = do
  putStrLn "Baltimore Homicides Analyzer"
  putStrLn "================================\n"
  putStrLn "Reading CSV file..."
  
  -- Read and parse CSV
  contents <- TIO.readFile "baltimore_homicides_combined.csv"
  let allLines = T.lines contents
      dataLines = drop 1 allLines  -- Skip header
      homicides = catMaybes $ map parseHomicide dataLines
      total = length homicides
  
  putStrLn $ "Loaded " ++ show total ++ " homicide records\n"
  
  -- Perform analyses
  let monthlyData = analyzeByMonth homicides
      weaponData = analyzeByWeaponType homicides
  
  -- Display results
  TIO.putStr $ formatMonthlyAnalysis monthlyData total
  TIO.putStr $ formatWeaponAnalysis weaponData total
  
  putStrLn "\nAnalysis complete!"