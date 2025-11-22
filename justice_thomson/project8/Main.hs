-- Main.hs

import Data.List (groupBy, sortBy, sortOn, isInfixOf)
import Data.Function (on)
import Data.Char (toLower)
import System.IO (readFile)
import Data.Maybe (catMaybes)

data Homicide = Homicide {
  no :: String,
  dateDied :: String,
  name :: String,
  age :: String,
  address :: String,
  notes :: String,
  history :: String,
  camera :: String,
  caseClosed :: String,
  sourcePage :: String,
  year :: Int,
  lat :: Double,
  lon :: Double
} deriving (Show)

-- Simple CSV parser handling quoted fields with commas
parseCSV :: String -> [[String]]
parseCSV input = map parseLine (lines input)

parseLine :: String -> [String]
parseLine s = parseFields s []
 where
  parseFields :: String -> [String] -> [String]
  parseFields "" acc = reverse acc
  parseFields (',' : rest) acc = parseFields rest ("" : acc)
  parseFields ('"' : rest) acc = let (field, rest') = parseQuoted rest "" in parseFields rest' (field : acc)
  parseFields str acc = let (field, rest) = break (== ',') str in parseFields (dropWhile (== ',') rest) (field : acc)

  parseQuoted :: String -> String -> (String, String)
  parseQuoted "" acc = (reverse acc, "")
  parseQuoted ('"' : '"' : rest) acc = parseQuoted rest ('"' : acc)
  parseQuoted ('"' : rest) acc = (reverse acc, rest)
  parseQuoted (c : rest) acc = parseQuoted rest (c : acc)

makeHomicide :: [String] -> Maybe Homicide
makeHomicide [n, d, nm, a, ad, nt, h, c, cc, sp, y, la, lo] =
  case (reads y, reads la, reads lo) of
    ([(yr, "")], [(lt, "")], [(ln, "")]) -> Just $ Homicide n d nm a ad nt h c cc sp yr lt ln
    _ -> Nothing
makeHomicide _ = Nothing

-- Pure function for homicides per year
homicidesPerYear :: [Homicide] -> [(Int, Int)]
homicidesPerYear hs =
  let sorted = sortBy (comparing year) hs
      grouped = groupBy ((==) `on` year) sorted
  in map (\g -> (year (head g), length g)) grouped

-- Pure function for type distribution
classifyType :: Homicide -> String
classifyType h
  | "shooting" `isInfixOf` lowerNotes = "Shooting"
  | "stabbing" `isInfixOf` lowerNotes = "Stabbing"
  | otherwise = "Other"
  where lowerNotes = map toLower (notes h)

typeDistribution :: [Homicide] -> [(String, Int)]
typeDistribution hs =
  let types = map classifyType hs
      sortedTypes = sortOn id types
      grouped = groupBy (==) sortedTypes
  in map (\g -> (head g, length g)) grouped

main :: IO ()
main = do
  content <- readFile "baltimore_homicides_combined.csv"
  let rows = tail $ parseCSV content  -- skip header
  let homicides = catMaybes $ map makeHomicide rows
  putStrLn "Homicides per year:"
  mapM_ print (homicidesPerYear homicides)
  putStrLn "\nType distribution (Shooting, Stabbing, Other):"
  mapM_ print (typeDistribution homicides)