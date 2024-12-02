import Data.Maybe (catMaybes)
import Data.List (sort)
import Data.Map (Map, empty, findWithDefault, insert)

parseLine :: String -> Maybe (Int, Int)
parseLine s =
    let ws = words s in

    case ws of
        [fst, snd] -> Just (read fst, read snd)
        _ -> Nothing

parse :: String -> IO ([Int], [Int])
parse s = do
    input <- readFile s
    let parsed = map parseLine (lines input)

    let parsed' = catMaybes parsed

    return $ unzip parsed'

part1 :: IO ()
part1 = do
    (fst, snd) <- parse "./input.txt"

    let (fst', snd') = (sort fst, sort snd)

    let diffs = zipWith (\x y -> abs (x - y)) fst' snd'

    print $ sum diffs

counts :: [Int] -> Map Int Int
counts [] = empty
counts (x : xs) = insert x value m
    where
        m = counts xs
        value = 1 + findWithDefault 0 x m

part2 :: IO ()
part2 = do
    (fst, snd) <- parse "./example.txt"

    let count_snd = counts snd

    let similarity = map (\x -> x * findWithDefault 0 x count_snd) fst

    print $ sum similarity

