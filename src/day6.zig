const std = @import("std");
const Allocator = std.mem.Allocator;

const Direction = enum {
    North,
    West,
    South,
    East,
};

const Vec2 = struct {
    x: u32,
    y: u32,
};

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("distinct positions: {d}\n", .{result});
}

// Solution is a coordinate mess.
pub fn solutionOne(allocator: Allocator) !u32 {
    const file = try std.fs.cwd().openFile("puzzle_input/day6.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buf: [1024]u8 = undefined;

    var obstructions = std.AutoArrayHashMap(Vec2, void).init(allocator);
    defer obstructions.deinit();

    var guard: Vec2 = undefined;
    var guard_direction: Direction = undefined;

    var width: u32 = undefined;

    var y: u32 = 1;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line_lf| : (y += 1) {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);

        width = @intCast(line.len);

        for (line, 1..) |char, x| {
            switch (char) {
                '#' => try obstructions.put(Vec2{ .x = @intCast(x), .y = y }, {}),
                '^' => {
                    guard = .{ .x = @intCast(x), .y = y };
                    guard_direction = .North;
                },
                else => {},
            }
        }
    }

    const height = y - 1;

    var distinct_positions = std.AutoArrayHashMap(Vec2, void).init(allocator);
    defer distinct_positions.deinit();

    while (guard.x > 0 and guard.x <= width and guard.y > 0 and guard.y <= height) {
        try distinct_positions.put(guard, {});

        const new_pos = switch (guard_direction) {
            .North => Vec2{ .x = guard.x, .y = guard.y - 1 },
            .East => Vec2{ .x = guard.x + 1, .y = guard.y },
            .South => Vec2{ .x = guard.x, .y = guard.y + 1 },
            .West => Vec2{ .x = guard.x - 1, .y = guard.y },
        };
        if (obstructions.contains(new_pos)) {
            // Rotate to the right.
            switch (guard_direction) {
                .North => guard_direction = .East,
                .East => guard_direction = .South,
                .South => guard_direction = .West,
                .West => guard_direction = .North,
            }
        } else {
            guard = new_pos;
        }
    }

    return @intCast(distinct_positions.count());
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("different positions to cause loop: {d}\n", .{result});
}

// Most spaghetti code you will ever read. (also kinda slow.)
pub fn solutionTwo(allocator: Allocator) !u32 {
    const file = try std.fs.cwd().openFile("puzzle_input/day6.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buf: [1024]u8 = undefined;

    var obstructions = std.AutoArrayHashMap(Vec2, void).init(allocator);
    defer obstructions.deinit();

    var guard_initial: Vec2 = undefined;
    var guard_direction_initial: Direction = undefined;

    var width: u32 = undefined;

    var y: u32 = 1;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line_lf| : (y += 1) {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);

        width = @intCast(line.len);

        for (line, 1..) |char, x| {
            switch (char) {
                '#' => try obstructions.put(Vec2{ .x = @intCast(x), .y = y }, {}),
                '^' => {
                    guard_initial = .{ .x = @intCast(x), .y = y };
                    guard_direction_initial = .North;
                },
                else => {},
            }
        }
    }

    const height = y - 1;

    var obstruction_causes_loop: u32 = 0;

    for (1..width + 1) |x_ob| {
        for (1..height + 1) |y_ob| {
            const new_obstruction = Vec2{ .x = @intCast(x_ob), .y = @intCast(y_ob) };
            if (obstructions.contains(new_obstruction)) continue;

            try obstructions.put(new_obstruction, {});
            defer _ = obstructions.swapRemove(new_obstruction);

            const T = struct {
                dir: Direction,
                pos: Vec2,
            };

            var distinct_positions = std.AutoArrayHashMap(T, void).init(allocator);
            defer distinct_positions.deinit();

            var guard = guard_initial;
            var guard_direction = guard_direction_initial;

            while (guard.x > 0 and guard.x <= width and guard.y > 0 and guard.y <= height) {
                const key = T{ .dir = guard_direction, .pos = guard };
                if (distinct_positions.contains(key)) {
                    obstruction_causes_loop += 1;
                    break;
                }
                try distinct_positions.put(key, {});

                const new_pos = switch (guard_direction) {
                    .North => Vec2{ .x = guard.x, .y = guard.y - 1 },
                    .East => Vec2{ .x = guard.x + 1, .y = guard.y },
                    .South => Vec2{ .x = guard.x, .y = guard.y + 1 },
                    .West => Vec2{ .x = guard.x - 1, .y = guard.y },
                };
                if (obstructions.contains(new_pos)) {
                    // Rotate to the right.
                    switch (guard_direction) {
                        .North => guard_direction = .East,
                        .East => guard_direction = .South,
                        .South => guard_direction = .West,
                        .West => guard_direction = .North,
                    }
                } else {
                    guard = new_pos;
                }
            }
        }
    }

    return obstruction_causes_loop;
}
