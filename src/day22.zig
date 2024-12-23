const std = @import("std");
const Allocator = std.mem.Allocator;

const SecretValueIterator = struct {
    secret: u64,
    count: usize,

    fn mix(secret: u64, num: u64) u64 {
        return secret ^ num;
    }

    fn prune(secret: u64) u64 {
        return @mod(secret, 16777216);
    }

    // Always returns a value.
    // But returns an optional to be consistent.
    pub fn next(self: *@This()) ?u8 {
        if (self.count == 0) return null;
        self.count -= 1;

        const current: u64 = self.secret;

        var next_secret: u64 = undefined;
        next_secret = mix(self.secret, self.secret * 64);
        next_secret = prune(next_secret);

        next_secret = mix(next_secret, next_secret / 32);
        next_secret = prune(next_secret);

        next_secret = mix(next_secret, next_secret * 2048);
        next_secret = prune(next_secret);

        self.secret = next_secret;
        return @intCast(current % 10);
    }
};

pub fn WindowOfIterator(T: type, R: type, size: comptime_int) type {
    return struct {
        iterator: *T,
        buffer: [size]R = undefined,
        first: bool = true,

        const Self = @This();

        pub fn next(self: *Self) ?[]const R {
            if (!self.first) {
                std.mem.rotate(R, @constCast(@ptrCast(&self.buffer)), 1);
                self.buffer[size - 1] = self.iterator.next() orelse return null;
            } else {
                for (&self.buffer) |*v| {
                    v.* = self.iterator.next() orelse return null;
                }

                self.first = false;
            }

            return @ptrCast(&self.buffer);
        }
    };
}

const Changes = struct {
    a: i8,
    b: i8,
    c: i8,
    d: i8,

    pub fn fromSlice(s: []const u8) @This() {
        std.debug.assert(s.len == 5);

        const @"0": i8 = @intCast(s[0]);
        const @"1": i8 = @intCast(s[1]);
        const @"2": i8 = @intCast(s[2]);
        const @"3": i8 = @intCast(s[3]);
        const @"4": i8 = @intCast(s[4]);

        return .{
            .a = @"1" - @"0",
            .b = @"2" - @"1",
            .c = @"3" - @"2",
            .d = @"4" - @"3",
        };
    }
};

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("{d}\n", .{result});
}

pub fn solutionOne(_: Allocator) !u64 {
    var sum: u64 = 0;

    const file = try std.fs.cwd().openFile("puzzle_input/day22.txt", .{});
    defer file.close();

    var buffer: [1024]u8 = undefined;
    var reader = file.reader();

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        if (line.len == 0) continue;

        const secret = try std.fmt.parseInt(u64, line, 10);

        var it = SecretValueIterator{ .secret = secret, .count = 2000 };
        while (it.next()) |_| {}
        sum += it.secret;
    }

    return sum;
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("best earnings: {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u64 {
    const file = try std.fs.cwd().openFile("puzzle_input/day22.txt", .{});
    defer file.close();

    var buffer: [1024]u8 = undefined;
    var reader = file.reader();

    var seq = std.AutoArrayHashMap(Changes, usize).init(allocator);
    defer seq.deinit();

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        if (line.len == 0) continue;

        const secret = try std.fmt.parseInt(u64, line, 10);

        var seen = std.AutoHashMap(Changes, void).init(allocator);
        defer seen.deinit();

        var value_iterator = SecretValueIterator{ .secret = secret, .count = 2000 };
        var window_iterator = WindowOfIterator(SecretValueIterator, u8, 5){
            .iterator = &value_iterator,
        };

        while (window_iterator.next()) |window| {
            const changes = Changes.fromSlice(window);

            if (seen.contains(changes)) continue;
            try seen.put(changes, {});

            const entry = try seq.getOrPutValue(changes, 0);
            entry.value_ptr.* += window[window.len - 1];
        }
    }

    return std.sort.max(usize, seq.values(), {}, std.sort.asc(usize)) orelse error.NoMaxValue;
}
