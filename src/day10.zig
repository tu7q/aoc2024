const std = @import("std");
const Allocator = std.mem.Allocator;

const Adjacent = struct {
    n: ?usize,
    e: ?usize,
    s: ?usize,
    w: ?usize,
};

const Map = struct {
    allocator: Allocator,
    map: []u8,

    width: usize,
    height: usize,

    pub fn getAdjacent(self: @This(), i: usize) Adjacent {
        const y = i / self.width;
        const x = i % self.width;

        const res = .{
            .n = if (y == 0) null else (y - 1) * self.width + x,
            .e = if (x + 1 == self.width) null else y * self.width + (x + 1),
            .s = if (y + 1 == self.height) null else (y + 1) * self.width + x,
            .w = if (x == 0) null else y * self.width + (x - 1),
        };

        return res;
    }

    pub fn topAdjacent(self: @This(), i: usize) Adjacent {
        const next = self.map[i] + 1;
        // std.debug.print("next: {c}\n", .{next});
        const adjacent = self.getAdjacent(i);

        return .{
            .n = if (adjacent.n != null and self.map[adjacent.n.?] == next) adjacent.n else null,
            .e = if (adjacent.e != null and self.map[adjacent.e.?] == next) adjacent.e else null,
            .s = if (adjacent.s != null and self.map[adjacent.s.?] == next) adjacent.s else null,
            .w = if (adjacent.w != null and self.map[adjacent.w.?] == next) adjacent.w else null,
        };
    }
};

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("sum of all trailheads: {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u32 {
    // Read in puzzle input.
    const file = try std.fs.cwd().openFile("puzzle_input/day10.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buffer: [1024]u8 = undefined;

    var input_map = std.ArrayList(u8).init(allocator);

    const width: usize = blk: {
        const line_lf = try reader.readUntilDelimiter(&buffer, '\n');
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        try input_map.appendSlice(line);
        break :blk line.len;
    };
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        try input_map.appendSlice(line);
    }

    std.debug.assert(input_map.items.len > 0);

    const top_map = Map{
        .allocator = allocator,
        .width = width,
        .height = input_map.items.len / width,
        .map = try input_map.toOwnedSlice(),
    };
    defer allocator.free(top_map.map);

    var ans: u32 = 0;

    for (top_map.map, 0..) |c, i| {
        if (c != '0') continue;

        var paths: u32 = 0;

        var visited: []bool = try allocator.alloc(bool, top_map.map.len);
        defer allocator.free(visited);
        for (visited) |*v| {
            v.* = false;
        }

        var unvisited = std.ArrayList(usize).init(allocator);
        defer unvisited.deinit();

        try unvisited.append(i);

        while (unvisited.items.len > 0) {
            const n = unvisited.pop();

            if (visited[n]) continue;
            if (top_map.map[n] == '9') {
                paths += 1;
            }
            visited[n] = true;

            const adj = top_map.topAdjacent(n);
            // std.debug.print("{any}\n", .{adj});
            if (adj.n != null and !visited[adj.n.?]) try unvisited.append(adj.n.?);
            if (adj.e != null and !visited[adj.e.?]) try unvisited.append(adj.e.?);
            if (adj.s != null and !visited[adj.s.?]) try unvisited.append(adj.s.?);
            if (adj.w != null and !visited[adj.w.?]) try unvisited.append(adj.w.?);
        }

        // for (0..top_map.map.len) |idx| {
        //     if (visited[idx]) {
        //         std.debug.print("\x1b[1m{c}\x1b[m", .{top_map.map[idx]});
        //     } else {
        //         std.debug.print("{c}", .{top_map.map[idx]});
        //     }

        //     if (idx % top_map.width == top_map.width - 1) std.debug.print("\n", .{});
        // }

        ans += paths;
    }

    return ans;
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("total rating: {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u32 {
    // Read in puzzle input.
    const file = try std.fs.cwd().openFile("puzzle_input/day10.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buffer: [1024]u8 = undefined;

    var input_map = std.ArrayList(u8).init(allocator);

    const width: usize = blk: {
        const line_lf = try reader.readUntilDelimiter(&buffer, '\n');
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        try input_map.appendSlice(line);
        break :blk line.len;
    };
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        try input_map.appendSlice(line);
    }

    std.debug.assert(input_map.items.len > 0);

    const top_map = Map{
        .allocator = allocator,
        .width = width,
        .height = input_map.items.len / width,
        .map = try input_map.toOwnedSlice(),
    };
    defer allocator.free(top_map.map);

    var ans: u32 = 0;

    for (top_map.map, 0..) |c, i| {
        if (c != '0') continue;

        var paths: u32 = 0;

        var unvisited = std.ArrayList(usize).init(allocator);
        defer unvisited.deinit();

        try unvisited.append(i);

        while (unvisited.items.len > 0) {
            const n = unvisited.pop();

            if (top_map.map[n] == '9') {
                paths += 1;
                continue;
            }

            const adj = top_map.topAdjacent(n);
            if (adj.n != null) try unvisited.append(adj.n.?);
            if (adj.e != null) try unvisited.append(adj.e.?);
            if (adj.s != null) try unvisited.append(adj.s.?);
            if (adj.w != null) try unvisited.append(adj.w.?);
        }

        ans += paths;
    }

    return ans;
}
