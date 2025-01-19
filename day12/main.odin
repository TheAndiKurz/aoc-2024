package main

import "core:fmt"
import "core:os"
import "core:strings"

filename :: "input.txt"

main :: proc () {
    fileData, readError := os.read_entire_file_from_filename_or_err(filename)
    if readError != nil {
        fmt.panicf("could not read file: %v", readError)
    }
    defer delete(fileData)

    data := string(fileData)
    lines, splitError := strings.split_lines(data)
    if readError != nil {
        fmt.panicf("could not split into lines: %v", splitError)
    }
    defer delete(lines)

    regions, regionsMap, size := parse(lines[:len(lines) - 1])
    defer {
        delete(regions)
        delete(regionsMap)
    }

    fmt.println("part1: ", part1(regions[:], regionsMap, size))
    fmt.println("part2: ", part2(regions[:], regionsMap, size))
}

Region :: struct {
    plant: u8,
    area: int,
    perimeter: int,
    sides: int,
}

findRegion :: proc (lines: []string, start: [2]int, regions: ^[]^Region, region: ^Region) {
    if start.y < 0 || start.x < 0 {
        return
    }

    sizeY := len(lines)
    sizeX := len(lines[0])

    if start.y >= sizeY || start.x >= sizeX {
        return
    }

    if lines[start.y][start.x] != region.plant {
        return
    }

    if regions[start.y * sizeX + start.x] != nil {
        return
    }

    regions[start.y * sizeX + start.x] = region

    findRegion(lines, start + { -1,  0 }, regions, region)
    findRegion(lines, start + { +1,  0 }, regions, region)
    findRegion(lines, start + {  0, -1 }, regions, region)
    findRegion(lines, start + {  0, +1 }, regions, region)
}

parse :: proc (lines: []string) -> (regions: [dynamic]Region, regionsMap: []^Region, size: [2]int) {
    size = { len(lines[0]), len(lines) }

    regions = make([dynamic]Region)
    regionsMap = make([]^Region, size.x * size.y)

    // fill regionsMap
    for y in 0..<size.y {
        for x in 0..<size.x {
            if regionsMap[y * size.x + x] != nil {
                continue
            }

            append(&regions, Region{
                plant = lines[y][x],
                area = 0,
                perimeter = 0,
                sides = 0,
            })
            findRegion(lines, [2]int{ x, y }, &regionsMap, &regions[len(regions) - 1])
        }
    }

    return
}

part1 :: proc (regions: []Region, regionsMap: []^Region, size: [2]int) -> int {
    for y in 0..<size.y {
        for x in 0..<size.x {
            region := regionsMap[y * size.x + x]
            perimeter := 4
            if y != 0 {
                otherRegion := regionsMap[(y - 1) * size.x + x]
                if region == otherRegion {
                    perimeter -= 1
                }
            }

            if y + 1 < size.y {
                otherRegion := regionsMap[(y + 1) * size.x + x]
                if region == otherRegion {
                    perimeter -= 1
                }
            }

            if x != 0 {
                otherRegion := regionsMap[y * size.x + x - 1]
                if region == otherRegion {
                    perimeter -= 1
                }
            }

            if x + 1 < size.x {
                otherRegion := regionsMap[y * size.x + x + 1]
                if region == otherRegion {
                    perimeter -= 1
                }
            }

            region.area += 1
            region.perimeter += perimeter
        }
    }


    prices := 0
    for region in regions {
        fmt.printf("%c %v\n", region.plant, region)
        prices += region.area * region.perimeter
    }

    return prices
}

part2 :: proc (regions: []Region, regionsMap: []^Region, size: [2]int) -> int {
    for y in 0..<size.y {
        for x in 0..<size.x {
            region := regionsMap[y * size.x + x]
            
            // ---------------------------------
            // create a 3x3 frame
            // ---------------------------------
            frame := [9]^Region{}
            for yy in -1..=+1 {
                for xx in -1..=+1 {
                    frameIndex := (yy+1) * 3 + xx + 1
                    if x + xx < size.x && x + xx >= 0 && y + yy < size.y && y + yy >= 0 {
                        regionIndex := (y + yy) * size.y + (x + xx)
                        frame[frameIndex] = regionsMap[regionIndex]
                    } else {
                        frame[frameIndex] = nil
                    }
                }
            }

            // ---------------------------------
            // check if there is a new side
            // ---------------------------------
            newSides := 0

            // vertical new side

            // left side

            // A A A
            // -+
            // B|A A
            if frame[0] == region && frame[1] == region && frame[3] != region {
                newSides += 1
            }

            // B B B
            //  +---
            // B|A A
            if frame[1] != region && frame[3] != region {
                newSides += 1
            }

            // right side

            // A A A
            //    +-
            // A A|B
            if frame[1] == region && frame[2] == region && frame[5] != region {
                newSides += 1
            }

            // B B B
            // ---+
            // A A|B
            if frame[1] != region && frame[5] != region {
                newSides += 1
            }

            // horizontal sides

            // top
            
            // B B B
            //  +---
            // B|A A
            if frame[1] != region && frame[3] != region {
                newSides += 1
            }

            // A|B B
            //  +---
            // A A A
            if frame[0] == region && frame[3] == region && frame[1] != region {
                newSides += 1
            }

            // bot

            // B|A A
            //  +---
            // B B B
            if frame[3] != region && frame[7] != region {
                newSides += 1
            }

            // A A A
            //  +---
            // A|B B
            if frame[3] == region && frame[6] == region && frame[7] != region {
                newSides += 1
            }

            region.sides += newSides
        }
    }


    prices := 0
    for region in regions {
        fmt.printf("%c %v\n", region.plant, region)
        prices += region.area * region.sides
    }

    return prices
}
