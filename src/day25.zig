const std = @import("std");
const Allocator = std.mem.Allocator;

const WIDTH = 5;
const HEIGHT = 7;

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("result: {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u32 {
    const file = try std.fs.cwd().openFile("puzzle_input/day25.txt", .{});
    defer file.close();

    var reader = file.reader();

    const input = try reader.readAllAlloc(allocator, 1024 * 40);

    const BitSet = std.bit_set.IntegerBitSet(WIDTH * HEIGHT);

    var keys = std.ArrayList(BitSet).init(allocator);
    defer keys.deinit();

    var locks = std.ArrayList(BitSet).init(allocator);
    defer locks.deinit();

    var item_iterator = std.mem.splitSequence(u8, input, "\n\n");
    while (item_iterator.next()) |item| {
        var bit_set = BitSet.initEmpty();

        var i: usize = 0;
        for (item) |char| {
            if (char == '\n') continue;
            defer i += 1;

            bit_set.setValue(i, char == '#');
        }

        if (item[0] == '#') { // Is a lock.
            try locks.append(bit_set);
        } else { // Isn't a lock.
            try keys.append(bit_set);
        }
    }

    var result: usize = 0;

    for (locks.items) |lock| {
        for (keys.items) |key| {
            if (lock.mask & key.mask == 0) {
                result += 1;
            }
        }
    }

    return @intCast(result);
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    _ = try solutionTwo(allocator);
    try writer.print("No part 2.\n", .{});
}

pub fn solutionTwo(_: Allocator) !void {}
