const std = @import("std");
const Allocator = std.mem.Allocator;

const Direction = enum {
    North,
    East,
    South,
    West,

    pub fn rotateLeft(self: @This()) @This() {
        return switch (self) {
            .North => .West,
            .East => .North,
            .South => .East,
            .West => .South,
        };
    }

    pub fn rotateRight(self: @This()) @This() {
        return switch (self) {
            .North => .East,
            .East => .South,
            .South => .West,
            .West => .North,
        };
    }
};

const MOVE_COST = 1;
const TURN_COST = 1000;

const Adjacent = struct {
    idx: usize, // Next place,
    dir: Direction, // The direction after moving.
    cost: u32, // the cost of moving.
};

const Kind = enum {
    Wall,
    Empty,
    Start,
    End,
};

const Map = struct {
    allocator: Allocator,
    layout: []const Kind,
    width: usize,
    height: usize,
    start: usize,
    end: usize,

    pub fn fromReader(allocator: Allocator, reader: anytype) !@This() {
        var layout = std.ArrayList(Kind).init(allocator);
        errdefer layout.deinit();

        var map = @This(){
            .allocator = allocator,
            .layout = undefined,
            .width = undefined,
            .height = undefined,
            .start = undefined,
            .end = undefined,
        };

        var buffer: [1024]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
            const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
            map.width = line.len;
            for (line) |c| {
                switch (c) {
                    '.' => try layout.append(.Empty),
                    '#' => try layout.append(.Wall),
                    'S' => {
                        map.start = layout.items.len;
                        try layout.append(.Start);
                    },
                    'E' => {
                        map.end = layout.items.len;
                        try layout.append(.End);
                    },
                    else => unreachable,
                }
            }
        }
        map.height = layout.items.len / map.width;
        map.layout = try layout.toOwnedSlice();
        return map;
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.free(self.layout);
    }

    pub fn print(self: @This()) void {
        for (self.layout, 0..) |k, i| {
            const c: u8 = switch (k) {
                .Wall => '#',
                .Empty => '.',
                .End => 'E',
                .Start => 'S',
            };

            std.debug.print("{c}", .{c});

            if (i % self.width == self.width - 1) std.debug.print("\n", .{});
        }
    }

    // Assumes the next location is valid and in bounds.
    pub fn along(self: @This(), i: usize, f: Direction) usize {
        return switch (f) {
            .North => i - self.width,
            .East => i + 1,
            .South => i + self.width,
            .West => i - 1,
        };
    }

    pub fn next(self: @This(), i: usize, f: Direction) [3]Adjacent {
        var result: [3]Adjacent = undefined;

        // Forward path
        const forward = &result[0];
        forward.cost = MOVE_COST;
        forward.dir = f;
        forward.idx = self.along(i, f);

        const left = &result[1];
        left.cost = MOVE_COST + TURN_COST;
        left.dir = f.rotateLeft();
        left.idx = self.along(i, left.dir);

        const right = &result[2];
        right.cost = MOVE_COST + TURN_COST;
        right.dir = f.rotateRight();
        right.idx = self.along(i, right.dir);

        return result;
    }

    const Node = struct {
        idx: usize,
        dir: Direction,
    };

    pub fn getPath(allocator: Allocator, came_from: std.AutoHashMap(Node, Node), end: Node) ![]usize {
        var path = std.ArrayList(usize).init(allocator);
        errdefer path.deinit();
        try path.append(end.idx);

        var current = end;
        while (came_from.contains(current)) {
            current = came_from.get(current).?;
            try path.insert(0, current.idx);
        }

        return try path.toOwnedSlice();
    }

    pub fn printPath(self: @This(), path: []usize) void {
        for (self.layout, 0..) |k, i| {
            const c: u8 = switch (k) {
                .Wall => '#',
                .Empty => '.',
                .End => 'E',
                .Start => 'S',
            };

            const bold = std.mem.containsAtLeast(usize, path, 1, &[_]usize{i});

            if (bold) {
                std.debug.print("\x1b[1mO\x1b[m", .{});
            } else {
                std.debug.print("{c}", .{c});
            }

            if (i % self.width == self.width - 1) std.debug.print("\n", .{});
        }
    }

    // manhattan distance
    pub fn h(self: @This(), node: Node) u32 {
        const ex = self.end % self.width;
        const ey = self.end / self.width;
        const nx = node.idx % self.width;
        const ny = node.idx / self.width;

        const x_abs = if (ex > nx) ex - nx else nx - ex;
        const y_abs = if (ey > ny) ey - ny else ny - ey;
        return @intCast(x_abs + y_abs);
    }

    pub fn lowestScore(self: @This(), allocator: Allocator) !u32 {
        const start = Node{
            .idx = self.start,
            .dir = .East,
        };

        // Min queue
        const QItem = struct {
            priority: u32,
            node: Node,
        };
        const PQlt = std.PriorityQueue(QItem, void, struct {
            pub fn lessThan(_: void, a: QItem, b: QItem) std.math.Order {
                return std.math.order(a.priority, b.priority);
            }
        }.lessThan);

        // Open set
        var open_list = PQlt.init(allocator, {});
        defer open_list.deinit();
        try open_list.add(.{ .priority = 0, .node = start });

        // Used to find path at the end.
        var came_from = std.AutoHashMap(Node, Node).init(allocator);
        defer came_from.deinit();

        // For node n, g_score[n] is the currently known cost of the cheapest path from start to n.
        var g_score = std.AutoHashMap(Node, u32).init(allocator);
        defer g_score.deinit();
        try g_score.put(start, 0);

        // For node n, f_score[n] := g_score[n] + h(n). f_score[n] represents the best current guess of
        // how cheaap a path could be from start to finish if it goes through n.
        var f_score = std.AutoHashMap(Node, u32).init(allocator);
        defer f_score.deinit();
        try f_score.put(start, self.h(start));

        while (open_list.removeOrNull()) |current| {
            const u = current.node;
            if (u.idx == self.end) {
                // self.printPath(try getPath(allocator, came_from, u));
                return g_score.get(u).?; // Total cost of path.
            }

            for (self.next(u.idx, u.dir)) |adj| {
                if (self.layout[adj.idx] == .Wall) continue;

                // std.debug.print("{d} {d}\n", .{ g_score.get(u).?, adj.cost });
                const tentative_g_score = g_score.get(u).? + adj.cost;
                const v = Node{ .idx = adj.idx, .dir = adj.dir };
                const known_g = try g_score.getOrPutValue(v, std.math.maxInt(u32));

                // if (tentative_g_score == known_g.value_ptr.*)
                //  and (came_from[v] != came_from[u])
                // Then there exists another path from from the start to v with equal length.
                // How to remember this...

                if (tentative_g_score < known_g.value_ptr.*) {
                    try came_from.put(v, u);
                    try g_score.put(v, tentative_g_score);
                    const f = tentative_g_score + self.h(v);
                    try f_score.put(v, f);
                    try open_list.add(.{ .priority = f, .node = v });
                }
            }
        }

        return error.NoPath;
    }

    pub fn numTiles(self: @This(), allocator: Allocator) !u32 {
        const start = Node{
            .idx = self.start,
            .dir = .East,
        };

        // Min queue
        const QItem = struct {
            priority: u32,
            node: Node,
        };
        const PQlt = std.PriorityQueue(QItem, void, struct {
            pub fn lessThan(_: void, a: QItem, b: QItem) std.math.Order {
                return std.math.order(a.priority, b.priority);
            }
        }.lessThan);

        // Open set
        var open_list = PQlt.init(allocator, {});
        defer open_list.deinit();
        try open_list.add(.{ .priority = 0, .node = start });

        // Used to find path at the end.
        var came_from = std.AutoHashMap(Node, std.AutoArrayHashMap(Node, void)).init(allocator);
        defer came_from.deinit();

        // For node n, g_score[n] is the currently known cost of the cheapest path from start to n.
        var g_score = std.AutoHashMap(Node, u32).init(allocator);
        defer g_score.deinit();
        try g_score.put(start, 0);

        // For node n, f_score[n] := g_score[n] + h(n). f_score[n] represents the best current guess of
        // how cheaap a path could be from start to finish if it goes through n.
        var f_score = std.AutoHashMap(Node, u32).init(allocator);
        defer f_score.deinit();
        try f_score.put(start, self.h(start));

        var maybe_score: ?u32 = null;

        while (open_list.removeOrNull()) |current| {
            const u = current.node;

            if (u.idx == self.end) {
                std.debug.print("new path found\n", .{});
            }

            if (u.idx == self.end and maybe_score == null) {
                maybe_score = g_score.get(u).?;
            }

            for (self.next(u.idx, u.dir)) |adj| {
                if (self.layout[adj.idx] == .Wall) continue;

                // std.debug.print("{d} {d}\n", .{ g_score.get(u).?, adj.cost });
                const tentative_g_score = g_score.get(u).? + adj.cost;
                const v = Node{ .idx = adj.idx, .dir = adj.dir };
                const known_g = try g_score.getOrPutValue(v, std.math.maxInt(u32));

                // if (tentative_g_score == known_g.value_ptr.*)
                //  and (came_from[v] != came_from[u])
                // Then there exists another path from from the start to v with equal length.
                // How to remember this...

                if (tentative_g_score == known_g.value_ptr.*) {
                    const e = try came_from.getOrPutValue(v, std.AutoArrayHashMap(Node, void).init(allocator));
                    try e.value_ptr.put(u, {});
                } else if (tentative_g_score < known_g.value_ptr.*) {
                    var r = std.AutoArrayHashMap(Node, void).init(allocator);
                    try r.put(u, {});
                    try came_from.put(v, r);

                    try g_score.put(v, tentative_g_score);
                    const f = tentative_g_score + self.h(v);
                    try f_score.put(v, f);
                    try open_list.add(.{ .priority = f, .node = v });
                }
            }
        }

        const score = maybe_score orelse unreachable; // Assume that a path was found.

        // Assume a path exists.
        var tile_indices = std.AutoArrayHashMap(usize, void).init(allocator);
        defer tile_indices.deinit();

        var tiles = std.ArrayList(Node).init(allocator);
        defer tiles.deinit();

        if (f_score.get(.{ .idx = self.end, .dir = .North }) == score) {
            try tiles.append(.{ .idx = self.end, .dir = .North });
        }
        if (f_score.get(.{ .idx = self.end, .dir = .East }) == score) {
            try tiles.append(.{ .idx = self.end, .dir = .East });
        }
        if (f_score.get(.{ .idx = self.end, .dir = .South }) == score) {
            try tiles.append(.{ .idx = self.end, .dir = .South });
        }
        if (f_score.get(.{ .idx = self.end, .dir = .West }) == score) {
            try tiles.append(.{ .idx = self.end, .dir = .West });
        }

        while (tiles.popOrNull()) |n| {
            try tile_indices.put(n.idx, {});
            const from = came_from.get(n) orelse continue;

            for (from.keys()) |k| {
                try tiles.append(k);
                try tile_indices.put(k.idx, {});
            }
        }

        self.printPath(tile_indices.keys());

        return @intCast(tile_indices.count());
    }
};

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("lowest score: {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u32 {
    const file = try std.fs.cwd().openFile("puzzle_input/day16.txt", .{});
    defer file.close();

    const reader = file.reader();

    const map = try Map.fromReader(allocator, reader);

    return map.lowestScore(allocator);
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("tiles: {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u32 {
    const file = try std.fs.cwd().openFile("puzzle_input/day16.txt", .{});
    defer file.close();

    const reader = file.reader();

    const map = try Map.fromReader(allocator, reader);

    return try map.numTiles(allocator);
}

// TODO: Move h() to a variable of ShortestPathIterator.

const Path = struct {
    score: u32,
    elements: []usize,
};

// // This iterator doesn't work very well...

// // Iterator over all shortest paths
// // using A* algorithm
// const ShortestPathIterator = struct {
//     // Node element
//     const Node = struct {
//         idx: usize,
//         dir: Direction,
//     };

//     // Min queue
//     const QItem = struct {
//         priority: u32,
//         node: Node,
//     };
//     const PQlt = std.PriorityQueue(QItem, void, struct {
//         pub fn lessThan(_: void, a: QItem, b: QItem) std.math.Order {
//             return std.math.order(a.priority, b.priority);
//         }
//     }.lessThan);

//     const Score = std.AutoHashMapUnmanaged(Node, u32);

//     allocator: Allocator,
//     map: Map,
//     come_from: std.AutoHashMapUnmanaged(Node, Node),
//     open_list: PQlt,
//     g_score: Score,
//     f_score: Score,

//     pub fn init(allocator: Allocator, map: Map) Allocator.Error!@This() {
//         const start = Node{
//             .idx = map.start,
//             .dir = .East,
//         };

//         const came_from = std.AutoHashMapUnmanaged(Node, Node){};
//         var open_list = PQlt.init(allocator, {});
//         var g_score = Score{};
//         var f_score = Score{};

//         try open_list.add(.{ .priority = 0, .node = start });
//         try g_score.put(allocator, start, 0);
//         try f_score.put(allocator, start, map.h(start));

//         return .{
//             .allocator = allocator,
//             .map = map,
//             .came_from = came_from,
//             .f_score = f_score,
//             .g_score = g_score,
//         };
//     }

//     pub fn deinit(self: *@This()) void {
//         self.come_from.deinit(self.allocator);
//         self.open_list.deinit();
//         self.f_score.deinit(self.allocator);
//         self.g_score.deinit(self.allocator);
//         self.* = undefined;
//     }

//     pub fn tracePath(self: @This(), allocator: Allocator, n: Node) []usize {
//         var path = std.ArrayList(usize).init(allocator);
//         errdefer path.deinit();

//         try path.append(n);
//         var current = n;

//         while (self.come_from.contains(current)) {
//             current = self.come_from.get(current).?;
//             try path.insert(0, current);
//         }

//         return try path.toOwnedSlice();
//     }

//     pub fn next(self: @This(), allocator: Allocator) !?Path {
//         while (self.open_list.removeOrNull()) |current| {
//             const u = current.node;
//             if (u.idx == self.map.end) return .{
//                 .score = self.g_score.get(u).?,
//                 .elements = self.tracePath(allocator),
//             };

//             for (self.map.next(u.idx, u.dir)) |adj| {
//                 if (self.layout[adj.idx] == .Wall) continue;

//                 const tentative_g_score = self.g_score.get(u).? + adj.cost;
//                 const v = Node{ .idx = adj.idx, .dir = adj.dir };
//                 const known_g = try self.g_score.getOrPutValue(self.allocator, v, std.math.maxInt(u32));

//                 if (tentative_g_score == known_g.value_ptr.*) {
//                     // uhhhh. What to do ???
//                 } else if (tentative_g_score < known_g.value_ptr.*) {
//                     try self.g_score.put(v, tentative_g_score);
//                     const f = tentative_g_score + self.map.h(v);
//                     try self.f_score.put(v, f);
//                     try self.open_list.add(.{ .priority = f, .node = v });
//                 }
//             }
//         }

//         return null;
//     }
// };
