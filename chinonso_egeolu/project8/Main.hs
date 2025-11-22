{-# LANGUAGE OverloadedStrings #-}

module Main where

import qualified Data.ByteString.Lazy as BL
import Data.Csv
import qualified Data.Vector as V
import qualified Data.Map as Map
import Data.List (sortBy)
import Data.Ord (comparing, Down(..))

-- Data type for a homicide record
data Homicide = Homicide
  { hYear     :: Int
  , hLocation :: String
  , hAge      :: String
  } deriving (Show)

-- Parse CSV using actual column names
instance FromNamedRecord Homicide where
  parseNamedRecord r = Homicide
    <$> r .: "year"
    <*> r .: "Address Block Found"
    <*> r .: "Age"

-- ANALYSIS 1: Count homicides per year using fold
countByYear :: [Homicide] -> [(Int, Int)]
countByYear homicides = 
  let counts = foldr addYear Map.empty homicides
  in sortBy (comparing fst) $ Map.toList counts
  where
    addYear h m = Map.insertWith (+) (hYear h) 1 m

-- Calculate year over year change using pattern matching
yearOverYear :: [(Int, Int)] -> [(Int, Int)]
yearOverYear [] = []
yearOverYear [_] = []
yearOverYear ((y1,c1):(y2,c2):rest) = 
  (y2, c2 - c1) : yearOverYear ((y2,c2):rest)

-- ANALYSIS 2: Find top locations using filter and fold
topLocations :: Int -> [Homicide] -> [(String, Int)]
topLocations n homicides =
  let filtered = filter (\h -> hLocation h /= "") homicides
      counts = foldr addLocation Map.empty filtered
      sorted = sortBy (comparing (Down . snd)) $ Map.toList counts
  in take n sorted
  where
    addLocation h m = Map.insertWith (+) (hLocation h) 1 m

-- Load CSV data
loadData :: FilePath -> IO (Either String [Homicide])
loadData path = do
  csv <- BL.readFile path
  case decodeByName csv of
    Left err -> return $ Left err
    Right (_, v) -> return $ Right (V.toList v)

-- Display yearly analysis
printYears :: [(Int, Int)] -> [(Int, Int)] -> IO ()
printYears counts changes = do
  putStrLn "\n=== ANALYSIS 1: Homicides by Year ==="
  putStrLn ""
  mapM_ (\(y, c) -> putStrLn $ show y ++ ": " ++ show c) counts
  putStrLn "\nYear-over-Year Change:"
  mapM_ (\(y, change) -> 
    putStrLn $ show y ++ ": " ++ showChange change) changes
  where
    showChange c 
      | c > 0 = "+" ++ show c ++ " (increase)"
      | c < 0 = show c ++ " (decrease)"
      | otherwise = "no change"

-- Display top locations
printLocations :: [(String, Int)] -> IO ()
printLocations locs = do
  putStrLn "\n=== ANALYSIS 2: Top 10 Locations ==="
  putStrLn ""
  mapM_ (\(i, (loc, count)) -> 
    putStrLn $ show i ++ ". " ++ loc ++ ": " ++ show count) 
    (zip [1..] locs)

main :: IO ()
main = do
  putStrLn "Loading data..."
  result <- loadData "baltimore_homicides_combined.csv"
  
  case result of
    Left err -> putStrLn $ "Error: " ++ err
    Right records -> do
      putStrLn $ "Loaded " ++ show (length records) ++ " records"
      
      let yearly = countByYear records
          changes = yearOverYear yearly
      printYears yearly changes
      
      let top10 = topLocations 10 records
      printLocations top10
      
      putStrLn "\nDone!"