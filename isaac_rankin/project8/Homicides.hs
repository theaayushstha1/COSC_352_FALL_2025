-- Homicides.hs
-- A pure functional analysis tool for the Baltimore Homicides dataset.
-- Demonstrates functional constructs: Type definitions, pattern matching, map, fold, guards.

import Data.List (sortBy, groupBy)
import Data.Ord (comparing)
import Data.Char (isSpace, isDigit)
import System.IO (readFile)
import Text.Read (readMaybe) -- Required for safe string-to-int conversion

-- | -------------------------------------------------------------------------
-- | 1. Data & Types: Defining the Homicide Record
-- | -------------------------------------------------------------------------

-- | The Homicide record structure.
data Homicide = Homicide {
    -- Using Address Block Found (Index 4) as the location identifier
    locationIdentifier :: String, 
    -- Date Died (Index 1) in MM/DD/YYYY format
    dateString :: String, 
    -- Age (Index 2), potentially complex (e.g., "26, pic")
    ageString :: String
} deriving (Show, Eq)

-- | Defines the age categories for Analysis 2. The order is important for sorting.
data AgeRange = Baby | Child | PreTeen | Teen | YoungAdult | Adult | MiddleAge | Senior | Unknown 
    deriving (Show, Eq, Ord)

-- | Helper function to extract the month (MM) from the date string (MM/DD/YYYY).
-- | This is a pure function.
extractMonth :: String -> String
-- We assume the date is always valid and in MM/DD/YYYY format.
extractMonth date = take 2 date -- Grabs the first two characters (MM)

-- | -------------------------------------------------------------------------
-- | 2. I/O Core: Parsing the CSV (The only impure part)
-- | -------------------------------------------------------------------------

-- | Takes a row of CSV data and attempts to convert it into a Homicide record.
-- | Column 2 (Date Died): index 1
-- | Column 3 (Name/Age): index 2 (Age is often complex like "26, pic")
-- | Column 5 (Address Block Found): index 4
parseRow :: [String] -> Maybe Homicide
parseRow row = 
    -- We need indices 1 (Date Died), 2 (Age), and 4 (Address Block Found)
    if length row > 4 
    then Just Homicide { 
            locationIdentifier = trim (row !! 4), -- Address Block Found
            dateString = trim (row !! 1),          -- Date Died
            ageString = trim (row !! 3)            -- Age
         }
    else Nothing

-- | Simple trim function to remove leading/trailing whitespace.
trim :: String -> String
trim = f . f
    where f = reverse . dropWhile isSpace

-- | Parses the entire CSV content string into a list of Homicide records.
-- | Skips the header row (first line) and invalid rows.
parseCSV :: String -> [Homicide]
parseCSV content = 
    let 
        -- Split content into lines, skip header, and split each line by comma.
        rows = drop 1 (lines content) 
        splitByComma = map (splitOn ',') rows
        -- Use map and filter (in a list comprehension) to safely parse the data
        parsedHomicides = [homicide | row <- splitByComma, Just homicide <- [parseRow row]]
    in 
        parsedHomicides

-- | Custom split function since Data.List.Split is not standard.
splitOn :: Char -> String -> [String]
splitOn delim s = case dropWhile (== delim) s of
    "" -> []
    s' -> w : splitOn delim s''
          where (w, s'') = break (== delim) s'

-- | -------------------------------------------------------------------------
-- | 3. Pure Functional Core: Analysis Logic
-- | -------------------------------------------------------------------------

-- | Type synonym for the resulting analysis format: (Key, Count)
type AnalysisResult = (String, Int)

-- | Helper function to validate the extracted month string and categorize it.
categorizeMonth :: String -> String
categorizeMonth monthStr
    | monthStr `elem` ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"] = monthStr
    | otherwise = "Unknown"

-- | Custom comparison logic to ensure "Unknown" is sorted to the very end.
compareMonth :: (String, Int) -> (String, Int) -> Ordering
compareMonth ("Unknown", _) ("Unknown", _) = EQ
compareMonth ("Unknown", _) _ = GT -- Unknown is greater (comes after) any other month
compareMonth _ ("Unknown", _) = LT -- Any month is less (comes before) Unknown
compareMonth (m1, _) (m2, _) = compare m1 m2 -- Compare month strings normally (01-12)

