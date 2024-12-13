const std = @import("std");
const Allocator = std.mem.Allocator;

// Solves the linear equation
// ax * a + bx * b = X
// ay * a + by * b = Y

// a | ax bx   X
// b | ay by = Y

// fn solve(ax: usize, ay: usize, bx: usize, by: usize, X: usize, Y: usize) ?struct { a: usize, b: usize } {
//     if (ax * by - bx * ay == 0) return null;
// }

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("fewest tokens required: {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u32 {
    const file = try std.fs.cwd().openFile("puzzle_input/day13.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buffer: [1024]u8 = undefined;

    var tokens: u32 = 0;

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        var line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);

        var ax: u32 = undefined;
        var ay: u32 = undefined;
        var bx: u32 = undefined;
        var by: u32 = undefined;
        var X: u32 = undefined;
        var Y: u32 = undefined;

        {
            const @"X+" = std.mem.indexOfScalar(u8, line, '+').?;
            const comma = std.mem.indexOfScalar(u8, line, ',').?;
            const @"Y+" = std.mem.indexOfScalarPos(u8, line, @"X+" + 1, '+').?;

            ax = try std.fmt.parseInt(u32, line[@"X+"..comma], 10);
            ay = try std.fmt.parseInt(u32, line[@"Y+"..], 10);
        }

        line = std.mem.trim(u8, try reader.readUntilDelimiter(&buffer, '\n'), &std.ascii.whitespace);
        {
            const @"X+" = std.mem.indexOfScalar(u8, line, '+').?;
            const comma = std.mem.indexOfScalar(u8, line, ',').?;
            const @"Y+" = std.mem.indexOfScalarPos(u8, line, @"X+" + 1, '+').?;

            bx = try std.fmt.parseInt(u32, line[@"X+"..comma], 10);
            by = try std.fmt.parseInt(u32, line[@"Y+"..], 10);
        }

        line = std.mem.trim(u8, try reader.readUntilDelimiter(&buffer, '\n'), &std.ascii.whitespace);
        {
            const @"X=" = std.mem.indexOfScalar(u8, line, '=').?;
            const comma = std.mem.indexOfScalar(u8, line, ',').?;
            const @"Y=" = std.mem.indexOfScalarPos(u8, line, @"X=" + 1, '=').?;

            X = try std.fmt.parseInt(u32, line[@"X=" + 1 .. comma], 10);
            Y = try std.fmt.parseInt(u32, line[@"Y=" + 1 ..], 10);
        }

        // std.debug.print("ax: {d}, ay: {d}, bx: {d}, by: {d}, X: {d}, Y: {d}\n", .{ ax, ay, bx, by, X, Y });

        try reader.skipUntilDelimiterOrEof('\n');

        // Stupidest solution imaginable
        // lmao

        var solutions = std.ArrayList(u32).init(allocator);
        defer solutions.deinit();

        for (1..101) |a| {
            for (1..101) |b| {
                if (a * ax + b * bx == X and a * ay + b * by == Y) {
                    try solutions.append(@intCast(3 * a + b));
                }
            }
        }

        if (solutions.items.len > 0) {
            tokens += std.mem.min(u32, solutions.items);
        }
    }

    return tokens;
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("fewest tokens required (with error): {d}\n", .{result});
}

pub fn solutionTwo(_: Allocator) !u64 {
    const OFFSET = 10000000000000;

    const file = try std.fs.cwd().openFile("puzzle_input/day13.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buffer: [1024]u8 = undefined;

    var tokens: u64 = 0;

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        var line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);

        var ax: i32 = undefined;
        var ay: i32 = undefined;
        var bx: i32 = undefined;
        var by: i32 = undefined;
        var X: u64 = undefined;
        var Y: u64 = undefined;

        {
            const @"X+" = std.mem.indexOfScalar(u8, line, '+').?;
            const comma = std.mem.indexOfScalar(u8, line, ',').?;
            const @"Y+" = std.mem.indexOfScalarPos(u8, line, @"X+" + 1, '+').?;

            ax = try std.fmt.parseInt(i32, line[@"X+"..comma], 10);
            ay = try std.fmt.parseInt(i32, line[@"Y+"..], 10);
        }

        line = std.mem.trim(u8, try reader.readUntilDelimiter(&buffer, '\n'), &std.ascii.whitespace);
        {
            const @"X+" = std.mem.indexOfScalar(u8, line, '+').?;
            const comma = std.mem.indexOfScalar(u8, line, ',').?;
            const @"Y+" = std.mem.indexOfScalarPos(u8, line, @"X+" + 1, '+').?;

            bx = try std.fmt.parseInt(i32, line[@"X+"..comma], 10);
            by = try std.fmt.parseInt(i32, line[@"Y+"..], 10);
        }

        line = std.mem.trim(u8, try reader.readUntilDelimiter(&buffer, '\n'), &std.ascii.whitespace);
        {
            const @"X=" = std.mem.indexOfScalar(u8, line, '=').?;
            const comma = std.mem.indexOfScalar(u8, line, ',').?;
            const @"Y=" = std.mem.indexOfScalarPos(u8, line, @"X=" + 1, '=').?;

            X = try std.fmt.parseInt(u32, line[@"X=" + 1 .. comma], 10);
            Y = try std.fmt.parseInt(u32, line[@"Y=" + 1 ..], 10);
        }

        X += OFFSET;
        Y += OFFSET;

        // std.debug.print("ax: {d}, ay: {d}, bx: {d}, by: {d}, X: {d}, Y: {d}\n", .{ ax, ay, bx, by, X, Y });

        try reader.skipUntilDelimiterOrEof('\n');

        if (ax * by == bx * ay) { // No solutions or infinite solutions.
            // cry.. The advent of code input doesn't contain any input where this is the case...
            // worrying over nothing.
            std.debug.print("crying\n", .{});
        } else {
            const a_numerator = @as(i64, @intCast(X)) * by - bx * @as(i64, @intCast(Y));
            const a_denominator = ax * by - bx * ay;
            const a = @divTrunc(a_numerator, a_denominator);

            const b_numerator = ax * @as(i64, @intCast(Y)) - @as(i64, @intCast(X)) * ay;
            const b_denominator = ax * by - bx * ay;
            const b = @divTrunc(b_numerator, b_denominator);

            if (a * ax + b * bx == X and a * ay + b * by == Y) tokens += @intCast(3 * a + b);
        }

        // for (1..@max(X / bx, Y / by)) |b| {
        //     // since ax * a + bx * b = X => a = X - (bx * b) / ax
        //     const a = (Y - (bx * b)) / ax;

        //     if (ax * a + bx * b == X and ay * a + by * b == Y) {
        //         tokens += 3 * a + b;
        //         break;
        //     }
        // }

    }

    return tokens;
}
