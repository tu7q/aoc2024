const std = @import("std");
const Allocator = std.mem.Allocator;

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("safety factor after 100(s): {d}\n", .{result});
}

pub fn solutionOne(_: Allocator) !u32 {
    const TIME = 100;
    const WIDTH = 101;
    const HEIGHT = 103;

    const file = try std.fs.cwd().openFile("puzzle_input/day14.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buffer: [1024]u8 = undefined;

    var quad1: u32 = 0;
    var quad2: u32 = 0;
    var quad3: u32 = 0;
    var quad4: u32 = 0;

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);

        var it = std.mem.splitScalar(u8, line, ' ');

        const pos = it.next().?;
        const vel = it.next().?;

        var px: i32 = undefined;
        var py: i32 = undefined;
        var vx: i32 = undefined;
        var vy: i32 = undefined;

        {
            const equal = std.mem.indexOfScalar(u8, pos, '=').?;
            const comma = std.mem.indexOfScalar(u8, pos, ',').?;

            px = try std.fmt.parseInt(i32, pos[equal + 1 .. comma], 10);
            py = try std.fmt.parseInt(i32, pos[comma + 1 ..], 10);
        }
        {
            const equal = std.mem.indexOfScalar(u8, vel, '=').?;
            const comma = std.mem.indexOfScalar(u8, vel, ',').?;

            vx = try std.fmt.parseInt(i32, vel[equal + 1 .. comma], 10);
            vy = try std.fmt.parseInt(i32, vel[comma + 1 ..], 10);
        }

        const mx = px + vx * TIME;
        const my = py + vy * TIME;

        const fx = @mod(mx, WIDTH);
        const fy = @mod(my, HEIGHT);

        if (fx == WIDTH / 2 or fy == HEIGHT / 2) continue;

        if (fx < WIDTH / 2 and fy < HEIGHT / 2) quad1 += 1;
        if (fx > WIDTH / 2 and fy < HEIGHT / 2) quad2 += 1;
        if (fx < WIDTH / 2 and fy > HEIGHT / 2) quad3 += 1;
        if (fx > WIDTH / 2 and fy > HEIGHT / 2) quad4 += 1;
    }

    return quad1 * quad2 * quad3 * quad4;
}

const Robot = struct {
    px: i32,
    py: i32,
    vx: i32,
    vy: i32,
};

const Vec2 = struct {
    x: i32,
    y: i32,
};

fn maxInRow(allocator: Allocator, robots: []Robot) !u32 {
    // var positions = std.AutoArrayHashMap(Vec2, bool).init(allocator);
    // defer positions.deinit();
    // for (robots) |r| try positions.put(.{ .x = r.px, .y = r.py }, false);

    var rows = std.AutoArrayHashMap(u32, std.ArrayList(u32)).init(allocator);
    defer {
        for (rows.values()) |v| v.deinit();
        rows.deinit();
    }

    for (robots) |r| {
        const entry = try rows.getOrPut(@intCast(r.py));
        if (!entry.found_existing) entry.value_ptr.* = std.ArrayList(u32).init(allocator);
        try entry.value_ptr.append(@intCast(r.px));
    }

    var longest: u32 = 0;

    for (rows.values()) |row| {
        std.mem.sort(u32, row.items, {}, std.sort.asc(u32));
        // Don't bother to filter out duplicates. (unlikely to affect results)

        var count: u32 = 0;
        for (0..row.items.len) |i| {
            if (i > 0 and row.items[i] == row.items[i - 1] + 1) count += 1 else count = 1;
            longest = @max(longest, count);
        }
    }

    return longest;
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("fewest seconds for easter egg (christmas tree): {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u32 {
    const WIDTH = 101;
    const HEIGHT = 103;

    const file = try std.fs.cwd().openFile("puzzle_input/day14.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buffer: [1024]u8 = undefined;

    var robots = std.ArrayList(Robot).init(allocator);

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);

        var it = std.mem.splitScalar(u8, line, ' ');

        const pos = it.next().?;
        const vel = it.next().?;

        var px: i32 = undefined;
        var py: i32 = undefined;
        var vx: i32 = undefined;
        var vy: i32 = undefined;

        {
            const equal = std.mem.indexOfScalar(u8, pos, '=').?;
            const comma = std.mem.indexOfScalar(u8, pos, ',').?;

            px = try std.fmt.parseInt(i32, pos[equal + 1 .. comma], 10);
            py = try std.fmt.parseInt(i32, pos[comma + 1 ..], 10);
        }
        {
            const equal = std.mem.indexOfScalar(u8, vel, '=').?;
            const comma = std.mem.indexOfScalar(u8, vel, ',').?;

            vx = try std.fmt.parseInt(i32, vel[equal + 1 .. comma], 10);
            vy = try std.fmt.parseInt(i32, vel[comma + 1 ..], 10);
        }

        try robots.append(.{
            .px = px,
            .py = py,
            .vx = vx,
            .vy = vy,
        });
    }

    var t: u32 = 0;
    while (try maxInRow(allocator, robots.items) < 10) : (t += 1) {
        for (robots.items) |*r| {
            r.px = @mod(r.px + r.vx, WIDTH);
            r.py = @mod(r.py + r.vy, HEIGHT);
        }
    }

    return t;
}
