const std = @import("std");
const Allocator = std.mem.Allocator;

const Direction = enum {
    North,
    West,
    South,
    East,
};

// Doesn't compile with
// const Vec2 = struct {
const Vec2 = struct {
    x: u32,
    y: u32,
};

const Bounds = struct {
    min_x: u32,
    min_y: u32,
    max_x: u32,
    max_y: u32,

    pub fn contains(self: @This(), p: Vec2) bool {
        if (p.x >= self.min_x and p.x <= self.max_x and p.y >= self.min_y and p.y <= self.max_y) {
            return true;
        }
        return false;
    }
};

const PathElem = struct {
    dir: Direction,
    loc: Vec2,
};

fn findPath(allocator: Allocator, origin: Vec2, origin_dir: Direction, obstructions: [][]bool, bounds: Bounds) !?[]PathElem {
    var path = std.ArrayList(PathElem).init(allocator);

    var seen = std.AutoHashMap(PathElem, void).init(allocator);
    defer seen.deinit();

    var current = origin;
    var facing = origin_dir;

    while (bounds.contains(current)) {
        const next = switch (facing) {
            .North => Vec2{ .x = current.x, .y = current.y - 1 },
            .East => Vec2{ .x = current.x + 1, .y = current.y },
            .South => Vec2{ .x = current.x, .y = current.y + 1 },
            .West => Vec2{ .x = current.x - 1, .y = current.y },
        };
        if (bounds.contains(next) and obstructions[next.y - bounds.min_y][next.x - bounds.min_x]) {
            switch (facing) {
                .North => facing = .East,
                .East => facing = .South,
                .South => facing = .West,
                .West => facing = .North,
            }
        } else {
            const elem = PathElem{ .loc = current, .dir = facing };
            if ((try seen.getOrPut(elem)).found_existing) return null;
            try path.append(elem);

            current = next;
        }
    }

    return try path.toOwnedSlice();
}

const ProblemInput = struct {
    guard: Vec2,
    facing: Direction,
    obstructions: [][]bool,
    bounds: Bounds,

    pub fn readInput(allocator: Allocator, file: std.fs.File) !@This() {
        var reader = file.reader();
        var buf: [1024]u8 = undefined;

        var obstructions = std.ArrayList([]bool).init(allocator);

        var guard: Vec2 = undefined;
        var facing: Direction = undefined;

        var bounds: Bounds = .{
            .min_x = 1,
            .min_y = 1,
            .max_x = undefined,
            .max_y = undefined,
        };

        var y: u32 = bounds.min_y;
        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line_lf| : (y += 1) {
            const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
            if (line.len == 0) break;

            bounds.max_x = @intCast(line.len);

            {
                const line_obstructions = try allocator.alloc(bool, line.len);
                @memset(line_obstructions, false);
                try obstructions.append(line_obstructions);
            }

            for (line, bounds.min_x..) |char, x| {
                switch (char) {
                    '#' => obstructions.items[y - bounds.min_y][x - bounds.min_x] = true,
                    '^' => {
                        guard = .{ .x = @intCast(x), .y = y };
                        facing = .North;
                    },
                    '.' => {},
                    else => unreachable,
                }
            }
        }
        bounds.max_y = y - 1;

        return .{
            .guard = guard,
            .facing = facing,
            .obstructions = try obstructions.toOwnedSlice(),
            .bounds = bounds,
        };
    }

    pub fn deinit(self: @This(), allocator: Allocator) void {
        for (self.obstructions) |line_obs| {
            allocator.free(line_obs);
        }
        allocator.free(self.obstructions);
    }
};

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("distinct positions: {d}\n", .{result});
}

// Solution is a coordinate mess.
pub fn solutionOne(allocator: Allocator) !u32 {
    const file = try std.fs.cwd().openFile("puzzle_input/day6.txt", .{});
    defer file.close();

    const input = try ProblemInput.readInput(allocator, file);
    defer input.deinit(allocator);

    const path = (try findPath(
        allocator,
        input.guard,
        input.facing,
        input.obstructions,
        input.bounds,
    )).?;
    defer allocator.free(path);

    var distinct_positions = std.AutoArrayHashMap(Vec2, void).init(allocator);
    defer distinct_positions.deinit();

    for (path) |elem| {
        try distinct_positions.put(elem.loc, {});
    }

    return @intCast(distinct_positions.count());
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("different positions to cause loop: {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u32 {
    const file = try std.fs.cwd().openFile("puzzle_input/day6.txt", .{});
    defer file.close();

    const input = try ProblemInput.readInput(allocator, file);
    defer input.deinit(allocator);

    const path = (try findPath(
        allocator,
        input.guard,
        input.facing,
        input.obstructions,
        input.bounds,
    )).?;
    defer allocator.free(path);

    var cycles: u32 = 0;

    var distinct_positions = std.AutoArrayHashMap(Vec2, void).init(allocator);
    defer distinct_positions.deinit();

    var it = std.mem.window(PathElem, path, 2, 1);
    while (it.next()) |elems| {
        const x = elems[1].loc.x - input.bounds.min_x;
        const y = elems[1].loc.y - input.bounds.min_y;

        if (distinct_positions.contains(Vec2{ .x = x, .y = y })) {
            continue;
        }

        input.obstructions[y][x] = true;
        defer input.obstructions[y][x] = false;

        if (try findPath(allocator, elems[0].loc, elems[0].dir, input.obstructions, input.bounds)) |p| {
            allocator.free(p);
        } else {
            cycles += 1;
        }

        try distinct_positions.put(Vec2{ .x = x, .y = y }, {});
    }

    return cycles;
}
