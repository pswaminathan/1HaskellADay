{-# LANGUAGE OverloadedStrings #-}

module Y2020.M07.D22.Solution where 

{--
So, day before yesterday, we parsed a JSON file...
So, yesterday, we contacted a REST endpoint with a GET request and got a
response-as-string-but-it's-really-JSON.

So, where two stream join, you fish.

I learned that from Hannibal Lecter.

Today's Haskell problem: go to the endpoint from yesterday. You 'know' we
have a list response of 642 entries. Now, divide that response into two
result sets: 

Those that are HTTPS endpoints and those that are not.


Also, bonus, it'd be nice if the APIs were searchable by name (so: Map).
--}

import Control.Arrow ((***), (&&&), second)

import Data.ByteString.Lazy.Char8 (ByteString)
import qualified Data.ByteString.Lazy.Char8 as L

import Data.Aeson

import Data.List (partition)
import Data.Map (Map)
import qualified Data.Map as Map
import Data.Maybe (fromJust)

import Network.HTTP.Conduit (simpleHttp)

import Y2020.M07.D21.Solution

type Name = String
type Description = String
type IsHttps = Bool
type URL = FilePath
type Category = String

data API = API { name :: Name, desc :: Description,
                 isHttps :: IsHttps, url :: URL, cat :: Category }
   deriving (Eq, Ord, Show)

instance FromJSON API where
   parseJSON = withObject "API" (\v -> API
      <$> v .: "API"
      <*> v .: "Description"
      <*> v .: "HTTPS"
      <*> v .: "Link"
      <*> v .: "Category")

type Count = Int

data APIs = APIs { count :: Count, ents :: [API] }
   deriving (Eq, Show)

instance FromJSON APIs where
   parseJSON = withObject "APIs" (\v -> APIs
      <$> v .: "count"
      <*> v .: "entries")

partitionedAPIs :: ByteString -> Map IsHttps (Map Name API)
partitionedAPIs = 
   supahMap . (api2map *** api2map) . part . fromJust . parsingAPIs

parsingAPIs :: ByteString -> Maybe APIs
parsingAPIs = decode

part :: APIs -> ([API], [API])
part = partition isHttps . ents

api2map :: [API] -> Map Name API
api2map = Map.fromList . map (name &&& id)

supahMap :: (Map Name API, Map Name API) -> Map IsHttps (Map Name API)
supahMap (a, b) = Map.fromList [(True, a), (False, b)]

-- How many public APIs are HTTP? How many public APIs are HTTPS?

{--
>>> let maps = simpleHttp publicAPIEndpoint >>= return . partitionedAPIs 
>>> Map.map Map.size maps
fromList [(False,93),(True,546)]
>>> map (second (take 2 . Map.toList)) (Map.toList maps)
[(False,[("18F",API {name = "18F", 
                     desc = "Unofficial US Federal Government API Development",
                     isHttps = False, 
                     url = "http://18f.github.io/API-All-the-X/", 
                     cat = "Open Data"}),
         ("7Timer!",API {name = "7Timer!", 
                         desc = "Weather, especially for Astroweather", 
                         isHttps = False, 
                         url = "http://www.7timer.info/doc.php?lang=en", 
                         cat = "Weather"})]),
 (True,[("1Forge",API {name = "1Forge", desc = "Forex currency market data", 
                       isHttps = True, 
                       url = "https://1forge.com/forex-data-api/api-documentation", 
                       cat = "Currency Exchange"}),
        ("24 Pull Requests",API {name = "24 Pull Requests", 
                                 desc = "Project to promote open source collaboration during December", 
                                 isHttps = True, 
                                 url = "https://24pullrequests.com/api", 
                                 cat = "Development"})])]
--}
