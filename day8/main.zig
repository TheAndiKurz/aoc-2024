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

    fn sub(self: *const Vector2, other: *const Vector2) Vector2 {
        return Vector2{
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }

    fn neg(self: *const Vector2) Vector2 {
        return Vector2{
            .x = -self.x,
            .y = -self.y,
        };
    }

    fn rotate(self: *const Vector2) Vector2 {
        return Vector2{
            .x = -self.y,
            .y = self.x,
        };
    }

    pub fn format(self: *const Vector2, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("(x:{d}, y:{d})", .{ self.x, self.y });
    }
};

const IndexError = error{ IndexOutOfRange, InvalidCharacter };

const Antennas = struct {
    allocator: std.mem.Allocator,
    locations: std.ArrayList(Vector2),

    fn init(allocator: std.mem.Allocator) Antennas {
        return Antennas{
            .allocator = allocator,
            .locations = std.ArrayList(Vector2).init(allocator),
        };
    }

    fn deinit(self: *const Antennas) void {
        self.locations.deinit();
    }

    fn isValid(char: u8) bool {
        return switch (char) {
            '0'...'9' => true,
            'a'...'z' => true,
            'A'...'Z' => true,
            else => false,
        };
    }

    fn getIndex(char: u8) IndexError!usize {
        return switch (char) {
            '0'...'9' => @intCast(char - '0'),
            'a'...'z' => @intCast(char - 'a' + 10),
            'A'...'Z' => @intCast(char - 'A' + 10 + 26),
            else => error.InvalidCharacter,
        };
    }
};

const AntiNodeMapCell = enum {
    Nothing,
    AntiNode,
};

const AntiNodeMap = struct {
    allocator: std.mem.Allocator,
    size: Vector2,
    field: []AntiNodeMapCell,
    concern: [][2]Vector2,

    fn init(allocator: std.mem.Allocator, size: Vector2) !AntiNodeMap {
        const map = AntiNodeMap{
            .allocator = allocator,
            .size = size,
            .field = try allocator.alloc(AntiNodeMapCell, @intCast(size.x * size.y)),
            .concern = try allocator.alloc([2]Vector2, @intCast(size.x * size.y)),
        };

        for (map.field) |*field| {
            field.* = AntiNodeMapCell.Nothing;
        }

        return map;
    }

    fn deinit(self: *AntiNodeMap) void {
        self.allocator.free(self.field);
        self.allocator.free(self.concern);
    }

    fn setAntiNode(self: *AntiNodeMap, position: Vector2, p1: Vector2, p2: Vector2) bool {
        if (0 > position.x or position.x >= self.size.x) {
            return false;
        }

        if (0 > position.y or position.y >= self.size.y) {
            return false;
        }

        const index: usize = @intCast(position.x + self.size.x * position.y);

        self.field[index] = AntiNodeMapCell.AntiNode;

        self.concern[index][0] = p1;
        self.concern[index][1] = p2;

        return true;
    }

    fn registerAntinodes(self: *AntiNodeMap, p1: Vector2, p2: Vector2) void {
        const diff = p1.sub(&p2);
        const antiNodePos1 = p1.add(&diff);
        _ = self.setAntiNode(antiNodePos1, p1, p2);

        const antiNodePos2 = p2.add(&diff.neg());
        _ = self.setAntiNode(antiNodePos2, p1, p2);
    }

    fn registerAntinodes2(self: *AntiNodeMap, p1: Vector2, p2: Vector2) void {
        var diff = p1.sub(&p2);
        var antiNodePos = p1;
        while (self.setAntiNode(antiNodePos, p1, p2)) {
            antiNodePos = antiNodePos.add(&diff);
        }

        diff = diff.neg();
        antiNodePos = p2;
        while (self.setAntiNode(antiNodePos, p1, p2)) {
            antiNodePos = antiNodePos.add(&diff);
        }
    }

    fn getConcern(self: *AntiNodeMap, position: Vector2) ![2]Vector2 {
        if (0 > position.x or position.x >= self.size.x) {
            return error.IndexOutOfRange;
        }

        if (0 > position.y or position.y >= self.size.y) {
            return error.IndexOutOfRange;
        }

        const index: usize = @intCast(position.x + self.size.x * position.y);

        return self.concern[index];
    }

    pub fn format(self: *const AntiNodeMap, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        const sizeX: usize = @intCast(self.size.x);
        const sizeY: usize = @intCast(self.size.y);

        for (0..sizeY) |y| {
            for (0..sizeX) |x| {
                const index = x + y * sizeX;
                if (self.field[index] == AntiNodeMapCell.AntiNode) {
                    try writer.print("#", .{});
                } else {
                    try writer.print(".", .{});
                }
            }
            try writer.print("\n", .{});
        }
    }
};

