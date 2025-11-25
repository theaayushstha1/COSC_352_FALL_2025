module Types
  ( Homicide(..)
  ) where

-- | Domain model for a homicide row.
data Homicide = Homicide
  { caseNumber :: String
  , dateDied :: String
  , name :: String
  , age :: Maybe Int
  , addressBlock :: String
  , notes :: String
  , victimHistory :: String
  , surveillanceCamera :: String
  , caseClosed :: String
  , sourcePage :: String
  , year :: Int
  , latitude :: Maybe Double
  , longitude :: Maybe Double
  } deriving (Eq, Show)
