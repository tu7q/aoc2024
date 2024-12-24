const std = @import("std");
const Allocator = std.mem.Allocator;
const set = @import("ziglangSet");

// TODO: despaghetifi this and clean-up allocations.
// Although it does kinda brute-force search its not slow for input size.

// A bit spaghetti but it works.
pub fn CombinationsIterator(T: type) type {
    return struct {
        buffer: []const T,

        allocator: Allocator,
        indices: ?[]usize,
        size: usize,

        const Self = @This();

        pub fn init(allocator: Allocator, buffer: []const T, size: usize) Self {
            return .{
                .buffer = buffer,
                .allocator = allocator,
                .indices = &[_]usize{},
                .size = size,
            };
        }

        // Based off of this stackoverflow answer: https://stackoverflow.com/a/5731531
        pub fn next(self: *@This(), allocator: Allocator) Allocator.Error!?[]T {
            const indices = blk: {
                const indices = self.indices orelse break :blk null;

                if (indices.len == 0) {
                    self.indices = try self.allocator.alloc(usize, self.size);

                    for (0..self.size) |i| {
                        self.indices.?[i] = i;
                    }

                    const result = try allocator.alloc(T, self.size);
                    for (self.indices.?, 0..) |k, j| {
                        result[j] = self.buffer[k];
                    }

                    return result;
                }

                break :blk indices;
            } orelse return null;

            const n = self.buffer.len;
            const r = self.size;

            if (r > n or r == 0) {
                self.allocator.free(self.indices.?);
                self.indices = null;
                return null;
            }

            var i: isize = @intCast(r - 1);
            while (i >= 0) : (i -= 1) {
                if (indices[@intCast(i)] != @as(usize, @intCast(i)) + n - r) break;
            } else {
                self.allocator.free(self.indices.?);
                self.indices = null;
                return null;
            }

            indices[@intCast(i)] += 1;
            for (@intCast(i + 1)..r) |j| {
                indices[j] = indices[j - 1] + 1;
            }

            const result = try allocator.alloc(T, self.size);
            for (indices, 0..) |k, j| {
                result[j] = self.buffer[k];
            }

            return result;
        }
    };
}

// Good enough.
const PowersetIterator = struct {
    buffer: []const u16,

    current: CombinationsIterator(u16),
    size: usize,

    pub fn init(allocator: Allocator, buffer: []const u16, size: usize) @This() {
        return .{
            .current = CombinationsIterator(u16).init(allocator, buffer, size),
            .buffer = buffer,
            .size = size,
        };
    }

    pub fn next(self: *@This(), allocator: Allocator) !?[]u16 {
        if (self.size == 0) return null;

        var s: ?[]u16 = null;
        while (s == null and self.size > 0) {
            s = try self.current.next(allocator);
            if (s == null) {
                const a = self.current.allocator;
                self.size -= 1;
                self.current = CombinationsIterator(u16).init(a, self.buffer, self.size);
            }
        }

        return s;
    }
};

pub fn into(s: []const u8) u16 {
    std.debug.assert(s.len == 2);

    // Store them in the reverse order.
    const r = @as(u16, @intCast(s[0]));
    const l = @as(u16, @intCast(s[1])) << 8;

    return l + r;
}

pub fn out(s: u16) struct { l: u8, r: u8 } {
    return .{
        .r = @as(u8, @intCast(s >> 8)),
        .l = @as(u8, @intCast(s & std.math.maxInt(u8))),
    };
}

