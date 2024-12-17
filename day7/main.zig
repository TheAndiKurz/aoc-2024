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

const Operators = enum {
    Add,
    Mul,
    Concat,

    pub fn format(self: *const Operators, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        if (fmt.len != 0) {
            std.fmt.invalidFmtError(fmt, self);
        }
        return switch (self.*) {
            Operators.Add => writer.print("+", .{}),
            Operators.Mul => writer.print("*", .{}),
            Operators.Concat => writer.print("||", .{}),
        };
    }
};

const Input = struct {
    allocator: std.mem.Allocator,
    result: u64,
    numbers: std.ArrayList(u64),

    fn init(allocator: std.mem.Allocator) !Input {
        const numbers = std.ArrayList(u64).init(allocator);

        return Input{
            .allocator = allocator,
            .result = 0,
            .numbers = numbers,
        };
    }

    fn deinit(self: *const Input) void {
        self.numbers.deinit();
    }

    fn applyOperators(self: *const Input, operators: []Operators) u64 {
        var result = self.numbers.items[0];
        for (operators, 1..) |operator, i| {
            switch (operator) {
                Operators.Add => result += self.numbers.items[i],
                Operators.Mul => result *= self.numbers.items[i],
                Operators.Concat => {
                    var num = self.numbers.items[i];
                    var num_reversed: u64 = 0;
                    while (num > 0) {
                        num_reversed *= 10;
                        num_reversed += num % 10;
                        num /= 10;
                    }

                    num = self.numbers.items[i];
                    while (num > 0) {
                        result *= 10;
                        result += num_reversed % 10;
                        num_reversed /= 10;
                        num /= 10;
                    }
                },
            }
        }

        return result;
    }
};

fn parse(allocator: std.mem.Allocator, lines: []const []const u8) ![]Input {
    var inputs = try allocator.alloc(Input, lines.len);

    for (lines, 0..) |line, y| {
        inputs[y] = try Input.init(allocator);
        var colonSplit = std.mem.split(u8, line, ":");
        const resultStr = colonSplit.next().?;

        inputs[y].result = try std.fmt.parseInt(u64, resultStr, 10);

        const numsStr = colonSplit.next().?;

        var splits = std.mem.split(u8, numsStr, " ");
        while (splits.next()) |split| {
            if (split.len == 0) {
                continue;
            }
            const num = try std.fmt.parseInt(u64, split, 10);
            try inputs[y].numbers.append(num);
        }
    }

    return inputs;
}

fn testOperators(input: *const Input, operators: *std.ArrayList(Operators)) !bool {
    const applied = input.applyOperators(operators.items);
    if (operators.items.len >= input.numbers.items.len - 1) {
        return applied == input.result;
    }

    if (applied > input.result) {
        return false;
    }

    try operators.append(Operators.Add);
    if (try testOperators(input, operators)) {
        return true;
    }

    operators.items[operators.items.len - 1] = Operators.Mul;
    if (try testOperators(input, operators)) {
        return true;
    }

    _ = operators.pop();
    return false;
}

fn part1(allocator: std.mem.Allocator, inputs: []const Input) !u64 {
    var result: u64 = 0;
    for (inputs) |*input| {
        var list = std.ArrayList(Operators).init(allocator);
        defer list.deinit();

        if (try testOperators(input, &list)) {
            result += input.result;
        }
    }

    return result;
}

fn testOperators2(input: *const Input, operators: *std.ArrayList(Operators)) !bool {
    const applied = input.applyOperators(operators.items);
    if (operators.items.len >= input.numbers.items.len - 1) {
        return applied == input.result;
    }

    if (applied > input.result) {
        return false;
    }

    try operators.append(Operators.Add);
    if (try testOperators2(input, operators)) {
        return true;
    }

    operators.items[operators.items.len - 1] = Operators.Mul;
    if (try testOperators2(input, operators)) {
        return true;
    }

    operators.items[operators.items.len - 1] = Operators.Concat;
    if (try testOperators2(input, operators)) {
        return true;
    }

    _ = operators.pop();
    return false;
}

fn part2(allocator: std.mem.Allocator, inputs: []const Input) !u64 {
    var result: u64 = 0;
    for (inputs) |*input| {
        var list = std.ArrayList(Operators).init(allocator);
        defer list.deinit();

        if (try testOperators2(input, &list)) {
            result += input.result;
        }
    }

    return result;
}

test "part 1" {
    const allocator = std.testing.allocator;

    const lines = try getLinesFromFile(allocator, "./example.txt");
    defer {
        for (lines.items) |line| allocator.free(line);
        lines.deinit();
    }

    const inputs = try parse(allocator, lines.items);
    defer {
        for (inputs) |*input| input.deinit();
        allocator.free(inputs);
    }

    try std.testing.expectEqual(3749, try part1(allocator, inputs));
}

test "test operators2" {
    const allocator = std.testing.allocator;
    var input = try Input.init(allocator);
    defer input.deinit();

    input.result = 7290;
    try input.numbers.append(6);
    try input.numbers.append(8);
    try input.numbers.append(6);
    try input.numbers.append(15);

    var list = std.ArrayList(Operators).init(allocator);
    defer list.deinit();
    const result = testOperators2(&input, &list);
    try std.testing.expectEqual(true, result);
}

test "part 2" {
    const allocator = std.testing.allocator;

    const lines = try getLinesFromFile(allocator, "./example.txt");
    defer {
        for (lines.items) |line| allocator.free(line);
        lines.deinit();
    }

    const inputs = try parse(allocator, lines.items);
    defer {
        for (inputs) |*input| input.deinit();
        allocator.free(inputs);
    }

    try std.testing.expectEqual(11387, try part2(allocator, inputs));
}

pub fn main() !void {
    var allocator = std.heap.page_allocator;

    const lines = try getLinesFromFile(allocator, "./input.txt");
    defer {
        for (lines.items) |line| allocator.free(line);
        lines.deinit();
    }

    const inputs = try parse(allocator, lines.items);
    defer {
        for (inputs) |*input| input.deinit();
        allocator.free(inputs);
    }

    std.debug.print("part 1: {d}\n", .{try part1(allocator, inputs)});
    std.debug.print("part 2: {d}\n", .{try part2(allocator, inputs)});
}
