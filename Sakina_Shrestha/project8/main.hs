{-# LANGUAGE OverloadedStrings #-}

import Data.List (foldl', sortOn)
import qualified Data.Map.Strict as Map
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import qualified Data.Text.Read as TR
import Data.Maybe (fromMaybe, mapMaybe)
import Control.Monad (when)

-- Define Homicide record type
data Homicide = Homicide
  { no :: Int
  , dateDied :: T.Text
  , name :: T.Text
  , age :: Maybe Int
  , addressBlockFound :: T.Text
  , notes :: T.Text
  , victimNoViolentCriminalHistory :: Bool
  , surveillanceCameraAtIntersection :: Bool
  , caseClosed :: Bool
  , year :: Int
  , weaponType :: T.Text
  } deriving (Show)

-- Parse a CSV line into Homicide record
parseHomicide :: T.Text -> Maybe Homicide
parseHomicide line =
  case splitCSV line of
    (noTxt:date:nameTxt:ageTxt:addr:notesTxt:vnc:cam:closed:_:yearTxt:_) ->
      let tryParseInt t = case TR.decimal t of
            Right (n, _) -> Just n
            _ -> Nothing
          no' = fromMaybe (-1) (tryParseInt noTxt)
          age' = tryParseInt (T.filter (`elem` ['0'..'9']) ageTxt)
          year' = fromMaybe (-1) (tryParseInt yearTxt)
          vncBool = T.toLower vnc == "none" || vnc == ""
          camBool = cam == "1" || T.toLower cam == "true"
          closedBool = T.toLower closed == "closed"
          weapon = extractWeapon notesTxt
      in Just $ Homicide no' date nameTxt age' addr notesTxt vncBool camBool closedBool year' weapon
    _ -> Nothing

-- Simple CSV splitter (does not fully handle quoted commas)
splitCSV :: T.Text -> [T.Text]
splitCSV = map (T.filter (/= '\"')) . T.splitOn ","

-- Extract weapon type from notes field (naive)
extractWeapon :: T.Text -> T.Text
extractWeapon notesTxt
  | "shooting" `T.isInfixOf` lowered = "Shooting"
  | "stabbing" `T.isInfixOf` lowered = "Stabbing"
  | "gunshot" `T.isInfixOf` lowered = "Gunshot"
  | "blunt" `T.isInfixOf` lowered = "Blunt Force"
  | "strang" `T.isInfixOf` lowered = "Strangulation"
  | otherwise = "Unknown"
  where lowered = T.toLower notesTxt

-- Weapon Type Distribution
weaponTypeDistribution :: [Homicide] -> [(T.Text, Int)]
weaponTypeDistribution hs =
  let grouped = foldl' (\acc h -> addOrIncrement (weaponType h) acc) [] hs
  in sortOn (negate . snd) grouped
  where
    addOrIncrement w [] = [(w,1)]
    addOrIncrement w ((k,v):xs)
      | w == k = (k, v+1):xs
      | otherwise = (k,v) : addOrIncrement w xs

printWeaponDist :: [(T.Text, Int)] -> IO ()
printWeaponDist = mapM_ (\(w,c) -> TIO.putStrLn $ w <> ": " <> T.pack (show c))

-- Top N Neighborhoods by homicide count (addresses filtered)
topNNeighborhoods :: Int -> [Homicide] -> [(T.Text, Int)]
topNNeighborhoods n hs =
  let isValidAddr addr = T.length (T.strip addr) > 3 && addr /= "pic" && addr /= ":"
      filtered = filter (isValidAddr . addressBlockFound) hs
      counts = foldl' (\acc h -> Map.insertWith (+) (addressBlockFound h) 1 acc) Map.empty filtered
      sorted = sortOn (negate . snd) $ Map.toList counts
  in take n sorted

printTopNeighborhoods :: [(T.Text, Int)] -> IO ()
printTopNeighborhoods = mapM_ (\(neigh, cnt) -> TIO.putStrLn $ neigh <> ": " <> T.pack (show cnt))

-- Main program: read, parse, analyze, print results
main :: IO ()
main = do
  content <- TIO.readFile "baltimore_homicides_combined.csv"
  let ls = drop 1 $ T.lines content
      homicides = mapMaybe parseHomicide ls
  putStrLn "Weapon Type Distribution:"
  printWeaponDist $ weaponTypeDistribution homicides
  putStrLn ""
  putStrLn "Top 10 Neighborhoods by Homicide Incidence:"
  printTopNeighborhoods $ topNNeighborhoods 10 homicides