pub fn startswith(s: u16, with: u8) bool {
    return @as(u8, @intCast(s & std.math.maxInt(u8))) == with;
}

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("number of three-interconnected computers that contain at least one computer starting with a t: {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u32 {
    const file = try std.fs.cwd().openFile("puzzle_input/day23.txt", .{});
    defer file.close();

    var buffer: [1024]u8 = undefined;
    var reader = file.reader();

    var arena_impl = std.heap.ArenaAllocator.init(allocator);
    defer arena_impl.deinit();

    const arena = arena_impl.allocator();

    var connections = std.AutoArrayHashMap(u16, set.ArraySetManaged(u16)).init(arena);

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        if (line.len == 0) continue;

        var it = std.mem.splitScalar(u8, line, '-');
        const lhs_slice = it.next().?;
        const rhs_slice = it.next().?;

        const lhs = into(lhs_slice);
        const rhs = into(rhs_slice);

        var lhs_entry = try connections.getOrPut(lhs);
        if (!lhs_entry.found_existing) lhs_entry.value_ptr.* = set.ArraySetManaged(u16).init(allocator);
        _ = try lhs_entry.value_ptr.add(rhs);

        var rhs_entry = try connections.getOrPut(rhs);
        if (!rhs_entry.found_existing) rhs_entry.value_ptr.* = set.ArraySetManaged(u16).init(allocator);
        _ = try rhs_entry.value_ptr.add(lhs);
    }

    var count_startswith_t: usize = 0;

    var it = CombinationsIterator(u16).init(arena, connections.keys(), 3);
    while (try it.next(arena)) |combination| {
        const a = combination[0];
        const b = combination[1];
        const c = combination[2];

        if (startswith(a, 't') or startswith(b, 't') or startswith(c, 't')) {
            const ab = [_]u16{ a, b };
            const ac = [_]u16{ a, c };
            const bc = [_]u16{ b, c };

            if (connections.get(a).?.containsAllSlice(&bc) and connections.get(b).?.containsAllSlice(&ac) and connections.get(c).?.containsAllSlice(&ab)) {
                count_startswith_t += 1;
            }
        }
    }

    return @intCast(count_startswith_t);
}

pub fn allConnected(connections: std.AutoArrayHashMap(u16, set.ArraySetManaged(u16)), items: []u16) bool {
    for (items, 0..) |item, i| {
        const conn = connections.get(item).?;

        const contains_all = conn.containsAllSlice(items[0..i]) and conn.containsAllSlice(items[i + 1 ..]);
        if (!contains_all) return false;
    }

    return true;
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    defer allocator.free(result);
    try writer.print("password for LAN party: {s}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile("puzzle_input/day23.txt", .{});
    defer file.close();

    var buffer: [1024]u8 = undefined;
    var reader = file.reader();

    var arena_impl = std.heap.ArenaAllocator.init(allocator);
    defer arena_impl.deinit();

    const arena = arena_impl.allocator();

    var connections = std.AutoArrayHashMap(u16, set.ArraySetManaged(u16)).init(arena);

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        if (line.len == 0) continue;

        var it = std.mem.splitScalar(u8, line, '-');
        const lhs_slice = it.next().?;
        const rhs_slice = it.next().?;

        const lhs = into(lhs_slice);
        const rhs = into(rhs_slice);

        var lhs_entry = try connections.getOrPut(lhs);
        if (!lhs_entry.found_existing) lhs_entry.value_ptr.* = set.ArraySetManaged(u16).init(allocator);
        _ = try lhs_entry.value_ptr.add(rhs);

        var rhs_entry = try connections.getOrPut(rhs);
        if (!rhs_entry.found_existing) rhs_entry.value_ptr.* = set.ArraySetManaged(u16).init(allocator);
        _ = try rhs_entry.value_ptr.add(lhs);
    }

    var best: []u16 = &[_]u16{};

    for (connections.keys()) |k| {
        const v = connections.get(k).?;

        if (v.cardinality() <= best.len) {
            continue;
        }

        var it = PowersetIterator.init(arena, v.unmanaged.unmanaged.keys(), v.cardinality());
        while (try it.next(allocator)) |sub| {
            if (best.len > sub.len) break;
            // For some reason best.len >= sub.len doesn't work???

            if (allConnected(connections, sub)) {
                best = try arena.alloc(u16, sub.len + 1);
                best[0] = k;
                @memcpy(best[1..], sub);
                break;
            }
        }
    }

    std.mem.sort(u16, best, {}, struct {
        fn inner(_: void, lhs: u16, rhs: u16) bool {
            const lhs_o = out(lhs);
            const lhs_slice: []const u8 = &[_]u8{ lhs_o.l, lhs_o.r };

            const rhs_o = out(rhs);
            const rhs_slice: []const u8 = &[_]u8{ rhs_o.l, rhs_o.r };

            return std.mem.order(u8, lhs_slice, rhs_slice) == .lt;
        }
    }.inner);

    var best_ = std.ArrayList(u8).init(allocator);
    errdefer best_.deinit();

    const writer = best_.writer();

    for (best) |b| {
        const o = out(b);
        try writer.print("{c}{c},", .{ o.l, o.r });
    }

    _ = best_.swapRemove(best_.items.len - 1);

    return best_.toOwnedSlice();
}
