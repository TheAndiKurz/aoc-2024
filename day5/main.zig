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

const Input = struct {
    allocator: std.mem.Allocator,
    ordering: std.AutoHashMap(i32, std.ArrayList(i32)),
    pageNumbers: std.ArrayList(std.ArrayList(i32)),

    fn init(allocator: std.mem.Allocator) Input {
        return Input{
            .allocator = allocator,
            .ordering = std.AutoHashMap(i32, std.ArrayList(i32)).init(allocator),
            .pageNumbers = std.ArrayList(std.ArrayList(i32)).init(allocator),
        };
    }

    fn deinit(self: *Input) void {
        var it = self.ordering.valueIterator();
        while (it.next()) |list| {
            list.deinit();
        }
        self.ordering.deinit();

        for (self.pageNumbers.items) |pageNumber| {
            pageNumber.deinit();
        }
        self.pageNumbers.deinit();
    }

    fn contains(self: *Input, num: i32) bool {
        return self.ordering.contains(num);
    }

    fn addOrdering(self: *Input, num1: i32, num2: i32) !void {
        if (!self.contains(num1)) {
            try self.ordering.put(num1, std.ArrayList(i32).init(self.allocator));
        }

        try self.ordering.getPtr(num1).?.append(num2);
    }

    fn addPageNumber(self: *Input, line: []const u8) !void {
        var pageNumber = std.ArrayList(i32).init(self.allocator);
        var it = std.mem.split(u8, line, ",");

        while (it.next()) |x| {
            try pageNumber.append(try std.fmt.parseInt(i32, x, 10));
        }

        try self.pageNumbers.append(pageNumber);
    }
};

fn parse(allocator: std.mem.Allocator, lines: []const []const u8) !Input {
    var input = Input.init(allocator);

    var secondBegining = lines.len;
    for (lines, 0..) |line, i| {
        if (line.len == 0) {
            secondBegining = i + 1;
            break;
        }

        const num1 = try std.fmt.parseInt(i32, line[0..2], 10);
        const num2 = try std.fmt.parseInt(i32, line[3..5], 10);

        try input.addOrdering(num1, num2);
    }

    for (lines[secondBegining..]) |line| {
        try input.addPageNumber(line);
    }

    return input;
}

fn listContains(list: []const i32, num: i32) bool {
    for (list) |n| {
        if (num == n) return true;
    }

    return false;
}

fn isGoodLine(input: *Input, list: []const i32) !bool {
    if (list.len == 1) return true;

    const lower = input.ordering.get(list[0]) orelse {
        return false;
    };

    for (list[1..]) |n| {
        if (!listContains(lower.items, n)) {
            return false;
        }
    }

    return isGoodLine(input, list[1..]);
}

fn compare(input: *Input, num1: i32, num2: i32) bool {
    const lower1 = input.ordering.get(num1) orelse {
        return true;
    };

    if (listContains(lower1.items, num2)) {
        return false;
    }

    return true;
}

fn orderLine(input: *Input, list: []i32) !void {
    std.mem.sort(i32, list, input, compare);
}

fn part1(allocator: std.mem.Allocator, lines: []const []const u8) !i32 {
    var input = try parse(allocator, lines);
    defer input.deinit();

    var sum: i32 = 0;
    for (input.pageNumbers.items) |pageNumbers| {
        const items = pageNumbers.items;
        if (try isGoodLine(&input, items)) {
            sum += items[items.len / 2];
        }
    }

    return sum;
}

fn part2(allocator: std.mem.Allocator, lines: []const []const u8) !i32 {
    var input = try parse(allocator, lines);
    defer input.deinit();

    std.debug.print("{any}\n", .{&input});

    var sum: i32 = 0;
    for (input.pageNumbers.items) |pageNumbers| {
        const items = pageNumbers.items;
        if (!try isGoodLine(&input, items)) {
            try orderLine(&input, items);
            sum += items[items.len / 2];
        }
    }

    return sum;
}

test "part 1" {
    const lines = try getLinesFromFile(std.testing.allocator, "./example.txt");
    defer {
        for (lines.items) |line| {
            std.testing.allocator.free(line);
        }
        lines.deinit();
    }

    const result = try part1(std.testing.allocator, lines.items);

    try std.testing.expectEqual(result, 143);
}

test "part 2" {
    const lines = try getLinesFromFile(std.testing.allocator, "./example.txt");
    defer {
        for (lines.items) |line| {
            std.testing.allocator.free(line);
        }
        lines.deinit();
    }

    const result = try part2(std.testing.allocator, lines.items);

    try std.testing.expectEqual(result, 123);
}

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;

    const linesList = try getLinesFromFile(allocator, "./example.txt");
    const lines = linesList.items;
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
        linesList.deinit();
    }

    std.debug.print("part 1: {d}\n", .{try part1(allocator, lines)});
    std.debug.print("part 2: {d}\n", .{try part2(allocator, lines)});
}
