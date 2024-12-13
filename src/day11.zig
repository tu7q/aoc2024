const std = @import("std");
const Allocator = std.mem.Allocator;

// problem utilities.

const Stone = struct {
    num: u64,
    digits: u64,
};

const SplitResult = struct {
    a: Stone,
    b: Stone,
};

fn numDigits(a: u64) u64 {
    return if (a != 0) std.math.log10(a) + 1 else 1;
}

fn splitStone(s: Stone) SplitResult {
    const half = s.digits / 2;

    const pow = std.math.pow(u64, 10, half);
    const a: u64 = s.num / pow;
    const b: u64 = s.num - a * pow;

    return .{
        .a = .{
            .num = a,
            .digits = half,
        },
        .b = .{
            .num = b,
            .digits = numDigits(b),
        },
    };
}

const MemoizeKey = struct {
    value: u64,
    blinks: u8,
};

// Actually counts the stones.
fn countStones(cache: *std.AutoHashMap(MemoizeKey, u64), stone: Stone, blinks: u8) !u64 {
    if (blinks == 0) return 1;

    const key: MemoizeKey = .{ .blinks = blinks, .value = stone.num };
    if (cache.get(key)) |r| {
        return r;
    }

    const result = if (stone.num == 0) blk: {
        break :blk try countStones(cache, Stone{ .digits = 1, .num = 1 }, blinks - 1);
    } else if (stone.digits % 2 == 0) blk: {
        const split_stones = splitStone(stone);
        break :blk try countStones(cache, split_stones.a, blinks - 1) + try countStones(cache, split_stones.b, blinks - 1);
    } else blk: {
        const mul = stone.num * 2024;
        break :blk try countStones(cache, .{
            .num = mul,
            .digits = numDigits(mul),
        }, blinks - 1);
    };

    // cache.putNoClobber(key: K, value: V)
    // _ = try cache.getOrPutValue(key, result);
    try cache.put(key, result);
    return result;
}

// input helper
fn getInputStones(allocator: Allocator) ![]Stone {
    const file = try std.fs.cwd().openFile("puzzle_input/day11.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buffer: [1024]u8 = undefined;

    var stones = std.ArrayList(Stone).init(allocator);

    const read = try reader.readAll(&buffer);
    const line = std.mem.trim(u8, buffer[0..read], &std.ascii.whitespace);

    var it = std.mem.splitScalar(u8, line, ' ');
    while (it.next()) |stone| {
        try stones.append(.{
            .digits = stone.len,
            .num = try std.fmt.parseUnsigned(u64, stone, 10),
        });
    }

    return stones.toOwnedSlice();
}

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("number of stones (25 blinks): {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u64 {
    const BLINKS = 25;

    const stones = try getInputStones(allocator);

    var cache = std.AutoHashMap(MemoizeKey, u64).init(allocator);
    defer cache.deinit();

    var totalStones: u64 = 0;
    for (stones) |stone| {
        totalStones += try countStones(&cache, stone, BLINKS);
    }

    return totalStones;
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("number of stones (75 blinks): {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u64 {
    const BLINKS = 75;

    const stones = try getInputStones(allocator);

    var cache = std.AutoHashMap(MemoizeKey, u64).init(allocator);
    defer cache.deinit();

    var totalStones: u64 = 0;
    for (stones) |stone| {
        totalStones += try countStones(&cache, stone, BLINKS);
    }

    return totalStones;
}
