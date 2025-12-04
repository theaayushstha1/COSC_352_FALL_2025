import Data.List (sortOn, groupBy, isInfixOf, findIndex)
import Data.Char (toLower)
import System.Environment (getArgs)
import Data.Maybe (fromMaybe)

data Homicide = Homicide
  { year  :: String
  , notes :: String
  } deriving (Show)

-- Manually split on ',' (does not handle quotes, good enough for clean data)
splitComma :: String -> [String]
splitComma = splitComma' [] []
  where
    splitComma' cell cells [] = reverse (reverse cell : cells)
    splitComma' cell cells (',':xs) = splitComma' [] (reverse cell : cells) xs
    splitComma' cell cells (x:xs)   = splitComma' (x:cell) cells xs

-- Detect column indices from the header row
getColumnIndices :: [String] -> (Int, Int)
getColumnIndices hdr =
  let find col = fromMaybe 0 (findIndex (\c -> map toLower c == map toLower col) hdr)
  in (find "year", find "Notes")

makeHomicide :: (Int, Int) -> [String] -> Homicide
makeHomicide (yearIdx, notesIdx) cols = Homicide
  { year  = if length cols > yearIdx then cols !! yearIdx else ""
  , notes = if length cols > notesIdx then cols !! notesIdx else ""
  }

parseCSV :: String -> [[String]]
parseCSV = map splitComma . lines

loadHomicides :: FilePath -> IO [Homicide]
loadHomicides fname = do
  txt <- readFile fname
  let rows = parseCSV txt
      header = if null rows then [] else head rows
      indices = getColumnIndices header
  return $ map (makeHomicide indices) (drop 1 rows)

homicidesPerYear :: [Homicide] -> [(String, Int)]
homicidesPerYear hs =
  map (\ys -> (year (head ys), length ys)) . groupBy (\a b -> year a == year b) . sortOn year $
    filter (\h -> year h /= "") hs

matchAny :: [String] -> String -> Bool
matchAny kws text = any (\kw -> isInfixOf kw (map toLower text)) (map (map toLower) kws)

classifyWeapon :: Homicide -> String
classifyWeapon h
  | matchAny ["shoot", "shot", "firearm"] n = "Firearm"
  | matchAny ["stab", "knife"] n            = "Knife"
  | matchAny ["beat", "blunt force"] n      = "Blunt Force"
  | matchAny ["unknown"] n                  = "Unknown"
  | otherwise                              = "Other"
  where n = notes h

weaponDistribution :: [Homicide] -> [(String, Int)]
weaponDistribution hs =
  map (\ws -> (head ws, length ws)) . groupBy (==) . sortOn id $ map classifyWeapon hs

main :: IO ()
main = do
  args <- getArgs
  let fname = if null args then "baltimore_homicides_combined.csv" else head args
  homicides <- loadHomicides fname
  putStrLn "Homicides per year:"
  mapM_ (\(y, c) -> putStrLn (y ++ ": " ++ show c)) $ homicidesPerYear homicides

  putStrLn "\nWeapon type distribution:"
  mapM_ (\(w, c) -> putStrLn (w ++ ": " ++ show c)) $ weaponDistribution homicides
