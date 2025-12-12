module Analysis where

import Homicide
import Data.List (sortBy, group, sort)
import Data.Ord (comparing, Down(..))
import qualified Data.Map.Strict as Map
import qualified Data.Text as T

-- Analysis 1: Count homicides per year
homicidesPerYear :: [Homicide] -> [(Int, Int)]
homicidesPerYear homicides =
  let years = map homicideYear homicides
      yearCounts = Map.toList $ Map.fromListWith (+) [(year, 1) | year <- years]
  in sortBy (comparing fst) yearCounts

-- Analysis 2: Top N addresses by homicide count
topAddresses :: Int -> [Homicide] -> [(String, Int)]
topAddresses n homicides =
  let addresses = map (T.unpack . homicideAddressBlock) homicides
      addressCounts = Map.fromListWith (+) [(addr, 1) | addr <- addresses, not (null addr)]
      sorted = sortBy (comparing (Down . snd)) (Map.toList addressCounts)
  in take n sorted

-- Helper: Format results for display
formatYearData :: [(Int, Int)] -> String
formatYearData yearData =
  unlines $ "Year | Count" : "-----+-------" : map formatRow yearData
  where
    formatRow (year, count) = show year ++ " | " ++ show count

formatAddressData :: [(String, Int)] -> String
formatAddressData addrData =
  unlines $ "Address Block | Count" : "--------------+-------" : map formatRow addrData
  where
    formatRow (addr, count) = addr ++ " | " ++ show count