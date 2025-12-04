module Main (main) where

import Analysis
import CsvParser
import System.Exit (exitFailure)
import Types

main :: IO ()
main = do
  content <- readFile "baltimore_homicides_combined.csv"
  case parseCSV content of
    Left err -> do
      putStrLn ("CSV parse error: " ++ err)
      exitFailure
    Right rows -> do
      let body = drop 1 rows
          (rowErrors, homicides) = parseHomicideRows body
      mapM_ putStrLn rowErrors
      putStrLn ("Parsed homicides: " ++ show (length homicides))
      putStrLn ""
      putStrLn "Homicides per year:"
      mapM_ printYear (homicidesPerYear homicides)
      putStrLn ""
      putStrLn "Top 5 neighborhoods (address clusters):"
      mapM_ printNeighborhood (topNeighborhoods 5 homicides)

printYear :: (Int, Int) -> IO ()
printYear (yr, count) = putStrLn (show yr ++ ": " ++ show count)

printNeighborhood :: (String, Int) -> IO ()
printNeighborhood (addr, count) = putStrLn (addr ++ " -> " ++ show count)
