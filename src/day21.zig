const std = @import("std");
const Allocator = std.mem.Allocator;

// For each character the final robot must be on that character whilst all of the robots must be on the A.
// Prefer straight paths rather than turns.

const NUMPAD = &[_][]const u8{ "789", "456", "123", ".0A" };
const DIRECTIONAL_ROBOT = &[_][]const u8{ ".^A", "<v>" };

const CacheKey = struct {
    start: u8,
    end: u8,
    intermediaries: u32,
};

const Cache = std.AutoHashMap(CacheKey, u64);

pub fn shortest_sequence(cache: *Cache, grid: []const []const u8, start: u8, end: u8, intermediaries: u32, max_robots: u32) !u64 {
    const key = CacheKey{
        .start = start,
        .end = end,
        .intermediaries = intermediaries,
    };
    if (cache.get(key)) |v| return v;

    var sx: usize = 0;
    var sy: usize = 0;
    var ex: usize = 0;
    var ey: usize = 0;

    for (grid, 0..) |row, y| {
        if (std.mem.indexOfScalar(u8, row, start)) |x| {
            sx = x;
            sy = y;
        }
        if (std.mem.indexOfScalar(u8, row, end)) |x| {
            ex = x;
            ey = y;
        }
    }

    const x_diff = @abs(@as(isize, @intCast(ex)) - @as(isize, @intCast(sx)));
    const y_diff = @abs(@as(isize, @intCast(ey)) - @as(isize, @intCast(sy)));

    if (intermediaries == 0) {
        return @intCast(x_diff + y_diff + 1);
    }

    const v: u8 = if (sy > ey) '^' else 'v';
    const h: u8 = if (sx > ex) '<' else '>';

    // TODO: Remove this badness.
    var heap = std.heap.HeapAllocator.init();
    defer heap.deinit();
    const allocator = heap.allocator();

    const vertical = allocator.alloc(u8, y_diff) catch unreachable;
    defer allocator.free(vertical);
    @memset(vertical, v);

    const horizontal = allocator.alloc(u8, x_diff) catch unreachable;
    defer allocator.free(horizontal);
    @memset(horizontal, h);

    const a = std.fmt.allocPrint(allocator, "A{s}{s}A", .{ vertical, horizontal }) catch unreachable;
    defer allocator.free(a);

    const b = std.fmt.allocPrint(allocator, "A{s}{s}A", .{ horizontal, vertical }) catch unreachable;
    defer allocator.free(b);

    const a_cost = blk: {
        var sum: u64 = 0;

        var it = std.mem.window(u8, a, 2, 1);
        while (it.next()) |window| {
            sum += try shortest_sequence(cache, DIRECTIONAL_ROBOT, window[0], window[1], intermediaries - 1, max_robots);
        }

        break :blk sum;
    };

    const b_cost = blk: {
        var sum: u64 = 0;

        var it = std.mem.window(u8, b, 2, 1);
        while (it.next()) |window| {
            sum += try shortest_sequence(cache, DIRECTIONAL_ROBOT, window[0], window[1], intermediaries - 1, max_robots);
        }

        break :blk sum;
    };

    const result = blk: {
        const hsign: isize = if (h == '>') 1 else -1;
        for (1..horizontal.len + 1) |offset| {
            const f: isize = @as(isize, @intCast(offset)) * hsign;
            const x: usize = @intCast(@as(isize, @intCast(sx)) + f);
            if (grid[sy][x] == '.') break :blk a_cost;
        }

        const vsign: isize = if (v == 'v') 1 else -1;
        for (1..vertical.len + 1) |offset| {
            const f: isize = @as(isize, @intCast(offset)) * vsign;
            const y: usize = @intCast(@as(isize, @intCast(sy)) + f);
            if (grid[y][sx] == '.') break :blk b_cost;
        }

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

        std.debug.print("length: {d}\n", .{shortest});

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

        std.debug.print("length: {d}\n", .{shortest});

        ans += shortest * try std.fmt.parseInt(u32, line[0 .. line.len - 1], 10);
    }

    return ans;
}
