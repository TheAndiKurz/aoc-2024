package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:mem"
import "core:strconv"

getNumLength :: proc (num: i64) -> u64 {
    numClone := num
    count: u64 = 0
    for numClone > 0 {
        numClone /= 10
        count += 1
    }

    return count
}

ParseError :: enum {
    AllocatorError,
    ConversionError,
}

parse :: proc (file: string) -> ([]i64, ParseError) {
    splitResult, splitError := strings.split(file, " ")
    if splitError != nil {
        return nil, ParseError.AllocatorError
    }
    
    nums := [dynamic]i64{}
    for i in 0..<len(splitResult) {
        num := splitResult[i]
        n, ok := strconv.parse_i64(strings.trim_space(num), 10)
        if !ok {
            fmt.println("could not convert", num)
            continue
        }
        append(&nums, n)
    }

    return nums[:], nil
}

part1 :: proc (nums: []i64) -> int {
    nums_can_grow := [dynamic]i64{}
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
                divider: i64 = 1
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

Node :: struct {
    num: i64,
    steps: uint,
    left: ^Node,
    right: ^Node,
}

nodes := [dynamic]Node{}
numToNode := map[i64]^Node{}

addNode :: proc (node: Node) {
    append(&nodes, node)
    numToNode[node.num] = &nodes[len(nodes)-1]
}

countStones :: proc (node: ^Node, steps: uint) -> int {
    //fmt.printf("increaseEnding(%d, %d)\n", node.num, steps)
    if steps == 0 {
        return 1
    }

    count := 0
    if node.left != nil {
        count += countStones(node.left, steps - 1)
    }

    if node.right != nil {
        count += countStones(node.right, steps - 1)
    }

    return count
}

expandGraph :: proc (num: i64, steps: uint) {
    fmt.printf("expandGraph(%d, %d)\n", num, steps)

    node, ok := numToNode[num]
    if ok && node.left != nil {
        fmt.println(num, "already exists", node.steps, steps)
        if node.steps < steps {
            fmt.println(num, "has to get deeper")
            fmt.println("left", node.left)
            expandGraph(node.left.num, steps - 1)
            if node.right != nil {
                fmt.println("right", node.right)
                expandGraph(node.right.num, steps - 1)
            }
            node.steps = steps
        }
        return
    }

    if node == nil {
        node = &Node {
            num = num,
            steps = steps,
            left = nil,
            right = nil,
        }
    }
    node = numToNode[num]

    if steps == 0 {
        addNode(node^)
        return
    }

    if num == 0 {
        succ, ok := numToNode[1]
        if !ok {
            expandGraph(1, steps - 1)
            succ = numToNode[1]
        }
        node.left = succ
        return
    }

    
    numLength := getNumLength(num)
    if numLength % 2 == 0 {
        divider: i64 = 1
        for _ in 0..<numLength/2 {
            divider *= 10
        }
        num1 := num % divider
        num2 := num / divider
        fmt.println("divided", num, "into", num1, num2)

        expandGraph(num1, steps - 1)
        succ1 := numToNode[num1]

        expandGraph(num2, steps - 1)
        succ2 := numToNode[num2]

        node.left = succ1
        node.right = succ2
        
        addNode(node^)
        return
    }


    newNum := num * 2024
    succ, ok2024 := numToNode[newNum]
    if !ok2024 {
        expandGraph(newNum, steps - 1)
        succ = numToNode[newNum]
    }
    node.left = succ
    addNode(node^)
}

part2 :: proc (nums: []i64) -> int {
    blinks :: 25
    for num in nums {
        expandGraph(num, blinks)
    }

    fmt.println(len(nodes))

    fmt.println("now counting")
    count := 0
    for num in nums {
        count += countStones(numToNode[num], blinks)
    }

    return count
}

main :: proc () {
    fileBytes, readError := os.read_entire_file_from_filename_or_err("input.txt")
    if readError != nil {
        fmt.panicf("error reading file: %v", readError)
    }
    file := string(fileBytes)
    nums, parseError := parse(file)
    if parseError != nil {
        fmt.panicf("error parsing file: %v", parseError)
    }
    defer delete(nums)
    
    fmt.println("part1 result:", part1(nums))
    fmt.println("part2 result:", part2(nums))
}
