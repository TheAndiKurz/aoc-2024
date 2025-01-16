package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:mem"
import "core:strconv"

num_type :: i128

getNumLength :: proc (num: num_type) -> u64 {
    numClone := num
    count: u64 = 0
    for numClone > 0 {
        numClone /= 10
        count += 1
    }

    return count
}

divideNum :: proc (num: num_type) -> (num_type, num_type, bool){
    numLength := getNumLength(num)
    if numLength % 2 != 0 {
        return 0, 0, false
    }

    divider: num_type = 1
    for _ in 0..<numLength/2 {
        divider *= 10
    }
    num1 := num / divider
    num2 := num % divider

    return num1, num2, true
}

ParseError :: enum {
    AllocatorError,
    ConversionError,
}

parse :: proc (file: string) -> ([]num_type, ParseError) {
    splitResult, splitError := strings.split(file, " ")
    defer delete(splitResult)
    if splitError != nil {
        return nil, ParseError.AllocatorError
    }
    
    nums := [dynamic]num_type{}
    for i in 0..<len(splitResult) {
        num := splitResult[i]
        n, ok := strconv.parse_i128(strings.trim_space(num), 10)
        if !ok {
            fmt.println("could not convert", num)
            continue
        }
        append(&nums, n)
    }

    return nums[:], nil
}

part1 :: proc (nums: []num_type) -> int {
    nums_can_grow := [dynamic]num_type{}
    defer delete(nums_can_grow)
    for num in nums {
        append(&nums_can_grow, num)
    }

    for blink in 0..<25 {
        current_length := len(nums_can_grow)
        fmt.println(blink, current_length)
        for i in 0..<current_length {
            if nums_can_grow[i] == 0 {
                nums_can_grow[i] = 1
                continue
            }

            numLength := getNumLength(nums_can_grow[i])
            if numLength % 2 == 0 {
                divider: num_type = 1
                for _ in 0..<numLength/2 {
                    divider *= 10
                }
                append(&nums_can_grow, nums_can_grow[i] % divider)
                nums_can_grow[i] /= divider
                continue
            }
            
            nums_can_grow[i] *= 2024
        }
    }

    return len(nums_can_grow)
}


stones :: proc (num: num_type, steps: int, memo: ^map[num_type]^[76]int) -> int {
    // fmt.printf("stones(%d, %d)\n", num, steps)
    if steps == 0 {
        return 1
    }

    stepList, ok := memo[num]
    if ok && stepList[steps] != 0 {
        // fmt.printf("retrieving memo[%d][%d] = %d\n", num, steps, stepList[steps])
        return stepList[steps]
    }

    if !ok {
        memo[num] = new([76]int)
        stepList = memo[num]
        stepList[0] = 1
    }

    if num == 0 {
        for step in 0..<steps {
            s := stones(1, step, memo)
            stepList[step + 1] = s
            // fmt.printf("memo[%d][%d] = %d\n", num, step + 1, s)
        }

        return stepList[steps]
    }
    
    if num1, num2, ok := divideNum(num); ok {
        for step in 0..<steps {
            s1 := stones(num1, step, memo)
            s2 := stones(num2, step, memo)
            stepList[step + 1] = s1 + s2
            // fmt.printf("memo[%d][%d] = %d + %d = %d\n", num, step + 1, s1, s2, s1 + s2)
        }

        return stepList[steps]
    }

    newNum := num * 2024

    for step in 0..<steps {
        s := stones(newNum, step, memo)
        stepList[step + 1] = s
        // fmt.printf("memo[%d][%d] = %d\n", num, step + 1, s)
    }

    return stepList[steps]
}

part2 :: proc (nums: []num_type) -> int {
    memo: map[num_type]^[76]int
    defer {
        for _, v in memo {
            free(v)
        }
        delete(memo)
    }

    count := 0
    for num in nums {
        count += stones(num, 75, &memo)
    }
    
    return count
}

main :: proc () {
    fileBytes, readError := os.read_entire_file_from_filename_or_err("input.txt")
    if readError != nil {
        fmt.panicf("error reading file: %v", readError)
    }
    defer delete(fileBytes)
    file := string(fileBytes)
    nums, parseError := parse(file)
    if parseError != nil {
        fmt.panicf("error parsing file: %v", parseError)
    }
    defer delete(nums)

    fmt.println("part1 result:", part1(nums))
    fmt.println("part2 result:", part2(nums))
}
