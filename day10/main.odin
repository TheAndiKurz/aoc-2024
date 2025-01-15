package main

import "core:fmt"
import "core:os"
import "core:strings"

parse :: proc(lines: []string) -> ([]u8, [2]int) {
    size := [2]int{len(lines[0]), len(lines) - 1}
    parsed := make([]u8, size.x * size.y)
    for y in 0..<size.y {
        line := lines[y]
        fmt.println(line)
        for x in 0..<size.x {
            char := line[x]
            if char > '9' || char < '0' {
                fmt.panicf("invalid character: %c", char)
            }
            index := y * size.x + x
            parsed[index] = char - '0'
        }
    }

    return parsed, size
}

followPath :: proc (input: []u8, size: [2]int, start: int, reached: []bool) -> int {
    startValue := input[start]
    if startValue == 9 {
        if reached[start] {
            return 0
        }
        reached[start] = true
        return 1
    }


    count := 0

    topIndex := start - size.x
    if topIndex >= 0 && input[topIndex] - startValue == 1 {
        count += followPath(input, size, topIndex, reached)
    }

    bottomIndex := start + size.x
    if bottomIndex < len(input) && input[bottomIndex] - startValue == 1 {
        count += followPath(input, size, bottomIndex, reached)
    }

    leftIndex := start - 1
    if start % size.x != 0 && input[leftIndex] - startValue == 1 {
        count += followPath(input, size, leftIndex, reached)
    }

    rightIndex := start + 1
    if rightIndex % size.x != 0 && input[rightIndex] - startValue == 1 {
        count += followPath(input, size, rightIndex, reached)
    }

    return count
}

part1 :: proc (input: []u8, size: [2]int) -> int {
    count := 0

    for i in 0..<len(input) {
        if input[i] == 0 {
            reached := make([]bool, len(input))
            defer delete(reached)

            score := followPath(input, size, i, reached)
            count += score
        }
    }

    return count
}

followPath2 :: proc (input: []u8, size: [2]int, start: int) -> int {
    startValue := input[start]
    if startValue == 9 {
        return 1
    }


    count := 0

    topIndex := start - size.x
    if topIndex >= 0 && input[topIndex] - startValue == 1 {
        count += followPath2(input, size, topIndex)
    }

    bottomIndex := start + size.x
    if bottomIndex < len(input) && input[bottomIndex] - startValue == 1 {
        count += followPath2(input, size, bottomIndex)
    }

    leftIndex := start - 1
    if start % size.x != 0 && input[leftIndex] - startValue == 1 {
        count += followPath2(input, size, leftIndex)
    }

    rightIndex := start + 1
    if rightIndex % size.x != 0 && input[rightIndex] - startValue == 1 {
        count += followPath2(input, size, rightIndex)
    }

    return count
}

part2 :: proc (input: []u8, size: [2]int) -> int {
    count := 0

    for i in 0..<len(input) {
        if input[i] == 0 {
            score := followPath2(input, size, i)
            count += score
        }
    }

    return count
}

main :: proc () {
    data, readError := os.read_entire_file_from_filename_or_err("input.txt")
    if readError != nil {
        fmt.panicf("could not read file: %v", readError)
    }

    stringData := string(data)

    lines, splitError := strings.split_lines(stringData)
    if splitError != nil {
        fmt.panicf("could not split file into lines: %v", splitError)
    }

    parsed, size := parse(lines)
    defer delete(parsed)

    fmt.println("part1 result: ", part1(parsed, size))
    fmt.println("part2 result: ", part2(parsed, size))
}
