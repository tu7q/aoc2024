const std = @import("std");

const day1 = @import("day1.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Day 1 solutions
    try day1.ppSolutionOne(allocator);
    try day1.ppSolutionTwo(allocator);
}