const Map = struct {
    allocator: std.mem.Allocator,
    size: Vector2,
    antennas: [62]Antennas,

    fn init(allocator: std.mem.Allocator, size: Vector2) Map {
        var map = Map{
            .allocator = allocator,
            .size = size,
            .antennas = undefined,
        };

        for (0..map.antennas.len) |i| {
            map.antennas[i] = Antennas.init(allocator);
        }

        return map;
    }

    fn deinit(self: *Map) void {
        for (self.antennas) |antenna| {
            antenna.deinit();
        }
    }

    fn addAntenna(self: *Map, char: u8, position: Vector2) !void {
        const index = try Antennas.getIndex(char);
        try self.antennas[index].locations.append(position);
    }
};

fn parse(allocator: std.mem.Allocator, lines: []const []const u8) !Map {
    var map = Map.init(allocator, .{ .x = @intCast(lines[0].len), .y = @intCast(lines.len) });

    for (lines, 0..) |line, y| {
        for (line, 0..) |char, x| {
            if (!Antennas.isValid(char)) {
                continue;
            }

            const position = Vector2{ .x = @intCast(x), .y = @intCast(y) };

            try map.addAntenna(char, position);
        }
    }

    return map;
}

fn part1(allocator: std.mem.Allocator, map: *Map) !u32 {
    var antiNodeMap = try AntiNodeMap.init(allocator, map.size);
    defer antiNodeMap.deinit();
    for (map.antennas) |antenna| {
        for (antenna.locations.items, 0..) |l1, i| {
            for (antenna.locations.items[i + 1 ..]) |l2| {
                antiNodeMap.registerAntinodes(l1, l2);
            }
        }
    }

    var count: u32 = 0;
    const sizeX: usize = @intCast(antiNodeMap.size.x);
    const sizeY: usize = @intCast(antiNodeMap.size.y);
    for (0..sizeY) |y| {
        for (0..sizeX) |x| {
            const index = x + y * sizeX;
            if (antiNodeMap.field[index] == AntiNodeMapCell.AntiNode) {
                count += 1;
            }
        }
    }

    return count;
}

fn part2(allocator: std.mem.Allocator, map: *Map) !u32 {
    var antiNodeMap = try AntiNodeMap.init(allocator, map.size);
    defer antiNodeMap.deinit();
    for (map.antennas) |antenna| {
        for (antenna.locations.items, 0..) |l1, i| {
            for (antenna.locations.items[i + 1 ..]) |l2| {
                antiNodeMap.registerAntinodes2(l1, l2);
            }
        }
    }

    var count: u32 = 0;
    const sizeX: usize = @intCast(antiNodeMap.size.x);
    const sizeY: usize = @intCast(antiNodeMap.size.y);
    for (0..sizeY) |y| {
        for (0..sizeX) |x| {
            const index = x + y * sizeX;
            if (antiNodeMap.field[index] == AntiNodeMapCell.AntiNode) {
                count += 1;
            }
        }
    }

    return count;
}

test "index in antennas" {
    for (0.., "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ") |e, c| {
        try std.testing.expectEqual(true, Antennas.isValid(c));
        try std.testing.expectEqual(e, try Antennas.getIndex(c));
    }
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

    try std.testing.expectEqual(14, try part1(allocator, &map));
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

    try std.testing.expectEqual(34, try part2(allocator, &map));
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

    std.debug.print("part 1: {d}\n", .{try part1(allocator, &map)});
    std.debug.print("part 2: {d}\n", .{try part2(allocator, &map)});
}
