const std = @import("std");
const Allocator = std.mem.Allocator;

const Direction = enum {
    North,
    East,
    South,
    West,
};

const Kind = enum {
    Wall,
    Object,
    Empty,
    Robot,
};

const Map = struct {
    allocator: Allocator,
    width: usize,
    height: usize,
    robot: usize,
    layout: []Kind,

    pub fn fromFile(allocator: Allocator, reader: anytype) !@This() {
        var map: @This() = .{
            .allocator = allocator,
            .width = undefined,
            .height = undefined,
            .robot = undefined,
            .layout = undefined,
        };

        var layout = std.ArrayList(Kind).init(allocator);
        errdefer layout.deinit();

        var buffer: [1024]u8 = undefined;

        // TODO: use reader.readUntilDelimiter instead.
        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
            const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
            if (line.len == 0) break;

            map.width = line.len;
            for (line) |c| {
                switch (c) {
                    '#' => try layout.append(.Wall),
                    'O' => try layout.append(.Object),
                    '@' => {
                        try layout.append(.Robot);
                        map.robot = layout.items.len - 1; // index of last element.
                    },
                    '.' => try layout.append(.Empty),
                    else => unreachable,
                }
            }
        }
        map.height = layout.items.len / map.width;

        map.layout = try layout.toOwnedSlice();
        return map;
    }

    // Assumes that the next state can't be invalid. ie outside of the map.
    fn next(self: @This(), i: usize, direction: Direction) struct { usize, Kind } {
        const x = i % self.width;
        const y = i / self.width; // probably.

        const idx: usize = switch (direction) {
            .North => (y - 1) * self.width + x,
            .East => i + 1,
            .South => (y + 1) * self.width + x,
            .West => i - 1,
        };

        return .{ idx, self.layout[idx] };
    }

    fn move(self: *@This(), p: usize, direction: Direction) bool {
        switch (self.layout[p]) {
            .Wall => return false,
            .Object, .Robot => {
                return self.move(self.next(p, direction).@"0", direction);
            },
            .Empty => {
                self.layout[p] = .Object;
                return true;
            },
        }
    }

    pub fn moveRobot(self: *@This(), direction: Direction) void {
        if (self.move(self.robot, direction)) {
            self.layout[self.robot] = .Empty;
            self.robot = self.next(self.robot, direction).@"0";
            self.layout[self.robot] = .Robot;
        }
    }

    pub fn sumGPSCoordinates(self: @This()) u32 {
        var ans: u32 = 0;
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                if (self.layout[y * self.width + x] == .Object) ans += @intCast(100 * y + x);
            }
        }
        return ans;
    }
};

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("sum of GPS coordinates: {d}\n", .{result});
}

// A few cases.
// @.  (> nothing in its way so it can move.)
// @O. (> Object in its way but there is an empty space after the object so it can be pushed.)
// @#  (> cannot move since there is a wall preventing movement)
// @O# (> cannot move since there is a wall preventing pushing)

pub fn solutionOne(allocator: Allocator) !u32 {
    const file = try std.fs.cwd().openFile("puzzle_input/day15.txt", .{});
    defer file.close();

    var reader = file.reader();

    var map = try Map.fromFile(allocator, reader);
    const moves = blk: {
        var moves = std.ArrayList(Direction).init(allocator);
        errdefer moves.deinit();
        var buffer: [1024]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
            const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
            for (line) |c| {
                switch (c) {
                    '^' => try moves.append(.North),
                    '>' => try moves.append(.East),
                    'v' => try moves.append(.South),
                    '<' => try moves.append(.West),
                    else => unreachable,
                }
            }
        }
        break :blk try moves.toOwnedSlice();
    };

    for (moves) |move| {
        map.moveRobot(move);
    }

    return map.sumGPSCoordinates();
}

const WideKind = enum {
    Wall,
    ObjectLeft,
    ObjectRight,
    Empty,
    Robot,
};

