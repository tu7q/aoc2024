const std = @import("std");
const Allocator = std.mem.Allocator;

// Note that all values in the dataset lie between [0, 98].
const AdjacencyMatrix = [100][100]u1;
// If there is an edge from vertex i to j then adjMat[i][j] == 1 otherwise adjMat[i][j] == 0.

// Rules represents each incoming edge.
fn kahn_sort(allocator: Allocator, sequence: []u32, rules: *AdjacencyMatrix) ![]u32 {
    var restore = std.ArrayList([2]u32).init(allocator);
    defer {
        for (restore.items) |v| {
            rules[v[0]][v[1]] = 1;
        }
        restore.deinit();
    }

    var L = std.ArrayList(u32).init(allocator);
    var S = std.ArrayList(u32).init(allocator);
    defer S.deinit();

    for (sequence) |n| {
        for (0..rules.len) |i| {
            if (!std.mem.containsAtLeast(u32, sequence, 1, &[_]u32{@intCast(i)})) continue;
            if (rules[i][n] != 0) break;
        } else {
            try S.append(n);
        }
    }

    while (S.items.len != 0) {
        const n = S.pop();
        try L.append(n);

        for (sequence) |m| {
            if (rules[n][m] == 0) continue;
            rules[n][m] = 0;
            try restore.append([2]u32{ n, m });
            for (0..rules.len) |j| {
                if (!std.mem.containsAtLeast(u32, sequence, 1, &[_]u32{@intCast(j)})) continue;
                if (rules[j][m] != 0) break;
            } else {
                try S.append(m);
            }
        }
    }

    return try L.toOwnedSlice();
}

const ProblemInput = struct {
    graph: AdjacencyMatrix,
    updates: [][]u32,
};

fn readInput(allocator: Allocator, file: std.fs.File) !ProblemInput {
    var reader = file.reader();
    var buffer: [1024]u8 = undefined;

    var rules: AdjacencyMatrix = std.mem.zeroes(AdjacencyMatrix);

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        if (line.len == 0) break;

        var it = std.mem.splitScalar(u8, line, '|');
        const before = try std.fmt.parseUnsigned(u32, it.next().?, 10);
        const after = try std.fmt.parseUnsigned(u32, it.next().?, 10);

        rules[before][after] = 1;
    }

    var updates = std.ArrayList([]u32).init(allocator);

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);

        var update = std.ArrayList(u32).init(allocator);

        var it = std.mem.splitScalar(u8, line, ',');
        while (it.next()) |str| {
            const page = try std.fmt.parseUnsigned(u32, str, 10);
            try update.append(page);
        }

        try updates.append(try update.toOwnedSlice());
    }

    return .{
        .graph = rules,
        .updates = try updates.toOwnedSlice(),
    };
}

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("correctly ordered pages: middle page number sum: {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u32 {
    const file = try std.fs.cwd().openFile("puzzle_input/day5.txt", .{});
    defer file.close();

    var input = try readInput(allocator, file);
    var accumulator: u32 = 0;

    for (input.updates) |update| {
        const sorted = try kahn_sort(allocator, update, &input.graph);
        if (std.mem.eql(u32, sorted, update)) {
            accumulator += update[update.len / 2];
        }
    }

    return accumulator;
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("sorted pages: middle page number sum: {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u32 {
    const file = try std.fs.cwd().openFile("puzzle_input/day5.txt", .{});
    defer file.close();

    var input = try readInput(allocator, file);
    var accumulator: u32 = 0;

    for (input.updates) |update| {
        const sorted = try kahn_sort(allocator, update, &input.graph);
        if (!std.mem.eql(u32, sorted, update)) {
            accumulator += sorted[sorted.len / 2];
        }
    }

    return accumulator;
}
