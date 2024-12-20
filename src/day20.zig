const std = @import("std");
const Allocator = std.mem.Allocator;

const Kind = enum {
    Empty,
    Wall,
};

const Map = struct {
    width: usize,
    height: usize,
    layout: []Kind,
    start: usize,
    end: usize,

    pub fn adjacent(self: @This(), i: usize) [4]?usize {
        var adj: [4]?usize = undefined;

        const x = i % self.width;
        const y = i / self.height;

        adj[0] = if (x > 0) i - 1 else null;
        adj[1] = if (x + 1 < self.width) i + 1 else null;
        adj[2] = if (y > 0) i - self.width else null;
        adj[3] = if (y + 1 < self.width) i + self.width else null;

        return adj;
    }

    pub fn move(self: @This(), i: usize, x_off: isize, y_off: isize) ?usize {
        const x = i % self.width;
        const y = i / self.height;

        const new_x = @as(isize, @intCast(x)) + x_off;
        const new_y = @as(isize, @intCast(y)) + y_off;

        if (new_x >= 0 and new_x < self.width and new_y >= 0 and new_y < self.height) {
            const j = @as(usize, @intCast(new_x)) + @as(usize, @intCast(new_y)) * self.width;
            if (self.layout[j] != .Wall) return @intCast(j);
        }

        return null;
    }

    pub fn cheated(self: @This(), allocator: Allocator, i: usize, radius: usize) ![]usize {
        var points = std.ArrayList(usize).init(allocator);
        errdefer points.deinit();

        for (1..radius + 1) |r| {
            for (0..r) |u_offset| {
                const offset: isize = @intCast(u_offset);
                const invOffset: isize = @as(isize, @intCast(r)) - offset;
                if (self.move(i, offset, invOffset)) |p| try points.append(p);
                if (self.move(i, invOffset, -offset)) |p| try points.append(p);
                if (self.move(i, -offset, -invOffset)) |p| try points.append(p);
                if (self.move(i, -invOffset, offset)) |p| try points.append(p);
            }
        }

        return points.toOwnedSlice();
    }

    pub fn manhattan_distance(self: @This(), a: usize, b: usize) u32 {
        const ax = a % self.width;
        const ay = a / self.width;
        const bx = b % self.width;
        const by = b / self.width;

        const x_diff = if (ax > bx) ax - bx else bx - ax;
        const y_diff = if (ay > by) ay - by else by - ay;
        return @intCast(x_diff + y_diff);
    }
};

fn readInput(allocator: Allocator) !Map {
    const file = try std.fs.cwd().openFile("puzzle_input/day20.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buffer: [1024]u8 = undefined;

    var width: usize = 0;
    var layout = std.ArrayList(Kind).init(allocator);
    errdefer layout.deinit();

    var start: usize = undefined;
    var end: usize = undefined;

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        width = line.len;

        for (line) |c| {
            switch (c) {
                '#' => try layout.append(.Wall),
                '.', 'S', 'E' => {
                    if (c == 'S') start = layout.items.len;
                    if (c == 'E') end = layout.items.len;
                    try layout.append(.Empty);
                },
                else => unreachable,
            }
        }
    }

    var map: Map = undefined;
    map.end = end;
    map.start = start;
    map.height = layout.items.len / width;
    map.width = width;
    map.layout = try layout.toOwnedSlice();
    return map;
}

pub fn tracePath(allocator: Allocator, came_from: std.AutoHashMap(usize, usize), start: usize) ![]usize {
    var path = std.ArrayList(usize).init(allocator);
    errdefer path.deinit();

    try path.append(start);

    var current = start;
    while (came_from.contains(current)) {
        current = came_from.get(current).?;
        try path.append(current);
    }

    return try path.toOwnedSlice();
}

const SearchResult = struct {
    distances: []u32,
    came_from: std.AutoHashMap(usize, usize),
};

pub fn dijkstra(allocator: Allocator, map: Map) !SearchResult {
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
    try open_list.add(.{ .priority = 0, .i = map.end });

    var closed = try allocator.alloc(bool, map.width * map.height);
    defer allocator.free(closed);
    @memset(closed, false);

    var dist = try allocator.alloc(u32, map.width * map.height);
    errdefer allocator.free(dist);
    @memset(dist, std.math.maxInt(u32) - 1);

    dist[map.end] = 0;

    var came_from = std.AutoHashMap(usize, usize).init(allocator);
    errdefer came_from.deinit();

    while (open_list.removeOrNull()) |current| {
        const u = current.i;

        // if (current.priority != dist[u]) continue;

        if (closed[u]) continue;
        closed[u] = true;

        for (map.adjacent(u)) |adj| {
            if (adj) |v| {
                if (map.layout[v] == .Wall) continue;
                const alt = dist[u] + 1;
                if (alt < dist[v]) {
                    dist[v] = alt;
                    try came_from.put(v, u);
                }

                try open_list.add(.{ .i = v, .priority = dist[v] });
            }
        }
    }

    return SearchResult{
        .came_from = came_from,
        .distances = dist,
    };
}

fn countShortcutsAtLeast(allocator: Allocator, map: Map, cheat_time: u32) !u32 {
    var r = try dijkstra(allocator, map);
    defer {
        allocator.free(r.distances);
        r.came_from.deinit();
    }
    const normal_path_length = r.distances[map.start];
    const path = try tracePath(allocator, r.came_from, map.start);

    var shortcuts: u32 = 0;

    for (path, 1..) |p, l| {
        const possible_shortcuts = try map.cheated(allocator, p, cheat_time);
        defer allocator.free(possible_shortcuts);

        for (possible_shortcuts) |possible_shortcut| {
            const length = r.distances[possible_shortcut] + l + map.manhattan_distance(p, possible_shortcut) - 1;
            if (normal_path_length >= 100 + length) shortcuts += 1;
        }
    }

    return shortcuts;
}

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("number of cheats that save 100 picoseconds (2 moves): {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u32 {
    const map = try readInput(allocator);
    defer allocator.free(map.layout);

    return countShortcutsAtLeast(allocator, map, 2);
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("number of cheats that save 100 picoseconds (20 moves): {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u32 {
    const map = try readInput(allocator);
    defer allocator.free(map.layout);

    return countShortcutsAtLeast(allocator, map, 20);
}
