const std = @import("std");
const Allocator = std.mem.Allocator;

// Pretty Print Solution
pub fn ppSolutionOne(writer: anytype, allocator: Allocator) !void {
    _ = try solutionOne(allocator);
    try writer.print("\n", .{});
}

pub fn solutionOne(allocator: Allocator) !void {
    _ = allocator;
}

pub fn ppSolutionTwo(writer: anytype, allocator: Allocator) !void {
    _ = try solutionTwo(allocator);
    try writer.print("\n", .{});
}

pub fn solutionTwo(allocator: Allocator) !void {
    _ = allocator;
}
