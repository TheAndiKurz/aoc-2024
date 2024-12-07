const std = @import("std");

fn getLinesFromFile(allocator: std.mem.Allocator, filename: []const u8) !std.ArrayList([]const u8) {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var lines = std.ArrayList([]const u8).init(allocator);

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const line_mem = try allocator.alloc(u8, line.len);
        std.mem.copyForwards(u8, line_mem, line);
        try lines.append(line_mem);
    }

    return lines;
}

const Vector2 = struct {
    x: i32,
    y: i32,

    fn equal(self: *const Vector2, other: *const Vector2) bool {
        return self.x == other.x and self.y == other.y;
    }

    fn add(self: *const Vector2, other: *const Vector2) Vector2 {
        return Vector2{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    fn rotate(self: *const Vector2) Vector2 {
        return Vector2{
            .x = -self.y,
            .y = self.x,
        };
    }
};

const Cell = enum {
    Free,
    Obstacle,
    Visited,
};

const SetPositionError = error{ IndexOutOfRange, PlayerDirection };

const Map = struct {
    allocator: std.mem.Allocator,
    startPosition: Vector2,
    startDirection: Vector2,
    playerPos: Vector2,
    playerDirection: Vector2,
    size: Vector2,
    cells: []Cell,
    visitedDirections: [][4]bool,

    fn init(allocator: std.mem.Allocator, size: Vector2) !Map {
        const cells = try allocator.alloc(Cell, @intCast(size.x * size.y));
        const cellsDirections = try allocator.alloc([4]bool, @intCast(size.x * size.y));

        return Map{
            .allocator = allocator,
            .size = size,
            .cells = cells,
            .startPosition = undefined,
            .startDirection = undefined,
            .playerPos = undefined,
            .playerDirection = undefined,
            .visitedDirections = cellsDirections,
        };
    }

    fn setStart(self: *Map, position: Vector2, char: u8) !void {
        self.startPosition = position;
        self.playerPos = position;

        self.playerDirection = switch (char) {
            '^' => Vector2{ .x = 0, .y = -1 },
            '>' => Vector2{ .x = 1, .y = 0 },
            'v' => Vector2{ .x = 0, .y = 1 },
            '<' => Vector2{ .x = -1, .y = 0 },
            else => unreachable,
        };

        self.startDirection = self.playerDirection;
        self.startPosition = self.playerPos;

        _ = try self.setPosition(position, Cell.Visited);
    }

    fn deinit(self: *Map) void {
        self.allocator.free(self.visitedDirections);
        self.allocator.free(self.cells);
    }

    fn getPosition(self: *const Map, position: Vector2) ?Cell {
        if (position.x < 0 or position.y < 0 or self.size.y <= position.y or self.size.x <= position.x) {
            return null;
        }

        return self.cells[@intCast(position.y * self.size.x + position.x)];
    }

    fn setPosition(self: *Map, position: Vector2, value: Cell) SetPositionError!bool {
        if (position.x < 0 or position.y < 0 or self.size.y <= position.y or self.size.x <= position.x) {
            return error.IndexOutOfRange;
        }

        const index: usize = @intCast(position.y * self.size.x + position.x);
        self.cells[index] = value;

        const d = self.playerDirection;

        if (value != Cell.Visited) {
            return true;
        }

        // top
        if (std.meta.eql(d, Vector2{ .x = 0, .y = -1 })) {
            const r = self.visitedDirections[index][0];
            self.visitedDirections[index][0] = true;
            return !r;
        }

        // right
        if (std.meta.eql(d, Vector2{ .x = 1, .y = 0 })) {
            const r = self.visitedDirections[index][1];
            self.visitedDirections[index][1] = true;
            return !r;
        }

        // bottom
        if (std.meta.eql(d, Vector2{ .x = 0, .y = 1 })) {
            const r = self.visitedDirections[index][2];
            self.visitedDirections[index][2] = true;
            return !r;
        }

        // left
        if (std.meta.eql(d, Vector2{ .x = -1, .y = 0 })) {
            const r = self.visitedDirections[index][3];
            self.visitedDirections[index][3] = true;
            return !r;
        }

        std.debug.print("{any}\n", .{d});
        return error.PlayerDirection;
    }

    fn reset(self: *Map) void {
        for (self.visitedDirections) |*visitedDirection| {
            visitedDirection[0] = false;
            visitedDirection[1] = false;
            visitedDirection[2] = false;
            visitedDirection[3] = false;
        }

        self.playerPos = self.startPosition;
        self.playerDirection = self.startDirection;
    }
};

fn parse(allocator: std.mem.Allocator, lines: []const []const u8) !Map {
    var map = try Map.init(allocator, .{ .x = @intCast(lines[0].len), .y = @intCast(lines.len) });

    for (lines, 0..) |line, y| {
        for (line, 0..) |char, x| {
            const position = Vector2{ .x = @intCast(x), .y = @intCast(y) };

            switch (char) {
                '#' => _ = try map.setPosition(position, Cell.Obstacle),
                '^', '>', 'v', '<' => try map.setStart(position, char),
                else => _ = try map.setPosition(position, Cell.Free),
            }
        }
    }

    return map;
}

fn playerInMap(map: *Map) !bool {
    return map.playerPos.x > 0 and map.playerPos.y > 0 and map.playerPos.y < map.size.y and map.playerPos.x < map.size.x;
}

fn part1(map: *Map) !i32 {
    var count: i32 = 1;
    while (true) {
        const newPosition = map.playerPos.add(&map.playerDirection);

        const cell = map.getPosition(newPosition) orelse {
            return count;
        };

        if (cell == Cell.Obstacle) {
            map.playerDirection = map.playerDirection.rotate();
            continue;
        }

        if (cell == Cell.Free) {
            count += 1;
            _ = try map.setPosition(newPosition, Cell.Visited);
        }

        map.playerPos = newPosition;
    }
}

fn simulateLoop(map: *Map) !bool {
    while (true) {
        const newPosition = map.playerPos.add(&map.playerDirection);

        const cell = map.getPosition(newPosition) orelse {
            return false;
        };

        if (cell == Cell.Obstacle) {
            map.playerDirection = map.playerDirection.rotate();
            continue;
        }

        if (!try map.setPosition(newPosition, Cell.Visited)) {
            return true;
        }

        map.playerPos = newPosition;
    }
}

fn part2(map: *Map) !i32 {
    var count: i32 = 0;

    for (0..@intCast(map.size.y)) |y| {
        for (0..@intCast(map.size.x)) |x| {
            const position = Vector2{ .x = @intCast(x), .y = @intCast(y) };

            if (position.equal(&map.startPosition)) {
                continue;
            }

            if (map.getPosition(position).? == Cell.Obstacle) {
                continue;
            }

            _ = try map.setPosition(position, Cell.Obstacle);

            if (try simulateLoop(map)) {
                count += 1;
            }

            _ = try map.setPosition(position, Cell.Free);

            map.reset();
        }
    }

    return count;
}

test "part 1" {
    const allocator = std.testing.allocator;

    const lines = try getLinesFromFile(allocator, "./example.txt");
    defer {
        for (lines.items) |line| allocator.free(line);
        lines.deinit();
    }

    var map = try parse(allocator, lines.items);
    defer map.deinit();

    try std.testing.expectEqual(41, try part1(&map));
}

test "part 2 simulation" {
    const allocator = std.testing.allocator;

    const lines = try getLinesFromFile(allocator, "./example.txt");
    defer {
        for (lines.items) |line| allocator.free(line);
        lines.deinit();
    }

    var map = try parse(allocator, lines.items);
    defer map.deinit();

    const position = Vector2{ .x = 3, .y = 6 };

    _ = try map.setPosition(position, Cell.Obstacle);

    try std.testing.expectEqual(true, try simulateLoop(&map));
}

test "part 2" {
    const allocator = std.testing.allocator;

    const lines = try getLinesFromFile(allocator, "./example.txt");
    defer {
        for (lines.items) |line| allocator.free(line);
        lines.deinit();
    }

    var map = try parse(allocator, lines.items);
    defer map.deinit();

    try std.testing.expectEqual(6, try part2(&map));
}

pub fn main() !void {
    var allocator = std.heap.page_allocator;

    const lines = try getLinesFromFile(allocator, "./input.txt");
    defer {
        for (lines.items) |line| allocator.free(line);
        lines.deinit();
    }

    var map = try parse(allocator, lines.items);
    defer map.deinit();

    std.debug.print("part 1: {d}\n", .{try part1(&map)});
    std.debug.print("part 2: {d}\n", .{try part2(&map)});
}
