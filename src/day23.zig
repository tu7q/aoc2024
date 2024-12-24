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
    buffer: []const Name,

    current: CombinationsIterator(Name),
    size: usize,

    pub fn init(allocator: Allocator, buffer: []const Name, size: usize) @This() {
        return .{
            .current = CombinationsIterator(Name).init(allocator, buffer, size),
            .buffer = buffer,
            .size = size,
        };
    }

    pub fn next(self: *@This(), allocator: Allocator) !?[]Name {
        if (self.size == 0) return null;

        var s: ?[]Name = null;
        while (s == null and self.size > 0) {
            s = try self.current.next(allocator);
            if (s == null) {
                const a = self.current.allocator;
                self.size -= 1;
                self.current = CombinationsIterator(Name).init(a, self.buffer, self.size);
            }
        }

        return s;
    }
};

// Each name is two characters.
const Name = struct {
    l: u8, // left
    r: u8, // right

    // from slice
    fn fromSlice(slice: []const u8) @This() {
        std.debug.assert(slice.len == 2);

        return .{
            .l = slice[0],
            .r = slice[1],
        };
    }

    // Converts to an ordered array.
    fn toArray(self: @This()) [2]u8 {
        var array: [2]u8 = undefined;
        array[0] = self.l;
        array[1] = self.r;
        return array;
    }

    fn lessThan(context: void, lhs: @This(), rhs: @This()) bool {
        _ = context;
        return std.mem.order(u8, &lhs.toArray(), &rhs.toArray()) == .lt;
    }

    fn startsWithScalar(self: @This(), scalar: u8) bool {
        return self.l == scalar;
    }
};

const Connections = std.AutoArrayHashMap(Name, set.ArraySetManaged(Name));

fn readInput(allocator: Allocator, reader: anytype) !Connections {
    var buffer: [1024]u8 = undefined;

    var connections = Connections.init(allocator);
    errdefer {
        for (connections.values()) |*v| v.deinit();
        connections.deinit();
    }

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line_lf| {
        const line = std.mem.trim(u8, line_lf, &std.ascii.whitespace);
        if (line.len == 0) continue;

        var it = std.mem.splitScalar(u8, line, '-');
        const lhs_slice = it.next().?;
        const rhs_slice = it.next().?;

        const lhs = Name.fromSlice(lhs_slice);
        const rhs = Name.fromSlice(rhs_slice);

        var lhs_entry = try connections.getOrPut(lhs);
        if (!lhs_entry.found_existing) lhs_entry.value_ptr.* = set.ArraySetManaged(Name).init(allocator);
        _ = try lhs_entry.value_ptr.add(rhs);

        var rhs_entry = try connections.getOrPut(rhs);
        if (!rhs_entry.found_existing) rhs_entry.value_ptr.* = set.ArraySetManaged(Name).init(allocator);
        _ = try rhs_entry.value_ptr.add(lhs);
    }

    return connections;
}

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("number of three-interconnected computers that contain at least one computer starting with a t: {d}\n", .{result});
}

pub fn solutionOne(allocator: Allocator) !u32 {
    var arena_impl = std.heap.ArenaAllocator.init(allocator);
    defer arena_impl.deinit();

    const arena = arena_impl.allocator();

    const file = try std.fs.cwd().openFile("puzzle_input/day23.txt", .{});
    defer file.close();

    var reader = file.reader();

    var connections = try readInput(arena, &reader);
    defer connections.deinit();

    var count_startswith_t: usize = 0;

    var it = CombinationsIterator(Name).init(arena, connections.keys(), 3);
    while (try it.next(arena)) |combination| {
        defer arena.free(combination);
        const a = combination[0];
        const b = combination[1];
        const c = combination[2];

        if (a.startsWithScalar('t') or b.startsWithScalar('t') or c.startsWithScalar('t')) {
            const ab = [_]Name{ a, b };
            const ac = [_]Name{ a, c };
            const bc = [_]Name{ b, c };

            if (connections.get(a).?.containsAllSlice(&bc) and connections.get(b).?.containsAllSlice(&ac) and connections.get(c).?.containsAllSlice(&ab)) {
                count_startswith_t += 1;
            }
        }
    }

    return @intCast(count_startswith_t);
}

pub fn allConnected(connections: std.AutoArrayHashMap(Name, set.ArraySetManaged(Name)), items: []Name) bool {
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

    var reader = file.reader();

    var arena_impl = std.heap.ArenaAllocator.init(allocator);
    defer arena_impl.deinit();

    const arena = arena_impl.allocator();

    var connections = try readInput(arena, &reader);
    defer connections.deinit();
    var best: []Name = &[_]Name{};

    for (connections.keys()) |k| {
        const v = connections.get(k).?;

        if (v.cardinality() <= best.len) {
            continue;
        }

        var it = PowersetIterator.init(arena, v.unmanaged.unmanaged.keys(), v.cardinality());
        while (try it.next(allocator)) |sub| {
            if (best.len >= sub.len + 1) break;

            if (allConnected(connections, sub)) {
                best = try arena.alloc(Name, sub.len + 1);
                best[0] = k;
                @memcpy(best[1..], sub);
                break;
            }
        }
    }

    std.mem.sort(Name, best, {}, Name.lessThan);

    var best_ = std.ArrayList(u8).init(allocator);
    errdefer best_.deinit();

    const writer = best_.writer();

    for (best) |n| {
        try writer.print("{c}{c},", .{ n.l, n.r });
    }

    _ = best_.swapRemove(best_.items.len - 1);

    return best_.toOwnedSlice();
}
