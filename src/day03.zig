const std = @import("std");
const Allocator = std.mem.Allocator;

fn nextNumber(buffer: []u8) ?[]u8 {
    var num_slice: ?[]u8 = null;
    for (0..buffer.len) |i| {
        if (!std.ascii.isDigit(buffer[i])) break;
        num_slice = buffer[0 .. i + 1];
    }
    return num_slice;
}

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("accumulated sum: {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u32 {
    var accumulator: u32 = 0;

    const file = try std.fs.cwd().openFile("puzzle_input/day3.txt", .{});
    defer file.close();

    // Read the file into a buffer.
    const stat = try file.stat();
    const buffer = try file.readToEndAlloc(allocator, stat.size);
    defer allocator.free(buffer);

    const MATCH = "mul(";

    var it = std.mem.window(u8, buffer, 4, 1);
    while (it.next()) |value| {
        if (!std.mem.eql(u8, MATCH, value)) continue;

        const si = it.index.? - it.advance + MATCH.len; // -advancement because of the advancement from it.next()

        // Note that there are missing bounds checks but I am lazy.

        const first_number_slice = nextNumber(buffer[si..]) orelse continue;
        if (buffer[si + first_number_slice.len] != ',') continue;
        const second_number_slice = nextNumber(buffer[si + first_number_slice.len + 1 ..]) orelse continue;
        if (buffer[si + first_number_slice.len + 1 + second_number_slice.len] != ')') continue;

        const first_number = try std.fmt.parseUnsigned(u32, first_number_slice, 10);
        const second_number = try std.fmt.parseUnsigned(u32, second_number_slice, 10);

        accumulator += first_number * second_number;
        it.index = si + first_number_slice.len + second_number_slice.len + 1;
    }

    return accumulator;
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("accumulated sum (with do's/don'ts): {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u32 {
    var accumulator: u32 = 0;

    const file = try std.fs.cwd().openFile("puzzle_input/day3.txt", .{});
    defer file.close();

    // Read the file into a buffer.
    const stat = try file.stat();
    const buffer = try file.readToEndAlloc(allocator, stat.size);
    defer allocator.free(buffer);

    const MUL = "mul(";
    const DO = "do()";
    const DONT = "don't()";
    var enabled = true;

    var it = std.mem.window(u8, buffer, 7, 1);
    while (it.next()) |value| {
        if (std.mem.startsWith(u8, value, DO)) {
            enabled = true;
            continue;
        }
        if (std.mem.startsWith(u8, value, DONT)) {
            enabled = false;
            continue;
        }

        if (!std.mem.startsWith(u8, value, MUL)) continue;

        const si = it.index.? - it.advance + MUL.len; // -advancement because of the advancement from it.next()

        // Note that there are missing bounds checks but I am lazy.

        const first_number_slice = nextNumber(buffer[si..]) orelse continue;
        if (buffer[si + first_number_slice.len] != ',') continue;
        const second_number_slice = nextNumber(buffer[si + first_number_slice.len + 1 ..]) orelse continue;
        if (buffer[si + first_number_slice.len + 1 + second_number_slice.len] != ')') continue;

        const first_number = try std.fmt.parseUnsigned(u32, first_number_slice, 10);
        const second_number = try std.fmt.parseUnsigned(u32, second_number_slice, 10);

        if (enabled) {
            accumulator += first_number * second_number;
        }
        it.index = si + first_number_slice.len + second_number_slice.len + 1;
    }

    return accumulator;
}
