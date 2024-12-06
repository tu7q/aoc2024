const std = @import("std");

const day1 = @import("day1.zig");
const day2 = @import("day2.zig");
const day3 = @import("day3.zig");
const day4 = @import("day4.zig");
const day5 = @import("day5.zig");
const day6 = @import("day6.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("day 1 solutions:\n", .{});
    try day1.ppSolutionOne(stdout, allocator);
    try day1.ppSolutionTwo(stdout, allocator);

    try stdout.print("day 2 solutions:\n", .{});
    try day2.ppSolutionOne(stdout, allocator);
    try day2.ppSolutionTwo(stdout, allocator);

    try stdout.print("day 3 solutions:\n", .{});
    try day3.ppSolutionOne(stdout, allocator);
    try day3.ppSolutionTwo(stdout, allocator);

    try stdout.print("day 4 solutions:\n", .{});
    try day4.ppSolutionOne(stdout, allocator);
    try day4.ppSolutionTwo(stdout, allocator);

    try stdout.print("day 5 solutions:\n", .{});
    try day5.ppSolutionOne(stdout, allocator);
    try day5.ppSolutionTwo(stdout, allocator);

    try stdout.print("day 6 solutions:\n", .{});
    try day6.ppSolutionOne(stdout, allocator);
    try day6.ppSolutionTwo(stdout, allocator);

    try bw.flush();
}
