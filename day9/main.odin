package main

import "core:fmt"
import "core:os"
import "core:strings"

parse :: proc (line: string) -> []i16 {
    nums: [dynamic]u8
    defer delete(nums)
    for i in 0..<len(line) {
        char := line[i]
        if char < '0' || char > '9' {
            continue
        }

        append(&nums, char - '0')
    }

    sum := 0
    for num in nums {
        sum += int(num)
    }
    
    file_dir := make([]i16, sum) 

    file_id: i16 = 0
    j := 0
    for i in 0..<len(nums) {
        num := nums[i]

        if i % 2 == 0 {
            for _ in 0..<num{
                file_dir[j] = file_id
                j += 1
            }
            file_id += 1
        } else {
            for _ in 0..<num{
                file_dir[j] = -1
                j += 1
            }
        }
    }

    return file_dir
}

checksum :: proc (file_dir: []i16) -> int {
    result := 0
    for i in 0..<len(file_dir) {
        num := file_dir[i]
        if num < 0 {
            continue
        }
        
        result += i * int(num)
    }

    return result
}

part1 :: proc (file_dir: []i16) -> int {
    p1 := 0
    p2 := len(file_dir) - 1

    for {
        if p1 >= p2 {
            break 
        }
        if file_dir[p1] != -1 {
            p1 += 1
            continue
        }
        if file_dir[p2] == -1 {
            p2 -= 1
            continue
        }
        
        file_dir[p1] = file_dir[p2]
        file_dir[p2] = -1

        p1 += 1
        p2 -= 1
    }

    return checksum(file_dir)
}

print_dir :: proc (file_dir: []i16) {
    for file_id in file_dir {
        if file_id < 0 {
            fmt.print(".")
            continue
        }
        fmt.print(file_id)
    }

    fmt.println()
}

part2 :: proc (file_dir: []i16) -> int {
    file_id := file_dir[len(file_dir) - 1]

    for file_id > 0 {
        upper_idx := len(file_dir) - 1
        for file_dir[upper_idx] != file_id {
            upper_idx -= 1
        }

        lower_idx := upper_idx
        for file_dir[lower_idx] == file_id {
            lower_idx -= 1
        }

        file_id_size := upper_idx - lower_idx
        fmt.printfln("id(%d) -> %d:%d (%d)", file_id, lower_idx, upper_idx, file_id_size)

        // find slot
        lower_empty := 0
        for lower_empty < lower_idx {
            for file_dir[lower_empty] != -1 {
                lower_empty += 1
            }

            upper_empty := lower_empty + 1
            for file_dir[upper_empty] == -1 {
                upper_empty += 1
            }
            empty_size := upper_empty - lower_empty

            fmt.printfln("empty -> %d:%d (%d)", lower_empty, upper_empty, empty_size)
            
            if empty_size >= file_id_size {
                break
            }

            lower_empty += empty_size
        }

        if lower_empty < lower_idx {
            for i in 0..<file_id_size {
                file_dir[lower_idx + i + 1] = -1
                file_dir[lower_empty + i] = file_id
            }
        }
        file_id -= 1
    }

    return checksum(file_dir)
}

main :: proc () {
    content, readError := os.read_entire_file_from_filename_or_err("input.txt")
    if readError != nil {
        fmt.eprintln("could not read file:", readError)
    }
    defer delete(content)
    
    line := string(content)
    input1 := parse(line)
    defer delete(input1)

    fmt.println("part 1:", part1(input1))

    input2 := parse(line)
    defer delete(input2)
    
    fmt.println("part 2:", part2(input2))
}
