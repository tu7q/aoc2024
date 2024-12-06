const std = @import("std");
const Allocator = std.mem.Allocator;

// TODO: Need to do a refactor on this solution.

fn orderedCorrectly(allocator: Allocator, rules: std.AutoArrayHashMap(u32, std.ArrayList(u32)), order: []u32) !bool {
    var banned = std.ArrayList(u32).init(allocator);
    defer banned.deinit();

    for (order) |page| {
        if (std.mem.containsAtLeast(u32, banned.items, 1, &[_]u32{page})) {
            return false;
        }

        if (rules.get(page)) |required| {
            try banned.appendSlice(required.items);
        }
    }

    return true;
}

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("correctly ordered pages: middle page number sum: {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u32 {
    var accumulator: u32 = 0;

    var rules = std.AutoArrayHashMap(u32, std.ArrayList(u32)).init(allocator);
    defer {
        for (rules.values()) |v| v.deinit();
        rules.deinit();
    }

    const file = try std.fs.cwd().openFile("puzzle_input/day5.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buffer: [1024]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        if (line.len == 0) break;

        var it = std.mem.splitScalar(u8, line, '|');
        const before = try std.fmt.parseUnsigned(u32, it.next().?, 10);
        const after = try std.fmt.parseUnsigned(u32, it.next().?, 10);

        const entry = try rules.getOrPut(after);
        if (!entry.found_existing) {
            entry.value_ptr.* = std.ArrayList(u32).init(allocator);
        }
        try entry.value_ptr.*.append(before);
    }

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);

        var order = std.ArrayList(u32).init(allocator);
        defer order.deinit();

        var it = std.mem.splitScalar(u8, line, ',');
        while (it.next()) |str| {
            const page = try std.fmt.parseUnsigned(u32, str, 10);
            try order.append(page);
        }

        if (try orderedCorrectly(allocator, rules, order.items)) {
            accumulator += order.items[order.items.len / 2];
        }
    }

    return accumulator;
}

fn intersects(a: []u32, b: []u32) ?usize {
    for (a, 0..) |a_, i| {
        for (b) |b_| {
            if (a_ == b_) return i;
        }
    }
    return null;
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("sorted pages: middle page number sum: {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u32 {
    var accumulator: u32 = 0;

    var rules = std.AutoArrayHashMap(u32, std.ArrayList(u32)).init(allocator);
    var a = std.AutoArrayHashMap(u32, std.ArrayList(u32)).init(allocator);
    defer {
        for (rules.values()) |v| v.deinit();
        rules.deinit();

        for (a.values()) |v| v.deinit();
        a.deinit();
    }

    const file = try std.fs.cwd().openFile("puzzle_input/day5.txt", .{});
    defer file.close();

    var reader = file.reader();
    var buffer: [1024]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        if (line.len == 0) break;

        var it = std.mem.splitScalar(u8, line, '|');
        const before = try std.fmt.parseUnsigned(u32, it.next().?, 10);
        const after = try std.fmt.parseUnsigned(u32, it.next().?, 10);

        {
            const entry = try a.getOrPut(after);
            if (!entry.found_existing) {
                entry.value_ptr.* = std.ArrayList(u32).init(allocator);
            }
            try entry.value_ptr.*.append(before);
        }

        const entry = try rules.getOrPut(before);
        if (!entry.found_existing) {
            entry.value_ptr.* = std.ArrayList(u32).init(allocator);
        }
        try entry.value_ptr.*.append(after);
    }

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);

        var pages = std.ArrayList(u32).init(allocator);
        defer pages.deinit();

        var it = std.mem.splitScalar(u8, line, ',');
        while (it.next()) |str| {
            const page = try std.fmt.parseUnsigned(u32, str, 10);
            try pages.append(page);
        }

        // The rules expected are different...
        if (try orderedCorrectly(allocator, a, pages.items)) continue;

        // Dumbass solution lmao.
        // TODO: implement a proper topoglical sorting algorithm *khan's algorithm

        while (!try orderedCorrectly(allocator, a, pages.items)) {
            for (pages.items, 0..) |page, i| {
                if (rules.get(page)) |not_allowed| {
                    if (intersects(pages.items[0..i], not_allowed.items)) |j| {
                        std.mem.swap(u32, &pages.items[i], &pages.items[j]);
                    }
                }
            }
        }
        std.debug.print("res: {d}\n", .{pages.items[pages.items.len / 2]});

        accumulator += pages.items[pages.items.len / 2];
    }

    return accumulator;
}