const WideMap = struct {
    allocator: Allocator,
    width: usize,
    height: usize,
    robot: usize,
    layout: []WideKind,

    pub fn fromFile(allocator: Allocator, reader: anytype) !@This() {
        var map: @This() = .{
            .allocator = allocator,
            .width = undefined,
            .height = undefined,
            .robot = undefined,
            .layout = undefined,
        };

        var layout = std.ArrayList(WideKind).init(allocator);
        errdefer layout.deinit();

        var buffer: [1024]u8 = undefined;

        // TODO: use reader.readUntilDelimiter instead.
        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
            const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
            if (line.len == 0) break;

            map.width = line.len * 2;
            for (line) |c| {
                switch (c) {
                    '#' => try layout.appendSlice(&[2]WideKind{ .Wall, .Wall }),
                    'O' => try layout.appendSlice(&[2]WideKind{ .ObjectLeft, .ObjectRight }),
                    '@' => {
                        try layout.appendSlice(&[2]WideKind{ .Robot, .Empty });
                        map.robot = layout.items.len - 2; // index of 2nd last element.
                    },
                    '.' => try layout.appendSlice(&[2]WideKind{ .Empty, .Empty }),
                    else => unreachable,
                }
            }
        }
        map.height = layout.items.len / map.width;

        map.layout = try layout.toOwnedSlice();
        return map;
    }

    // Assumes that the next state can't be invalid. ie outside of the map.
    fn next(self: @This(), i: usize, direction: Direction) usize {
        const x = i % self.width;
        const y = i / self.width; // probably.

        return switch (direction) {
            .North => (y - 1) * self.width + x,
            .East => i + 1,
            .South => (y + 1) * self.width + x,
            .West => i - 1,
        };
    }

    pub fn moveRobot(self: *@This(), allocator: Allocator, direction: Direction) !void {
        var seen = std.AutoArrayHashMap(usize, void).init(allocator);
        defer seen.deinit();

        var Q = std.ArrayList(usize).init(allocator);
        defer Q.deinit();

        try Q.append(self.robot);

        while (Q.items.len > 0) {
            const n = Q.pop();
            if (seen.contains(n)) continue;
            try seen.put(n, {});

            const a = self.next(n, direction);

            switch (self.layout[a]) {
                .Wall => return, // Don't
                .Robot, .Empty => continue,
                .ObjectLeft, .ObjectRight => |obj| {
                    try Q.append(a);
                    if (obj == .ObjectLeft) try Q.append(a + 1);
                    if (obj == .ObjectRight) try Q.append(a - 1);
                },
            }
        }

        const Context = struct {
            width: usize,
            direction: Direction,
        };

        std.mem.sort(usize, seen.keys(), Context{
            .width = self.width,
            .direction = direction,
        }, struct {
            pub fn lessThanFn(ctxt: Context, lhs: usize, rhs: usize) bool {
                const lhs_x = lhs % ctxt.width;
                const rhs_x = rhs % ctxt.width;
                const lhs_y = lhs / ctxt.width;
                const rhs_y = rhs / ctxt.width;

                switch (ctxt.direction) {
                    // The y-axis ordering is inverted compared to the x-axis since (0, 0) is at the top left.
                    .North => return std.sort.asc(usize)({}, lhs_y, rhs_y),
                    .South => return std.sort.desc(usize)({}, lhs_y, rhs_y),
                    .East => return std.sort.desc(usize)({}, lhs_x, rhs_x),
                    .West => return std.sort.asc(usize)({}, lhs_x, rhs_x),
                }
            }
        }.lessThanFn);

        for (seen.keys()) |i| {
            const j = self.next(i, direction);
            self.layout[j] = self.layout[i];
            self.layout[i] = .Empty;
        }

        self.robot = self.next(self.robot, direction);
    }

    pub fn sumGPSCoordinates(self: @This()) u32 {
        var ans: u32 = 0;
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const v = self.layout[y * self.width + x];
                if (v == .ObjectLeft) ans += @intCast(100 * y + x);
            }
        }
        return ans;
    }
};

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("sum of GPS coordinates (wide map): {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u32 {
    const file = try std.fs.cwd().openFile("puzzle_input/day15.txt", .{});
    defer file.close();

    var reader = file.reader();

    var map = try WideMap.fromFile(allocator, reader);
    const moves = blk: {
        var moves = std.ArrayList(Direction).init(allocator);
        errdefer moves.deinit();
        var buffer: [1024]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
            const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
            for (line) |c| {
                switch (c) {
                    '^' => try moves.append(.North),
                    '>' => try moves.append(.East),
                    'v' => try moves.append(.South),
                    '<' => try moves.append(.West),
                    else => unreachable,
                }
            }
        }
        break :blk try moves.toOwnedSlice();
    };

    for (moves) |move| {
        try map.moveRobot(allocator, move);
        // std.debug.print("{any}\n", .{move});
        // for (0..map.layout.len) |i| {
        //     const c: u8 = switch (map.layout[i]) {
        //         .Empty => '.',
        //         .ObjectLeft => '[',
        //         .ObjectRight => ']',
        //         .Robot => '@',
        //         .Wall => '#',
        //     };

        //     std.debug.print("{c}", .{c});

        //     if ((i % map.width) == map.width - 1) {
        //         std.debug.print("\n", .{});
        //     }
        // }
    }

    for (0..map.layout.len) |i| {
        const c: u8 = switch (map.layout[i]) {
            .Empty => '.',
            .ObjectLeft => '[',
            .ObjectRight => ']',
            .Robot => '@',
            .Wall => '#',
        };

        std.debug.print("{c}", .{c});

        if ((i % map.width) == map.width - 1) {
            std.debug.print("\n", .{});
        }
    }

    return map.sumGPSCoordinates();
}
