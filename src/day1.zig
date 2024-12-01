const std = @import("std");
const Allocator = std.mem.Allocator;

// Pretty Print Solution
pub fn ppSolutionOne(allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    std.debug.print("total difference: {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u32 {
    var leftList = std.ArrayList(u32).init(allocator);
    defer leftList.deinit();
    var rightList = std.ArrayList(u32).init(allocator);
    defer rightList.deinit();

    const file = try std.fs.cwd().openFile("puzzle_input/day1.txt", .{});
    defer file.close();

    const reader = file.reader();
    var buf: [1024]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line_lf| {
        // if (maybe_number == null) break;

        const line = std.mem.trim(u8, line_lf, "\r\n");

        var it = std.mem.splitSequence(u8, line, "   ");

        try leftList.append(try std.fmt.parseInt(u32, it.next().?, 10));
        try rightList.append(try std.fmt.parseInt(u32, it.next().?, 10));
    }

    std.mem.sort(u32, leftList.items, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, rightList.items, {}, comptime std.sort.asc(u32));

    var accumulator: u32 = 0;
    for (0..leftList.items.len) |i| {
        const a = leftList.items[i];
        const b = rightList.items[i];

        if (a > b) {
            accumulator += a - b;
        } else {
            accumulator += b - a;
        }
    }

    return accumulator;
}

pub fn ppSolutionTwo(allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    std.debug.print("similarity: {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u64 {
    var leftList = std.ArrayList(u32).init(allocator);
    defer leftList.deinit();
    var rightList = std.ArrayList(u32).init(allocator);
    defer rightList.deinit();

    const file = try std.fs.cwd().openFile("puzzle_input/day1.txt", .{});
    defer file.close();

    const reader = file.reader();
    var buf: [1024]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line_lf| {
        // if (maybe_number == null) break;

        const line = std.mem.trim(u8, line_lf, "\r\n");

        var it = std.mem.splitSequence(u8, line, "   ");

        try leftList.append(try std.fmt.parseInt(u32, it.next().?, 10));
        try rightList.append(try std.fmt.parseInt(u32, it.next().?, 10));
    }

    var similarity: usize = 0;

    for (leftList.items) |value| {
        similarity += value * std.mem.count(u32, rightList.items, &[_]u32{value});
    }

    return similarity;
}
