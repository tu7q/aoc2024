const std = @import("std");

const day1 = @import("day1.zig");
const day2 = @import("day2.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    std.debug.print("day 1 solutions:\n", .{});
    try day1.ppSolutionOne(allocator);
    try day1.ppSolutionTwo(allocator);

    std.debug.print("day 2 solutions:\n", .{});
    try day2.ppSolutionOne(allocator);
    try day2.ppSolutionTwo(allocator);
}
