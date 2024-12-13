const std = @import("std");
const Allocator = std.mem.Allocator;

const Adjacent = struct {
    n: ?usize,
    e: ?usize,
    s: ?usize,
    w: ?usize,
};

const Garden = struct {
    plots: []u8,
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
};

const Region = struct {
    plots: []usize,
    perimeter: usize,
};

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("total price of all regions (cost = perimiter * area): {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u32 {
    const file = try std.fs.cwd().openFile("puzzle_input/day12.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buffer: [1024]u8 = undefined;

    var garden: Garden = undefined;
    defer allocator.free(garden.plots);

    var plots = std.ArrayList(u8).init(allocator);
    var y: u32 = 0;
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| : (y += 1) {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        garden.width = line.len;
        try plots.appendSlice(line);
    }
    garden.plots = try plots.toOwnedSlice();
    garden.height = y;

    var regions = std.ArrayList(Region).init(allocator);
    defer {
        for (regions.items) |region| {
            allocator.free(region.plots);
        }
        regions.deinit();
    }

    var has_known_region = try allocator.alloc(bool, garden.plots.len);
    @memset(has_known_region, false);

    for (garden.plots, 0..) |plot, i| {
        if (has_known_region[i]) continue;

        var region = std.ArrayList(usize).init(allocator);
        var perimiter: u32 = 0;

        var unvisited = std.ArrayList(usize).init(allocator);
        defer unvisited.deinit();

        try unvisited.append(i);

        while (unvisited.items.len > 0) {
            const n = unvisited.pop();
            if (has_known_region[n]) continue;

            try region.append(n);
            has_known_region[n] = true;

            const adj = garden.getAdjacent(n);

            if (adj.n != null and garden.plots[adj.n.?] == plot) try unvisited.append(adj.n.?);
            if (adj.e != null and garden.plots[adj.e.?] == plot) try unvisited.append(adj.e.?);
            if (adj.s != null and garden.plots[adj.s.?] == plot) try unvisited.append(adj.s.?);
            if (adj.w != null and garden.plots[adj.w.?] == plot) try unvisited.append(adj.w.?);

            if (adj.n) |nidx| {
                if (garden.plots[nidx] != plot) perimiter += 1;
            } else perimiter += 1;
            if (adj.e) |eidx| {
                if (garden.plots[eidx] != plot) perimiter += 1;
            } else perimiter += 1;
            if (adj.s) |sidx| {
                if (garden.plots[sidx] != plot) perimiter += 1;
            } else perimiter += 1;
            if (adj.w) |widx| {
                if (garden.plots[widx] != plot) perimiter += 1;
            } else perimiter += 1;
        }

        try regions.append(Region{
            .perimeter = perimiter,
            .plots = try region.toOwnedSlice(),
        });
    }

    var sum: u32 = 0;
    for (regions.items) |region| {
        sum += @intCast(region.plots.len * region.perimeter);
    }

    return sum;
}

const RegionTwo = struct {
    plots: []usize,
    edges: usize,
};

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("total price of all regions (cost = sides * area): {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u32 {
    const file = try std.fs.cwd().openFile("puzzle_input/day12.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buffer: [1024]u8 = undefined;

    var garden: Garden = undefined;
    defer allocator.free(garden.plots);

    var plots = std.ArrayList(u8).init(allocator);
    var y: u32 = 0;
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| : (y += 1) {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        garden.width = line.len;
        try plots.appendSlice(line);
    }
    garden.plots = try plots.toOwnedSlice();
    garden.height = y;

    var regions = std.ArrayList(RegionTwo).init(allocator);
    defer {
        for (regions.items) |region| {
            allocator.free(region.plots);
        }
        regions.deinit();
    }

    var has_known_region = try allocator.alloc(bool, garden.plots.len);
    @memset(has_known_region, false);

    for (garden.plots, 0..) |plot, i| {
        if (has_known_region[i]) continue;

        // This works but is terrible.
        // Couldn't even be bothered calling deinit()

        var n_edges = std.ArrayList(usize).init(allocator);
        var s_edges = std.ArrayList(usize).init(allocator);
        var e_edges = std.ArrayList(usize).init(allocator);
        var w_edges = std.ArrayList(usize).init(allocator);

        var region = std.ArrayList(usize).init(allocator);

        var unvisited = std.ArrayList(usize).init(allocator);
        defer unvisited.deinit();

        try unvisited.append(i);

        while (unvisited.items.len > 0) {
            const n = unvisited.pop();
            if (has_known_region[n]) continue;

            try region.append(n);
            has_known_region[n] = true;

            const adj = garden.getAdjacent(n);

            if (adj.n != null and garden.plots[adj.n.?] == plot) try unvisited.append(adj.n.?);
            if (adj.e != null and garden.plots[adj.e.?] == plot) try unvisited.append(adj.e.?);
            if (adj.s != null and garden.plots[adj.s.?] == plot) try unvisited.append(adj.s.?);
            if (adj.w != null and garden.plots[adj.w.?] == plot) try unvisited.append(adj.w.?);

            if (adj.n) |idx| {
                if (garden.plots[idx] != plot) try n_edges.append(n);
            } else try n_edges.append(n);
            if (adj.e) |idx| {
                if (garden.plots[idx] != plot) try e_edges.append(n);
            } else try e_edges.append(n);
            if (adj.s) |idx| {
                if (garden.plots[idx] != plot) try s_edges.append(n);
            } else try s_edges.append(n);
            if (adj.w) |idx| {
                if (garden.plots[idx] != plot) try w_edges.append(n);
            } else try w_edges.append(n);
        }

        const lessThanHorizontal = struct {
            fn lessThanFn(context: void, lhs: usize, rhs: usize) bool {
                return std.sort.asc(usize)(context, lhs, rhs);
            }
        }.lessThanFn;

        const lessThanVertical = struct {
            fn lessThanFn(width: usize, lhs: usize, rhs: usize) bool {
                return std.sort.asc(usize)({}, lhs / width, rhs / width);
            }
        }.lessThanFn;

        std.mem.sort(usize, n_edges.items, {}, lessThanHorizontal);
        std.mem.sort(usize, e_edges.items, garden.width, lessThanVertical);
        std.mem.sort(usize, s_edges.items, {}, lessThanHorizontal);
        std.mem.sort(usize, w_edges.items, garden.width, lessThanVertical);

        const Facing = enum {
            N,
            E,
            S,
            W,
        };

        const Range = struct {
            start: usize,
            end: usize,
            dir: Facing,

            pub fn isAdjacent(self: @This(), width: usize, j: usize) bool {
                switch (self.dir) {
                    .N, .S => return self.start == j + 1 or self.end + 1 == j, // start - width == i or end + width == i,
                    .E, .W => return self.start == j + width or self.end + width == j, // start - 1 == width or end + 1 == i
                }
            }
        };
        var edges = std.ArrayList(Range).init(allocator);

        for (n_edges.items) |face| {
            for (edges.items) |*edge| {
                if (edge.dir != .N) continue;
                if (edge.isAdjacent(garden.width, face)) {
                    edge.end = face; // because its sorted.
                    break;
                }
            } else {
                try edges.append(.{
                    .dir = .N,
                    .start = face,
                    .end = face,
                });
            }
        }

        for (e_edges.items) |face| {
            for (edges.items) |*edge| {
                if (edge.dir != .E) continue;
                if (edge.isAdjacent(garden.width, face)) {
                    edge.end = face; // because its sorted.
                    break;
                }
            } else {
                try edges.append(.{
                    .dir = .E,
                    .start = face,
                    .end = face,
                });
            }
        }

        for (s_edges.items) |face| {
            for (edges.items) |*edge| {
                if (edge.dir != .S) continue;
                if (edge.isAdjacent(garden.width, face)) {
                    edge.end = face; // because its sorted.
                    break;
                }
            } else {
                try edges.append(.{
                    .dir = .S,
                    .start = face,
                    .end = face,
                });
            }
        }

        for (w_edges.items) |face| {
            for (edges.items) |*edge| {
                if (edge.dir != .W) continue;
                if (edge.isAdjacent(garden.width, face)) {
                    edge.end = face; // because its sorted.
                    break;
                }
            } else {
                try edges.append(.{
                    .dir = .W,
                    .start = face,
                    .end = face,
                });
            }
        }

        try regions.append(RegionTwo{
            .edges = edges.items.len,
            .plots = try region.toOwnedSlice(),
        });
    }

    var sum: u32 = 0;
    for (regions.items) |region| {
        sum += @intCast(region.plots.len * region.edges);
    }

    return sum;
}
