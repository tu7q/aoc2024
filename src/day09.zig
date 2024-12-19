const std = @import("std");
const Allocator = std.mem.Allocator;

const Chunk = struct {
    len: usize,
    file_id: ?u32,
};

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    const result = try solutionOne(allocator);
    try writer.print("filesystem checksum: {d}\n", .{result});
}

// Terrible solutions omg.
pub fn solutionOne(allocator: Allocator) !u64 {
    const file = try std.fs.cwd().openFile("puzzle_input/day9.txt", .{});
    defer file.close();

    var reader = file.reader();

    var chunks = std.ArrayList(Chunk).init(allocator);
    defer chunks.deinit();

    var isFile = true;
    var id: u32 = 0;

    while (true) : ({
        if (isFile) id += 1;
        isFile = !isFile;
    }) {
        const c = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => |e| return e,
        };

        const len = try std.fmt.charToDigit(c, 10);
        const file_id = if (isFile) id else null;

        try chunks.append(.{ .file_id = file_id, .len = len });
    }

    while (true) {
        const chunk = chunks.pop();
        if (chunk.file_id == null) continue;
        var empty_idx: usize = undefined;
        var empty = blk: for (chunks.items, 0..) |*c, i| {
            if (c.file_id == null) {
                empty_idx = i;
                break :blk c;
            }
        } else {
            try chunks.append(chunk); // undo removal
            break;
        };

        if (empty.len == 0) {
            try chunks.append(chunk); // undo.
            _ = chunks.orderedRemove(empty_idx);
            continue;
        }

        empty.file_id = chunk.file_id;
        if (chunk.len > empty.len) {
            try chunks.append(.{
                .file_id = chunk.file_id,
                .len = chunk.len - empty.len,
            });
        } else if (chunk.len < empty.len) {
            try chunks.insert(
                empty_idx + 1,
                .{
                    .file_id = null,
                    .len = empty.len - chunk.len,
                },
            );
            empty.len = chunk.len; // empty ptr shouldn't have been invalidated.
        }
    }

    var checksum: u64 = 0;
    var i: usize = 0;
    for (chunks.items) |chunk| {
        const A = i;
        const B = i + chunk.len - 1;

        const @"sum(A->B)" = ((B - A + 1) * (A + B)) / 2;
        checksum += @intCast(@"sum(A->B)" * chunk.file_id.?);
        i += chunk.len;
    }
    return checksum;
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    const result = try solutionTwo(allocator);
    try writer.print("filesystem checksum (moving whole files.): {d}\n", .{result});
}

pub fn solutionTwo(allocator: Allocator) !u64 {
    const file = try std.fs.cwd().openFile("puzzle_input/day9.txt", .{});
    defer file.close();

    var reader = file.reader();

    var chunks = std.ArrayList(Chunk).init(allocator);
    defer chunks.deinit();

    var isFile = true;
    var id: u32 = 0;

    while (true) : ({
        if (isFile) id += 1;
        isFile = !isFile;
    }) {
        const c = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => |e| return e,
        };

        const len = try std.fmt.charToDigit(c, 10);
        const file_id = if (isFile) id else null;

        try chunks.append(.{ .file_id = file_id, .len = len });
    }

    var it = std.mem.reverseIterator(chunks.items);
    while (it.nextPtr()) |c| {
        if (c.file_id == null) continue;

        for (chunks.items[0..it.index], 0..) |*empty, i| {
            if (empty.file_id == null and empty.len >= c.len) {
                empty.file_id = c.file_id;
                c.file_id = null;

                if (empty.len > c.len) {
                    const used = c.len;
                    const unused = empty.len - used;

                    empty.len = used;
                    try chunks.insert(i + 1, .{
                        .file_id = null,
                        .len = unused,
                    });
                }

                break;
            }
        }
    }

    var checksum: u64 = 0;
    var i: usize = 0;
    for (chunks.items) |chunk| {
        defer i += chunk.len;
        if (chunk.file_id == null) continue;

        const A = i;
        const B = i + chunk.len - 1;

        const @"sum(A->B)" = ((B - A + 1) * (A + B)) / 2;
        checksum += @intCast(@"sum(A->B)" * chunk.file_id.?);
    }
    return checksum;
}
