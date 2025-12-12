{-# LANGUAGE OverloadedStrings #-}

import qualified Data.ByteString.Lazy as BL
import qualified Data.Vector as V
import Data.Csv
import Data.List (foldl', sortOn, groupBy)
import Data.Function (on)
import qualified Data.Map.Strict as M

-- Define the homicide record type
data Homicide = Homicide
  { date :: !String
  , neighborhood :: !String
  , weapon :: !String
  , age :: !String
  } deriving (Show)

instance FromNamedRecord Homicide where
  parseNamedRecord r = Homicide
    <$> r .: "Date"
    <*> r .: "Neighborhood"
    <*> r .: "Weapon"
    <*> r .: "Age"

-- Pure analysis: count homicides per year
homicidesPerYear :: [Homicide] -> [(String, Int)]
homicidesPerYear = M.toList . foldl' countYear M.empty
  where
    countYear acc h =
      let yr = take 4 (date h)
      in M.insertWith (+) yr 1 acc

-- Pure analysis: top 5 neighborhoods by homicide count
topNeighborhoods :: [Homicide] -> [(String, Int)]
topNeighborhoods hs =
  take 5 . sortOn (negate . snd) . M.toList $
    foldl' (\acc h -> M.insertWith (+) (neighborhood h) 1 acc) M.empty hs

-- Main function: I/O only
main :: IO ()
main = do
  csvData <- BL.readFile "baltimore_homicides_combined.csv"
  case decodeByName csvData of
    Left err -> putStrLn $ "CSV parse error: " ++ err
    Right (_, v) -> do
      let records = V.toList v
      putStrLn "\nHomicides per Year:"
      mapM_ print (homicidesPerYear records)

      putStrLn "\nTop 5 Neighborhoods:"
      mapM_ print (topNeighborhoods records)
