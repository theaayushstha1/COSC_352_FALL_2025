module CsvParser
  ( parseCSV
  , parseHomicideRows
  ) where

import Data.Char (isDigit)
import Text.Read (readMaybe)
import Types

-- | Parse full CSV text into rows of fields.
parseCSV :: String -> Either String [[String]]
parseCSV content = traverse parseLine (lines content)

-- | Convert CSV rows (excluding header) into homicide records and collect errors.
parseHomicideRows :: [[String]] -> ([String], [Homicide])
parseHomicideRows rows =
  foldr collect ([], []) (zip [2 ..] rows)
  where
    collect (n, r) (errs, hs) =
      case parseRow r of
        Left e -> (("Row " ++ show n ++ ": " ++ e) : errs, hs)
        Right h -> (errs, h : hs)

parseRow :: [String] -> Either String Homicide
parseRow fields
  | length fields /= 13 = Left ("Expected 13 columns, found " ++ show (length fields))
  | otherwise =
      case (readInt (fields !! 0), readInt (fields !! 10)) of
        (Nothing, _) -> Left "Case number missing or invalid"
        (_, Nothing) -> Left "Year missing or invalid"
        (_, Just yr) ->
          Right
            Homicide
              { caseNumber = fields !! 0
              , dateDied = fields !! 1
              , name = fields !! 2
              , age = readInt (fields !! 3)
              , addressBlock = fields !! 4
              , notes = fields !! 5
              , victimHistory = fields !! 6
              , surveillanceCamera = fields !! 7
              , caseClosed = fields !! 8
              , sourcePage = fields !! 9
              , year = yr
              , latitude = readDouble (fields !! 11)
              , longitude = readDouble (fields !! 12)
              }

readInt :: String -> Maybe Int
readInt txt =
  case filter isDigit txt of
    "" -> Nothing
    digits -> readMaybe digits

readDouble :: String -> Maybe Double
readDouble txt = readMaybe txt

-- CSV line parser implemented with explicit recursion to honor assignment constraints.
parseLine :: String -> Either String [String]
parseLine input = parseFields input False [] []
  where
    parseFields [] inQuotes current acc
      | inQuotes = Left "Unclosed quote"
      | otherwise = Right (reverse (reverse current : acc))
    parseFields (c:cs) inQuotes current acc
      | inQuotes =
          if c == '"'
            then case cs of
                   ('"':rest) -> parseFields rest True ('"':current) acc
                   _ -> parseFields cs False current acc
            else parseFields cs True (c:current) acc
      | c == '"' = parseFields cs True current acc
      | c == ',' = parseFields cs False [] (reverse current : acc)
      | otherwise = parseFields cs False (c:current) acc
