const std = @import("std");
const Allocator = std.mem.Allocator;

fn numPatterns(cache: *std.StringHashMap(u64), design: []const u8, patterns: []const []const u8) !u64 {
    if (design.len == 0) return 0;

    if (cache.get(design)) |r| return r;

    var count: u64 = 0;

    for (patterns) |pattern| {
        if (std.mem.startsWith(u8, design, pattern)) {
            if (pattern.len == design.len) {
                count += 1;
            } else {
                count += try numPatterns(cache, design[pattern.len..], patterns);
            }
        }
    }

    try cache.put(design, count);

    return count;
}

fn isPossible(design: []const u8, patterns: []const []const u8) bool {
    for (patterns) |pattern| {
        const match = std.mem.startsWith(u8, design, pattern);
        if (match and pattern.len == design.len) {
            return true;
        } else if (match and isPossible(design[pattern.len..], patterns)) {
            return true;
        }
    }

    return false;
}

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("number of possible designs: {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u32 {
    var arena_impl = std.heap.ArenaAllocator.init(allocator);
    defer arena_impl.deinit();

    const arena = arena_impl.allocator();

    const file = try std.fs.cwd().openFile("puzzle_input/day19.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buffer: [4096]u8 = undefined;

    const patterns = blk: {
        const line_lf = try reader.readUntilDelimiter(&buffer, '\n');
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);

        var patterns = std.ArrayList([]u8).init(arena);

        var it = std.mem.splitSequence(u8, line, &[_]u8{ ',', ' ' });
        while (it.next()) |pattern| {
            const new_pattern = try arena.alloc(u8, pattern.len);
            @memcpy(new_pattern, pattern);
            try patterns.append(new_pattern);
        }

        break :blk try patterns.toOwnedSlice();
    };

    const designs = blk: {
        var designs = std.ArrayList([]u8).init(arena);

        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
            const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
            if (line.len == 0) continue;

            const design = try arena.alloc(u8, line.len);
            @memcpy(design, line);

            try designs.append(design);
        }

        break :blk try designs.toOwnedSlice();
    };

    var count: u32 = 0;

    for (designs) |design| {
        if (isPossible(design, patterns)) count += 1;
    }

    return count;
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("sum of number of ways to make each design: {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u64 {
    var arena_impl = std.heap.ArenaAllocator.init(allocator);
    defer arena_impl.deinit();

    const arena = arena_impl.allocator();

    const file = try std.fs.cwd().openFile("puzzle_input/day19.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buffer: [4096]u8 = undefined;

    const patterns = blk: {
        const line_lf = try reader.readUntilDelimiter(&buffer, '\n');
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);

        var patterns = std.ArrayList([]u8).init(arena);

        var it = std.mem.splitSequence(u8, line, &[_]u8{ ',', ' ' });
        while (it.next()) |pattern| {
            const new_pattern = try arena.alloc(u8, pattern.len);
            @memcpy(new_pattern, pattern);
            try patterns.append(new_pattern);
        }

        std.mem.sort(
            []u8,
            patterns.items,
            {},
            struct {
                pub fn inner(_: void, lhs: []u8, rhs: []u8) bool {
                    return std.sort.asc(usize)({}, lhs.len, rhs.len);
                }
            }.inner,
        );

        break :blk try patterns.toOwnedSlice();
    };

    const designs = blk: {
        var designs = std.ArrayList([]u8).init(arena);

        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
            const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
            if (line.len == 0) continue;

            const design = try arena.alloc(u8, line.len);
            @memcpy(design, line);

            try designs.append(design);
        }

        break :blk try designs.toOwnedSlice();
    };

    var count: u64 = 0;

    var cache = std.StringHashMap(u64).init(allocator);
    defer cache.deinit();

    for (designs) |design| {
        count += try numPatterns(&cache, design, patterns);
    }

    return count;
}
