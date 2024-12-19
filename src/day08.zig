const std = @import("std");
const Allocator = std.mem.Allocator;

const Bound = struct {
    min_x: isize,
    min_y: isize,
    max_x: isize,
    max_y: isize,

    pub fn contains(self: @This(), v: Vec2) bool {
        if (v.x >= self.min_x and v.x <= self.max_x and v.y >= self.min_y and v.y <= self.max_y) {
            return true;
        }
        return false;
    }
};

const Vec2 = struct {
    x: isize,
    y: isize,
};

fn Pair(T: type) type {
    return std.meta.Tuple(&.{ T, T });
}

fn PairIterator(T: type) type {
    return struct {
        buffer: []T,
        indicies: ?struct {
            i: usize,
            j: usize,
        },

        // Note that it is possible to have (i, j) and (j, i)
        pub fn next(self: *@This()) ?Pair(T) {
            const current = self.indicies orelse return null;
            self.advance();
            return .{ self.buffer[current.i], self.buffer[current.j] };
        }

        fn advance(self: *@This()) void {
            if (self.indicies == null) return;

            if (self.indicies.?.j + 1 == self.buffer.len) {
                if (self.indicies.?.i + 1 == self.buffer.len) {
                    self.indicies = null;
                } else {
                    self.indicies.?.j = 0;
                    self.indicies.?.i += 1;
                }
            } else {
                self.indicies.?.j += 1;
                if (self.indicies.?.i == self.indicies.?.j) self.advance();
            }
        }
    };
}

fn pairs(T: type, buffer: []T) PairIterator(T) {
    std.debug.assert(buffer.len >= 2);
    return .{
        .buffer = buffer,
        .indicies = .{
            .i = 0,
            .j = 1,
        },
    };
}

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("unique antinodal positions: {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u32 {
    const file = try std.fs.cwd().openFile("puzzle_input/day8.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buf: [1024]u8 = undefined;

    var antennas = std.AutoArrayHashMap(u8, std.ArrayList(Vec2)).init(allocator);
    defer {
        for (antennas.values()) |list| {
            list.deinit();
        }
        antennas.deinit();
    }

    var y: usize = 0;
    var w: usize = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line_lf| : (y += 1) {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        w = line.len;
        for (line, 0..) |c, x| {
            switch (c) {
                '.' => {},
                else => {
                    const entry = try antennas.getOrPut(c);
                    if (!entry.found_existing) {
                        entry.value_ptr.* = std.ArrayList(Vec2).init(allocator);
                    }
                    try entry.value_ptr.append(Vec2{
                        .x = @intCast(x),
                        .y = @intCast(y),
                    });
                },
            }
        }
    }

    const bound = Bound{
        .min_x = 0,
        .min_y = 0,
        .max_x = @intCast(w - 1),
        .max_y = @intCast(y - 1),
    };

    var antinodes = std.AutoArrayHashMap(Vec2, void).init(allocator);
    defer antinodes.deinit();

    for (antennas.values()) |same_anttenas| {
        var it = pairs(Vec2, same_anttenas.items);
        while (it.next()) |antenna_pair| {
            const a = antenna_pair.@"0";
            const b = antenna_pair.@"1";

            const x_diff = a.x - b.x;
            const y_diff = a.y - b.y;

            const f = Vec2{ .x = a.x + x_diff, .y = a.y + y_diff };
            const g = Vec2{ .x = b.x - x_diff, .y = b.y - y_diff };

            if (bound.contains(f)) {
                try antinodes.put(f, {});
            }

            if (bound.contains(g)) {
                try antinodes.put(g, {});
            }
        }
    }

    return @intCast(antinodes.count());
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("unique antinodal positions (w/ resonant freq): {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u32 {
    const file = try std.fs.cwd().openFile("puzzle_input/day8.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buf: [1024]u8 = undefined;

    var antennas = std.AutoArrayHashMap(u8, std.ArrayList(Vec2)).init(allocator);
    defer {
        for (antennas.values()) |list| {
            list.deinit();
        }
        antennas.deinit();
    }

    var y: usize = 0;
    var w: usize = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line_lf| : (y += 1) {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        w = line.len;
        for (line, 0..) |c, x| {
            switch (c) {
                '.' => {},
                else => {
                    const entry = try antennas.getOrPut(c);
                    if (!entry.found_existing) {
                        entry.value_ptr.* = std.ArrayList(Vec2).init(allocator);
                    }
                    try entry.value_ptr.append(Vec2{
                        .x = @intCast(x),
                        .y = @intCast(y),
                    });
                },
            }
        }
    }

    const bound = Bound{
        .min_x = 0,
        .min_y = 0,
        .max_x = @intCast(w - 1),
        .max_y = @intCast(y - 1),
    };

    var antinodes = std.AutoArrayHashMap(Vec2, void).init(allocator);
    defer antinodes.deinit();

    for (antennas.values()) |same_anttenas| {
        var it = pairs(Vec2, same_anttenas.items);
        while (it.next()) |antenna_pair| {
            const a = antenna_pair.@"0";
            const b = antenna_pair.@"1";

            const x_diff = a.x - b.x;
            const y_diff = a.y - b.y;

            var @"a+" = a;
            while (bound.contains(@"a+")) : ({
                @"a+".x += x_diff;
                @"a+".y += y_diff;
            }) {
                try antinodes.put(@"a+", {});
            }

            var @"b+" = b;
            while (bound.contains(@"b+")) : ({
                @"b+".x -= x_diff;
                @"b+".y -= y_diff;
            }) {
                try antinodes.put(@"b+", {});
            }
        }
    }

    return @intCast(antinodes.count());
}
