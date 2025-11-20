module Main where

import Homicide
import Analysis
import System.Exit (exitFailure)

main :: IO ()
main = do
  putStrLn "Loading Baltimore Homicides data..."
  
  result <- parseHomicides "baltimore_homicides_combined.csv"
  
  case result of
    Left err -> do
      putStrLn $ "Error parsing CSV: " ++ err
      exitFailure
    
    Right homicides -> do
      putStrLn $ "Loaded " ++ show (length homicides) ++ " homicide records.\n"
      
      -- Analysis 1: Homicides per year
      putStrLn "=== Analysis 1: Homicides Per Year ==="
      let yearAnalysis = homicidesPerYear homicides
      putStrLn $ formatYearData yearAnalysis
      
      -- Analysis 2: Top 10 address blocks
      putStrLn "\n=== Analysis 2: Top 10 Address Blocks by Homicide Count ==="
      let topAddr = topAddresses 10 homicides
      putStrLn $ formatAddressData topAddr
      
      putStrLn "\nAnalysis complete!"