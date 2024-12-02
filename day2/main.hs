parseLine :: String -> [Int]
parseLine s = map read $ words s

parse :: String -> IO [[Int]]
parse filePath = do
    file <- readFile filePath

    return $ map parseLine $ lines file

isSave'' :: Int -> (Int -> Int -> Bool) -> [Int] -> Bool
isSave'' (-1) _ _ = False
isSave'' damp comp [] = True
isSave'' damp comp [x] = True
isSave'' damp comp [x, y]
    | damp > 0 = True
    | comp x y = False
    | abs (x - y) > 3 = False
    | otherwise = True

isSave'' damp comp (x : y : xs) =
    let skipped = isSave'' (damp - 1) comp $ x : xs in

    ((not (comp x y || (abs (x - y) > 3)) 
    && isSave'' damp comp (y : xs))
    || skipped)

isSave' :: Int -> (Int -> Int -> Bool) -> [Int] -> Bool
isSave' (-1) _ _ = False
isSave' damp comp [] = True
isSave' damp comp [x] = True
isSave' damp comp (x : y : xs) = 
    isSave'' (damp - 1) comp (y : xs)
    || isSave'' damp comp (x : y : xs)

isSave :: Int -> [Int] -> Bool
isSave damp x = isSave' damp (>=) x || isSave' damp (<=) x

part1 :: IO ()
part1 = do
    input <- parse "./input.txt"

    let saves = map (isSave 0) input

    print $ length $ filter id saves


part2 :: IO ()
part2 = do
    input <- parse "./input.txt"

    let saves = map (isSave 1) input

    print $ length $ filter id saves
