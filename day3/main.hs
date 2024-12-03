import Text.Read (readMaybe)
import Debug.Trace
inParthesis :: String -> Maybe (String, (Int, Int))
inParthesis s =
    let
        helper :: String -> String -> Bool -> String -> Maybe (String, (Int, Int))
        -- there was never a ','
        helper (')' : _) _ False _ = Nothing
        helper (')' : rest) s1 True s2 =
            case (readMaybe s1, readMaybe s2) of
                (Just n1, Just n2) -> Just (rest, (n1, n2))
                _ -> Nothing

        helper (',' : _) _ True _ = Nothing
        helper (',' : rest) s1 False s2 = helper rest s1 True s2
        helper (c : rest) s1 False s2 = helper rest (s1 ++ [c]) False s2
        helper (c : rest) s1 True s2 = helper rest s1 True (s2 ++ [c])
    in

    helper s "" False ""

mul :: String -> (String, Maybe (Int, Int))
mul ('m':'u':'l':'(' : rest) =
    case inParthesis rest of
        Nothing -> (rest, Nothing)
        Just (xs, value) -> (xs, Just value)

mul (_ : rest) = (rest, Nothing)
mul [] = ([], Nothing)

parseContentPart2 :: Bool -> String -> [(Int, Int)]
parseContentPart2 _ "" = []
parseContentPart2 _ ('d':'o':'n':'\'':'t':'(':')':rest) = 
    parseContentPart2 False rest
parseContentPart2 _ ('d':'o':'(':')':rest) = 
    parseContentPart2 True rest
parseContentPart2 True s = case mul s of
    (rest, Nothing) -> parseContentPart2 True rest
    (rest, Just pair) -> pair : parseContentPart2 True rest
parseContentPart2 False (_ : ss) = parseContentPart2 False ss

parseContentPart1 :: String -> [(Int, Int)]
parseContentPart1 "" = []
parseContentPart1 s = case mul s of
    (rest, Nothing) -> parseContentPart1 rest
    (rest, Just pair) -> pair : parseContentPart1 rest

data Part = Part1 | Part2

parseContent :: Part -> String -> [(Int, Int)]
parseContent Part1 = parseContentPart1
parseContent Part2 = parseContentPart2 True

parse :: Part -> String -> IO [(Int, Int)]
parse p fileName = do
    content <- readFile fileName
    return $ parseContent p content

fileName = "./input.txt"
part1 :: IO ()
part1 = do
    input <- parse Part1 fileName

    print $ sum $ map (uncurry (*)) input

part2 :: IO ()
part2 = do
    input <- parse Part2 fileName

    print $ sum $ map (uncurry (*)) input
