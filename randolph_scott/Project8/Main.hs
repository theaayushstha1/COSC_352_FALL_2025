{-# LANGUAGE OverloadedStrings #-}

module Main where

import qualified Data.ByteString.Lazy as BL
import qualified Data.Csv as Csv
import qualified Data.Vector as V
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import Data.List (sortOn)
import qualified Data.Map as M

--------------------------------------------------------------------------------
-- TYPE
--------------------------------------------------------------------------------

data Homicide = Homicide
  { hYear        :: Int
  , hNeighborhood :: Text
  } deriving (Show)

--------------------------------------------------------------------------------
-- PARSER (very forgiving)
--------------------------------------------------------------------------------

instance Csv.FromRecord Homicide where
  parseRecord v =
    case length v of
      n | n >= 8 -> do
            dateField <- v Csv..! 1 :: Csv.Parser Text
            neigh     <- v Csv..! 7 :: Csv.Parser Text
            let y = parseYear dateField
            return $ Homicide y neigh
      _ -> fail "Row too short"

-- "01/02/20" → 2020
parseYear :: Text -> Int
parseYear t =
  case T.splitOn "/" t of
    [_,_,yy] -> 2000 + read (T.unpack yy)
    _        -> 0

--------------------------------------------------------------------------------
-- PURE ANALYSIS
--------------------------------------------------------------------------------

homicidesPerYear :: [Homicide] -> [(Int, Int)]
homicidesPerYear hs =
  let freq = foldl (\m h -> M.insertWith (+) (hYear h) 1 m) M.empty hs
  in sortOn fst (M.toList freq)

topNeighborhoods :: Int -> [Homicide] -> [(Text, Int)]
topNeighborhoods n hs =
  let freq = foldl (\m h -> M.insertWith (+) (hNeighborhood h) 1 m) M.empty hs
      sorted = reverse (sortOn snd (M.toList freq))
  in take n sorted

--------------------------------------------------------------------------------
-- MAIN
--------------------------------------------------------------------------------

main :: IO ()
main = do
  putStrLn "Reading baltimore_homicides_combined.csv..."
  csvData <- BL.readFile "baltimore_homicides_combined.csv"

  case Csv.decode Csv.NoHeader csvData :: Either String (V.Vector Homicide) of
    Left err -> putStrLn ("CSV parse error: " ++ err)
    Right vec -> do
      let hs = V.toList vec

      putStrLn "\n====================="
      putStrLn "Homicides per year"
      putStrLn "====================="
      print (homicidesPerYear hs)

      putStrLn "\n====================="
      putStrLn "Top 5 neighborhoods"
      putStrLn "====================="
      print (topNeighborhoods 5 hs)
