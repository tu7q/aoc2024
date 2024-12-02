const std = @import("std");
const Allocator = std.mem.Allocator;

// Pretty Print Solution
pub fn ppSolutionOne(allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    std.debug.print("safe reports: {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u32 {
    var safe_reports: u32 = 0;

    const file = try std.fs.cwd().openFile("puzzle_input/day2.txt", .{});
    defer file.close();

    const reader = file.reader();
    var buf: [1024]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, "\r\n");

        var report = std.ArrayList(u32).init(allocator);
        defer report.deinit();

        var it = std.mem.splitScalar(u8, line, ' ');
        while (it.next()) |str_num| {
            const level = try std.fmt.parseInt(u32, str_num, 10);
            try report.append(level);
        }

        if (isSafe(report.items)) safe_reports += 1;
    }

    return safe_reports;
}

pub fn ppSolutionTwo(allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    std.debug.print("safe reports: {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u32 {
    var safe_reports: u32 = 0;

    const file = try std.fs.cwd().openFile("puzzle_input/day2.txt", .{});
    defer file.close();

    const reader = file.reader();
    var buf: [1024]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, "\r\n");

        var levels = std.ArrayList(u32).init(allocator);
        defer levels.deinit();

        var it = std.mem.splitScalar(u8, line, ' ');
        while (it.next()) |str_num| {
            const level = try std.fmt.parseInt(u32, str_num, 10);
            try levels.append(level);
        }

        // naive solution (good enough for the aoc dataset)

        if (isSafe(levels.items)) {
            safe_reports += 1;
            continue;
        }

        // One small optimization might be to iterate over i in reverse. (might save time on the orderedRemove)
        for (0..levels.items.len) |i| {
            const value = levels.orderedRemove(i);
            if (isSafe(levels.items)) {
                safe_reports += 1;
                break;
            }
            try levels.insert(i, value);
        }
    }

    return safe_reports;
}

// Checks whether a report is safe without checking for any layers of safety.
fn isSafe(report: []u32) bool {
    std.debug.assert(report.len > 1);

    const increasing = report[1] > report[0];

    var it = std.mem.window(u32, report, 2, 1);
    while (it.next()) |levels| {
        const difference = if (levels[0] > levels[1]) levels[0] - levels[1] else levels[1] - levels[0];
        switch (increasing) {
            false => if (levels[1] > levels[0]) return false,
            true => if (levels[1] < levels[0]) return false,
        }
        if (difference == 0 or difference > 3) {
            return false;
        }
    }
    return true;
}
