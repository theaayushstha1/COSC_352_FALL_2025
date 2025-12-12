{-# LANGUAGE OverloadedStrings #-}

module Homicide where

import qualified Data.ByteString.Lazy as BL
import Data.Csv
import qualified Data.Vector as V
import Data.Text (Text)
import qualified Data.Text as T

-- Define the Homicide record type matching actual CSV columns
data Homicide = Homicide
  { homicideNo :: Text
  , homicideDateDied :: Text
  , homicideName :: Text
  , homicideAge :: Text
  , homicideAddressBlock :: Text
  , homicideNotes :: Text
  , homicideYear :: Int
  , homicideLat :: Text
  , homicideLon :: Text
  } deriving (Show)

-- CSV parsing instance
instance FromNamedRecord Homicide where
  parseNamedRecord r = Homicide
    <$> r .: "No."
    <*> r .: "Date Died"
    <*> r .: "Name"
    <*> r .: "Age"
    <*> r .: "Address Block Found"
    <*> r .: "Notes"
    <*> r .: "year"
    <*> r .: "lat"
    <*> r .: "lon"

-- Parse CSV file into list of Homicides
parseHomicides :: FilePath -> IO (Either String [Homicide])
parseHomicides filePath = do
  csvData <- BL.readFile filePath
  case decodeByName csvData of
    Left err -> return $ Left err
    Right (_, v) -> return $ Right (V.toList v)