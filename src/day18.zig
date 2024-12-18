const std = @import("std");
const Allocator = std.mem.Allocator;

const Vec2 = struct {
    x: usize,
    y: usize,
};

fn readInput(allocator: Allocator) ![]Vec2 {
    const file = try std.fs.cwd().openFile("puzzle_input/day18.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buffer: [1024]u8 = undefined;

    var coordinates = std.ArrayList(Vec2).init(allocator);
    errdefer coordinates.deinit();

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);

        var it = std.mem.splitScalar(u8, line, ',');

        const x = try std.fmt.parseUnsigned(usize, it.next().?, 10);
        const y = try std.fmt.parseUnsigned(usize, it.next().?, 10);

        try coordinates.append(Vec2{ .x = x, .y = y });
    }

    return coordinates.toOwnedSlice();
}

const WIDTH = 71;
const HEIGHT = 71;

const END = WIDTH * HEIGHT - 1;
const END_X = 70;
const END_Y = 70;

pub fn adjacent(i: usize) [4]?usize {
    var adj: [4]?usize = undefined;

    const x = i % WIDTH;
    const y = i / HEIGHT;

    adj[0] = if (x > 0) i - 1 else null;
    adj[1] = if (x + 1 < WIDTH) i + 1 else null;
    adj[2] = if (y > 0) i - WIDTH else null;
    adj[3] = if (y + 1 < HEIGHT) i + WIDTH else null;

    return adj;
}

// manhattan distance.
pub fn h(i: usize) u32 {
    const nx = i % WIDTH;
    const ny = i / WIDTH;

    const x_abs = if (END_X > nx) END_X - nx else nx - END_X;
    const y_abs = if (END_Y > ny) END_Y - ny else ny - END_Y;
    return @intCast(x_abs + y_abs);
}

pub fn tracePath(allocator: Allocator, came_from: std.AutoHashMap(usize, usize), end: usize) ![]usize {
    var path = std.ArrayList(usize).init(allocator);
    errdefer path.deinit();

    try path.append(end);

    var current = end;
    while (came_from.contains(current)) {
        current = came_from.get(current).?;
        try path.append(current);
    }

    std.mem.reverse(usize, path.items);

    return try path.toOwnedSlice();
}

// pub fn a_star(allocator: Allocator, context: anytype, Node: type, adjacent: fn (allocator, @typeOf(context), Node) []Node, start: Node, end: Node) !u32 {
pub fn a_star(allocator: Allocator, walls: std.AutoHashMap(usize, void), start: usize, end: usize) ![]usize {
    // Min queue
    const QItem = struct {
        priority: u32,
        i: usize,
    };
    const PQlt = std.PriorityQueue(QItem, void, struct {
        pub fn lessThan(_: void, a: QItem, b: QItem) std.math.Order {
            return std.math.order(a.priority, b.priority);
        }
    }.lessThan);

    // Open set
    var open_list = PQlt.init(allocator, {});
    defer open_list.deinit();
    try open_list.add(.{ .priority = 0, .i = start });

    // Used to find path at the end.
    var came_from = std.AutoHashMap(usize, usize).init(allocator);
    defer came_from.deinit();

    // For node n, g_score[n] is the currently known cost of the cheapest path from start to n.
    var g_score = std.AutoHashMap(usize, u32).init(allocator);
    defer g_score.deinit();
    try g_score.put(start, 0);

    // For node n, f_score[n] := g_score[n] + h(n). f_score[n] represents the best current guess of
    // how cheaap a path could be from start to finish if it goes through n.
    var f_score = std.AutoHashMap(usize, u32).init(allocator);
    defer f_score.deinit();
    try f_score.put(start, h(start));

    while (open_list.removeOrNull()) |current| {
        const u = current.i;
        if (u == end) {
            return tracePath(allocator, came_from, u);
        }

        for (adjacent(u)) |adj| {
            if (adj) |v| {
                if (walls.contains(v)) continue;

                const tentative_g_score = g_score.get(u).? + 1;
                const known_g = try g_score.getOrPutValue(v, std.math.maxInt(u32));

                if (tentative_g_score < known_g.value_ptr.*) {
                    try came_from.put(v, u);
                    try g_score.put(v, tentative_g_score);
                    const f = tentative_g_score + h(v);
                    try f_score.put(v, f);
                    try open_list.add(.{ .priority = f, .i = v });
                }
            }
        }
    }

    return error.NoPath;
}

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("min steps {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u32 {
    const input = try readInput(allocator);
    defer allocator.free(input);

    var walls = std.AutoHashMap(usize, void).init(allocator);
    defer walls.deinit();

    for (input[0..1024]) |v| {
        const i = v.y * WIDTH + v.x;
        try walls.put(i, {});
    }

    const path = try a_star(allocator, walls, 0, END);
    defer allocator.free(path);

    return @intCast(path.len);
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("first to block: '{d},{d}'\n", .{ result.x, result.y });
}

pub fn solutionTwo(allocator: Allocator) !Vec2 {
    const input = try readInput(allocator);
    defer allocator.free(input);

    var walls = std.AutoHashMap(usize, void).init(allocator);
    defer walls.deinit();

    // With no walls this should always succeed.
    var path = try a_star(allocator, walls, 0, END);

    for (input) |v| {
        const i = v.y * WIDTH + v.x;
        try walls.put(i, {});

        if (std.mem.containsAtLeast(usize, path, 1, &[_]usize{i})) {
            allocator.free(path); // free old path.
            // Need to try and recompute path.
            path = a_star(allocator, walls, 0, END) catch |err| switch (err) {
                error.NoPath => return v,
                else => return err,
            };
        }
    }

    defer allocator.free(path);
    return error.AllPathsAreValid;
}
