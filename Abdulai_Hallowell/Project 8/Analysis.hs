module Analysis
  ( homicidesPerYear
  , topNeighborhoods
  ) where

import Data.List (sortBy)
import Data.Ord (comparing)
import Types

-- | Count homicides per year using folds and recursion.
homicidesPerYear :: [Homicide] -> [(Int, Int)]
homicidesPerYear hs =
  sortBy (comparing fst) (foldl addYear [] hs)
  where
    addYear counts h = increment (year h) counts

-- | Top N address clusters (treated as neighborhoods) by frequency.
topNeighborhoods :: Int -> [Homicide] -> [(String, Int)]
topNeighborhoods n hs =
  take n (sortBy compareCount (foldl addAddress [] hs))
  where
    addAddress counts h = increment (addressBlock h) counts
    compareCount (aAddr, aTotal) (bAddr, bTotal) =
      compare bTotal aTotal <> compare aAddr bAddr

-- | Increment associative list frequency using explicit recursion.
increment :: (Eq a) => a -> [(a, Int)] -> [(a, Int)]
increment key [] = [(key, 1)]
increment key ((k, v) : rest)
  | key == k = (k, v + 1) : rest
  | otherwise = (k, v) : increment key rest
