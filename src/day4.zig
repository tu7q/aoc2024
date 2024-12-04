const std = @import("std");
const Allocator = std.mem.Allocator;

// Too many terrible integer casts.

fn Vec2(T: type) type {
    return struct { x: T, y: T };
}

// Note that this iterator does not include the first character.
const WordSearchIterator = struct {
    puzzle: [][]const u8,
    direction: Vec2(i8),
    indices: ?Vec2(u32),
    w: u32,
    h: u32,

    pub fn next(self: *@This()) ?u8 {
        const start = self.indices orelse return null;
        const next_index = Vec2(i32){ // i32 to detect when index goes out of bounds.
            .x = @as(i32, @intCast(start.x)) + self.direction.x,
            .y = @as(i32, @intCast(start.y)) + self.direction.y,
        };

        if (next_index.x >= self.w or next_index.x < 0 or next_index.y >= self.h or next_index.y < 0) {
            self.indices = null;
            return null;
        }
        self.indices = Vec2(u32){
            .x = @intCast(next_index.x),
            .y = @intCast(next_index.y),
        };
        return self.puzzle[self.indices.?.y][self.indices.?.x];
    }
};

fn countOccurencesAround(puzzle: [][]const u8, from: Vec2(u32), match: []const u8) u32 {
    std.debug.assert(puzzle.len > 0);

    if (puzzle[from.y][from.x] != match[0]) {
        return 0;
    }

    var occurences: u32 = 0;

    const h: u32 = @intCast(puzzle.len);
    const w: u32 = @intCast(puzzle[0].len);

    for (0..3) |y| {
        for (0..3) |x| {
            if (y == 1 and x == 1) continue;
            var it = WordSearchIterator{
                .puzzle = puzzle,
                .direction = Vec2(i8){ .x = @as(i8, @intCast(x)) - 1, .y = @as(i8, @intCast(y)) - 1 },
                .indices = from,
                .w = w,
                .h = h,
            };

            // var i: u32 = 1;
            for (1..match.len) |i| {
                const c = it.next() orelse break;
                if (c != match[i]) break;
            } else {
                occurences += 1;
            }
        }
    }

    return occurences;
}

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("'XMAS' occurrences: {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u32 {
    var occurences: u32 = 0;

    var puzzle = std.ArrayList([]const u8).init(allocator);
    defer puzzle.deinit();

    const file = try std.fs.cwd().openFile("puzzle_input/day4.txt", .{});
    defer file.close();

    var reader = file.reader();

    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        try puzzle.append(line);
    }

    const MATCH: []const u8 = "XMAS";

    std.debug.assert(puzzle.items.len > 0);
    const h = puzzle.items.len;
    const w = puzzle.items[0].len;

    for (0..h) |y| {
        for (0..w) |x| {
            occurences += countOccurencesAround(puzzle.items, Vec2(u32){ .x = @intCast(x), .y = @intCast(y) }, MATCH);
        }
    }

    return occurences;
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("'X-MAS' occurrences {d}\n", .{result}); // struggling to spell.
}

pub fn solutionTwo(allocator: Allocator) !u32 {
    var occurences: u32 = 0;

    var puzzle = std.ArrayList([]const u8).init(allocator);
    defer puzzle.deinit();

    const file = try std.fs.cwd().openFile("puzzle_input/day4.txt", .{});
    defer file.close();

    var reader = file.reader();

    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        try puzzle.append(line);
    }

    std.debug.assert(puzzle.items.len > 0);
    const h = puzzle.items.len;
    const w = puzzle.items[0].len;

    if (w < 3 or h < 3) {
        return 0;
    }

    for (0..h - 2) |y| {
        for (0..w - 2) |x| {
            // x,y are topleft.
            if (puzzle.items[y + 1][x + 1] != 'A') continue;
            const topleft = puzzle.items[y][x];
            switch (topleft) {
                'M' => if (puzzle.items[y + 2][x + 2] != 'S') continue,
                'S' => if (puzzle.items[y + 2][x + 2] != 'M') continue,
                else => continue,
            }
            const topright = puzzle.items[y][x + 2];
            switch (topright) {
                'M' => if (puzzle.items[y + 2][x] != 'S') continue,
                'S' => if (puzzle.items[y + 2][x] != 'M') continue,
                else => continue,
            }

            occurences += 1;
        }
    }

    return occurences;
}
