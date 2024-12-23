const std = @import("std");
const Allocator = std.mem.Allocator;

const Vec2 = struct {
    x: u8,
    y: u8,
};

const NUMPAD = &[_][]const u8{ "789", "456", "123", ".0A" };
const DIRECTIONAL_ROBOT = &[_][]const u8{ ".^A", "<v>" };

const DIRECTIONAL_POSITIONS = blk: {
    var POSITIONS: [255]Vec2 = undefined;
    POSITIONS['^'] = Vec2{ .x = 1, .y = 0 };
    POSITIONS['A'] = Vec2{ .x = 2, .y = 0 };
    POSITIONS['<'] = Vec2{ .x = 0, .y = 1 };
    POSITIONS['v'] = Vec2{ .x = 1, .y = 1 };
    POSITIONS['>'] = Vec2{ .x = 2, .y = 1 };
    break :blk POSITIONS;
};

const NUMPAD_POSITIONS = blk: {
    var POSITIONS: [255]Vec2 = undefined;
    POSITIONS['7'] = Vec2{ .x = 0, .y = 0 };
    POSITIONS['8'] = Vec2{ .x = 1, .y = 0 };
    POSITIONS['9'] = Vec2{ .x = 2, .y = 0 };
    POSITIONS['4'] = Vec2{ .x = 0, .y = 1 };
    POSITIONS['5'] = Vec2{ .x = 1, .y = 1 };
    POSITIONS['6'] = Vec2{ .x = 2, .y = 1 };
    POSITIONS['1'] = Vec2{ .x = 0, .y = 2 };
    POSITIONS['2'] = Vec2{ .x = 1, .y = 2 };
    POSITIONS['3'] = Vec2{ .x = 2, .y = 2 };
    POSITIONS['0'] = Vec2{ .x = 1, .y = 3 };
    POSITIONS['A'] = Vec2{ .x = 2, .y = 3 };
    break :blk POSITIONS;
};

const CacheKey = packed struct {
    start: u8,
    end: u8,
    intermediaries: u8,
};

const Cache = std.AutoHashMap(CacheKey, u64);

pub fn shortest_sequence(cache: *Cache, grid: []const []const u8, start: u8, end: u8, intermediaries: u8, max_robots: u8) Allocator.Error!u64 {
    const key = CacheKey{
        .start = start,
        .end = end,
        .intermediaries = intermediaries,
    };

    if (cache.get(key)) |v| return v;

    const end_pos = if (intermediaries == max_robots) NUMPAD_POSITIONS[end] else DIRECTIONAL_POSITIONS[end];
    const start_pos = if (intermediaries == max_robots) NUMPAD_POSITIONS[start] else DIRECTIONAL_POSITIONS[start];

    const sx = start_pos.x;
    const sy = start_pos.y;
    const ex = end_pos.x;
    const ey = end_pos.y;

    const x_diff = if (ex > sx) ex - sx else sx - ex;
    const y_diff = if (ey > sy) ey - sy else sy - ey;

    if (intermediaries == 0) {
        return @intCast(x_diff + y_diff + 1);
    }

    const v: u8 = if (sy > ey) '^' else 'v';
    const h: u8 = if (sx > ex) '<' else '>';

    // This way avoids allocating a slice

    const aa = try shortest_sequence(cache, DIRECTIONAL_ROBOT, 'A', 'A', intermediaries - 1, max_robots);
    const av = try shortest_sequence(cache, DIRECTIONAL_ROBOT, 'A', v, intermediaries - 1, max_robots);
    const vv = if (y_diff > 1) (y_diff - 1) * try shortest_sequence(cache, DIRECTIONAL_ROBOT, v, v, intermediaries - 1, max_robots) else 0;
    const vh = try shortest_sequence(cache, DIRECTIONAL_ROBOT, v, h, intermediaries - 1, max_robots);
    const hh = if (x_diff > 1) (x_diff - 1) * try shortest_sequence(cache, DIRECTIONAL_ROBOT, h, h, intermediaries - 1, max_robots) else 0;
    const ha = try shortest_sequence(cache, DIRECTIONAL_ROBOT, h, 'A', intermediaries - 1, max_robots);
    const ah = try shortest_sequence(cache, DIRECTIONAL_ROBOT, 'A', h, intermediaries - 1, max_robots);
    const hv = try shortest_sequence(cache, DIRECTIONAL_ROBOT, h, v, intermediaries - 1, max_robots);
    const va = try shortest_sequence(cache, DIRECTIONAL_ROBOT, v, 'A', intermediaries - 1, max_robots);

    const result = if (x_diff == 0 and y_diff == 0) blk: {
        break :blk aa;
    } else if (x_diff == 0) blk: {
        // only vertical
        break :blk av + vv + va;
    } else if (y_diff == 0) blk: {
        // Horizontal only
        break :blk ah + hh + ha;
    } else blk: {
        // Both horizontal and vertical

        const a_cost = av + vv + vh + hh + ha;
        const b_cost = ah + hh + hv + vv + va;

        if (grid[sy][ex] == '.') break :blk a_cost;
        if (grid[ey][sx] == '.') break :blk b_cost;

        break :blk @min(a_cost, b_cost);
    };

    try cache.put(key, result);
    return result;
}

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("sum of complexities (2 robots): {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u64 {
    var ans: u64 = 0;

    const file = try std.fs.cwd().openFile("puzzle_input/day21.txt", .{});
    defer file.close();

    var buffer: [1024]u8 = undefined;
    var reader = file.reader();

    var cache = Cache.init(allocator);
    defer cache.deinit();

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        if (line.len == 0) continue;

        var shortest: u64 = 0;

        shortest += try shortest_sequence(&cache, NUMPAD, 'A', line[0], 2, 2);
        var it = std.mem.window(u8, line, 2, 1);
        while (it.next()) |c| {
            shortest += try shortest_sequence(&cache, NUMPAD, c[0], c[1], 2, 2);
        }

        ans += shortest * try std.fmt.parseInt(u32, line[0 .. line.len - 1], 10);
    }

    return ans;
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("sum of complexities (25 robots): {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u64 {
    var ans: u64 = 0;

    const file = try std.fs.cwd().openFile("puzzle_input/day21.txt", .{});
    defer file.close();

    var buffer: [1024]u8 = undefined;
    var reader = file.reader();

    var cache = Cache.init(allocator);
    defer cache.deinit();

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        if (line.len == 0) continue;

        var shortest: u64 = 0;

        shortest += try shortest_sequence(&cache, NUMPAD, 'A', line[0], 25, 25);
        var it = std.mem.window(u8, line, 2, 1);
        while (it.next()) |c| {
            shortest += try shortest_sequence(&cache, NUMPAD, c[0], c[1], 25, 25);
        }

        ans += shortest * try std.fmt.parseInt(u32, line[0 .. line.len - 1], 10);
    }

    return ans;
}
