const std = @import("std");
const Allocator = std.mem.Allocator;

const Token = struct {
    val: u64,
    slice: []u8,
};

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("total calibration result: {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u64 {
    var total_calibration_result: u64 = 0;

    const file = try std.fs.cwd().openFile("puzzle_input/day7.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buf: [1024]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);

        var it = std.mem.splitSequence(u8, line, ": ");
        const test_value = try std.fmt.parseUnsigned(u64, it.next().?, 10);

        const tokens = get_nums: {
            var nums = std.ArrayList(Token).init(allocator);
            var str_nums = std.mem.splitScalar(u8, it.next().?, ' ');
            while (str_nums.next()) |str_num| {
                const num = try std.fmt.parseUnsigned(u64, str_num, 10);
                try nums.append(.{ .val = num, .slice = @constCast(str_num) });
            }
            break :get_nums try nums.toOwnedSlice();
        };
        defer allocator.free(tokens);

        var sltns = try allocator.alloc(u64, 1);
        defer allocator.free(sltns);
        sltns[0] = tokens[0].val;

        for (tokens[1..]) |t| {
            if (sltns.len == 0) break;

            var next = std.ArrayList(u64).init(allocator);
            for (sltns) |sltn| {
                if (sltn + t.val <= test_value) {
                    try next.append(sltn + t.val);
                }
                if (sltn * t.val <= test_value) {
                    try next.append(sltn * t.val);
                }
            }
            allocator.free(sltns);
            sltns = try next.toOwnedSlice();
        }

        if (std.mem.containsAtLeast(u64, sltns, 1, &[_]u64{test_value})) {
            total_calibration_result += test_value;
        }
    }

    return total_calibration_result;
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("total calibration result: {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u64 {
    var ans: u64 = 0;

    const file = try std.fs.cwd().openFile("puzzle_input/day7.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buf: [1024]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        if (line.len == 0) break;

        var it = std.mem.splitSequence(u8, line, ": ");
        const tgt = try std.fmt.parseUnsigned(u64, it.next().?, 10);

        const Y = get_nums: {
            var nums = std.ArrayList(Token).init(allocator);
            var str_nums = std.mem.splitScalar(u8, it.next().?, ' ');
            while (str_nums.next()) |str_num| {
                const num = try std.fmt.parseUnsigned(u64, str_num, 10);
                try nums.append(.{ .val = num, .slice = @constCast(str_num) });
            }
            break :get_nums try nums.toOwnedSlice();
        };
        defer allocator.free(Y);

        var X = try allocator.alloc(u64, 1);
        defer allocator.free(X);
        X[0] = Y[0].val;

        for (Y[1..]) |y| {
            if (X.len == 0) break;

            var next = try std.ArrayList(u64).initCapacity(allocator, X.len * 3);

            for (X) |x| {
                if (x + y.val <= tgt) {
                    try next.append(x + y.val);
                }
                if (x * y.val <= tgt) {
                    try next.append(x * y.val);
                }
                const res = x * std.math.pow(u64, 10, y.slice.len) + y.val;
                if (res <= tgt) {
                    try next.append(res);
                }
            }
            allocator.free(X);
            X = try next.toOwnedSlice();
        }

        if (std.mem.containsAtLeast(u64, X, 1, &[_]u64{tgt})) {
            ans += tgt;
        }
    }

    return ans;
}