-- | **Analysis 1: Homicides per Month**
-- | Groups and counts homicides based on the month extracted from the date,
-- | classifying invalid/unreadable months as "Unknown".
-- | Uses 'foldr' as a reduction pattern to build the frequency map.
countHomicidesByMonth :: [Homicide] -> [AnalysisResult]
countHomicidesByMonth homicides = 
    let 
        -- 1. Use map to transform Homicide records into CATEGORIZED months (MM or "Unknown")
        months = map (categorizeMonth . extractMonth . dateString) homicides
        
        -- 2. Use a fold (reduction) to create a frequency map (as a list of tuples)
        countAcc :: String -> [AnalysisResult] -> [AnalysisResult]
        countAcc month acc = case lookup month acc of
            -- If month found, increment count and replace old tuple
            Just count -> (month, count + 1) : filter ((/= month) . fst) acc
            -- If month not found, add new tuple
            Nothing    -> (month, 1) : acc

        frequencyMap = foldr countAcc [] months
    in 
        -- 3. Sort using the custom comparator to put Unknown last
        sortBy compareMonth frequencyMap


-- | Helper function to clean the age string (e.g., "33, pic" -> "33")
cleanAgeString :: String -> String
cleanAgeString = takeWhile isDigit

-- | **Analysis 2: Homicides by Age Range**
-- | Groups and counts homicides based on the specified age categories.
categorizeAge :: String -> AgeRange
categorizeAge ageStr = 
    let cleanStr = cleanAgeString ageStr
    -- Safely read the integer age, falling back to Unknown if parsing fails
    in case readMaybe cleanStr :: Maybe Int of
         Just age 
             | age >= 1 && age <= 4   -> Baby
             | age >= 5 && age <= 9   -> Child
             | age >= 10 && age <= 12 -> PreTeen
             | age >= 13 && age <= 17 -> Teen
             | age >= 18 && age <= 29 -> YoungAdult
             | age >= 30 && age <= 44 -> Adult
             | age >= 45 && age <= 64 -> MiddleAge
             | age >= 65              -> Senior
             | otherwise              -> Unknown -- Covers age 0 or negative
         Nothing -> Unknown

countHomicidesByAgeRange :: [Homicide] -> [AnalysisResult]
countHomicidesByAgeRange homicides =
    let
        -- 1. Map homicides to their AgeRange category
        ageRanges = map (categorizeAge . ageString) homicides
        
        -- 2. Sort the list of categories (required for groupBy)
        sortedRanges = sortBy compare ageRanges
        
        -- 3. Group identical consecutive categories
        groupedRanges = groupBy (==) sortedRanges
        
        -- 4. Count the groups and map to (String, Int)
        counted = map (\group -> (show (head group), length group)) groupedRanges
    in
        -- The initial sort/grouping handles the desired order due to 'deriving Ord' on AgeRange
        counted

-- | -------------------------------------------------------------------------
-- | 4. Main Program: I/O and Printing Results (Impure)
-- | -------------------------------------------------------------------------

main :: IO ()
main = do
    putStrLn "Starting Baltimore Homicide Data Analysis..."
    
    -- File path hardcoded for the assignment
    let filePath = "baltimore_homicides_combined.csv"

    -- Catch potential file reading errors (Simplified)
    fileContent <- catch (readFile filePath)
        (\e -> do 
            putStrLn $ "Error reading file " ++ filePath ++ ": " ++ show (e :: IOError)
            putStrLn "Please ensure 'baltimore_homicides_combined.csv' is in the current directory."
            return "")

    if null fileContent
    then putStrLn "Analysis terminated due to file error."
    else do
        putStrLn $ "Successfully read " ++ filePath ++ "."

        let 
            -- Parse the data
            homicides = parseCSV fileContent
            totalRecords = length homicides
        
        putStrLn $ "Parsed " ++ show totalRecords ++ " homicide records."
        
        putStrLn "\n======================================================="
        putStrLn "ANALYSIS 1: Homicides Per Month"
        putStrLn "======================================================="

        let monthlyResults = countHomicidesByMonth homicides
        mapM_ (\(month, count) -> putStrLn $ "Month " ++ month ++ ": " ++ show count) monthlyResults

        putStrLn "\n======================================================="
        putStrLn "ANALYSIS 2: Homicides by Age Range"
        putStrLn "======================================================="

        let ageResults = countHomicidesByAgeRange homicides
        mapM_ (\(name, count) -> putStrLn $ name ++ ": " ++ show count ++ " incidents") ageResults
        
        putStrLn "\nAnalysis Complete."
        
-- A simple way to handle IO errors without external libraries
catch :: IO a -> (IOError -> IO a) -> IO a
catch action handler = do
    result <- action
    return result