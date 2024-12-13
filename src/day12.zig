const std = @import("std");
const Allocator = std.mem.Allocator;

// FIXME: this entire file.

const Adjacent = struct {
    n: ?usize,
    e: ?usize,
    s: ?usize,
    w: ?usize,
};

const AdjacentValues = struct {
    n: ?u8,
    ne: ?u8,
    e: ?u8,
    se: ?u8,
    s: ?u8,
    sw: ?u8,
    w: ?u8,
    nw: ?u8,
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

    pub fn getAdjacentValues(self: @This(), i: usize) AdjacentValues {
        const y = i / self.width;
        const x = i % self.width;

        const north = y > 0;
        const east = x + 1 < self.width;
        const south = y + 1 < self.height;
        const west = x > 0;

        const n_idx: ?usize = if (north) (y - 1) * self.width + x else null;
        const s_idx: ?usize = if (south) (y + 1) * self.width + x else null;

        return AdjacentValues{
            .nw = if (west and north) self.plots[n_idx.? - 1] else null,
            .n = if (north) self.plots[n_idx.?] else null,
            .ne = if (north and east) self.plots[n_idx.? + 1] else null,
            .e = if (east) self.plots[i + 1] else null,
            .se = if (south and east) self.plots[s_idx.? + 1] else null,
            .s = if (south) self.plots[s_idx.?] else null,
            .sw = if (south and west) self.plots[s_idx.? - 1] else null,
            .w = if (west) self.plots[i - 1] else null,
        };
    }

    // The number of corners at a given tile.
    pub fn numCorners(self: @This(), i: usize) u8 {
        const c = self.plots[i];
        const adj = self.getAdjacentValues(i);

        var count: u8 = 0;

        // Check for corner in the north west.
        if (adj.nw != c) {
            if ((adj.n == c and adj.w == c) or (adj.n != c and adj.w != c)) {
                count += 1;
            }
        } else if (adj.n != c and adj.w != c) count += 1;

        // Check for corner in the north east
        if (adj.ne != c) {
            if ((adj.n == c and adj.e == c) or (adj.n != c and adj.e != c)) {
                count += 1;
            }
        } else if (adj.n != c and adj.e != c) count += 1;

        // Check for corner in the south west
        if (adj.sw != c) {
            if ((adj.s == c and adj.w == c) or (adj.s != c and adj.w != c)) {
                count += 1;
            }
        } else if (adj.s != c and adj.w != c) count += 1;

        // Check for corner in the south east
        if (adj.se != c) {
            if ((adj.s == c and adj.e == c) or (adj.s != c and adj.e != c)) {
                count += 1;
            }
        } else if (adj.s != c and adj.e != c) count += 1;

        return count;
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

        var region = std.ArrayList(usize).init(allocator);

        var corners: u32 = 0;

        var unvisited = std.ArrayList(usize).init(allocator);
        defer unvisited.deinit();

        try unvisited.append(i);

        while (unvisited.items.len > 0) {
            const n = unvisited.pop();
            if (has_known_region[n]) continue;

            try region.append(n);

            corners += garden.numCorners(n);
            has_known_region[n] = true;

            const adj = garden.getAdjacent(n);

            if (adj.n != null and garden.plots[adj.n.?] == plot) try unvisited.append(adj.n.?);
            if (adj.e != null and garden.plots[adj.e.?] == plot) try unvisited.append(adj.e.?);
            if (adj.s != null and garden.plots[adj.s.?] == plot) try unvisited.append(adj.s.?);
            if (adj.w != null and garden.plots[adj.w.?] == plot) try unvisited.append(adj.w.?);
        }

        try regions.append(RegionTwo{
            .edges = corners,
            .plots = try region.toOwnedSlice(),
        });
    }

    var sum: u32 = 0;
    for (regions.items) |region| {
        sum += @intCast(region.plots.len * region.edges);
    }

    return sum;
}
