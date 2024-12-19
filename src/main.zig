const std = @import("std");

const day1 = @import("day01.zig");
const day2 = @import("day02.zig");
const day3 = @import("day03.zig");
const day4 = @import("day04.zig");
const day5 = @import("day05.zig");
const day6 = @import("day06.zig");
const day7 = @import("day07.zig");
const day8 = @import("day08.zig");
const day9 = @import("day09.zig");
const day10 = @import("day10.zig");
const day11 = @import("day11.zig");
const day12 = @import("day12.zig");
const day13 = @import("day13.zig");
const day14 = @import("day14.zig");
const day15 = @import("day15.zig");
const day16 = @import("day16.zig");
const day17 = @import("day17.zig");
const day18 = @import("day18.zig");
const day19 = @import("day19.zig");

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

    try stdout.print("day 7 solutions:\n", .{});
    try day7.ppSolutionOne(stdout, allocator);
    try day7.ppSolutionTwo(stdout, allocator);

    try stdout.print("day 8 solutions:\n", .{});
    try day8.ppSolutionOne(stdout, allocator);
    try day8.ppSolutionTwo(stdout, allocator);

    try stdout.print("day 9 solutions:\n", .{});
    try day9.ppSolutionOne(stdout, allocator);
    try day9.ppSolutionTwo(stdout, allocator);

    try stdout.print("day 10 solutions:\n", .{});
    try day10.ppSolutionOne(stdout, allocator);
    try day10.ppSolutionTwo(stdout, allocator);

    try stdout.print("day 11 solutions:\n", .{});
    try day11.ppSolutionOne(stdout, allocator);
    try day11.ppSolutionTwo(stdout, allocator);

    try stdout.print("day 12 solutions:\n", .{});
    try day12.ppSolutionOne(stdout, allocator);
    try day12.ppSolutionTwo(stdout, allocator);

    try stdout.print("day 13 solutions:\n", .{});
    try day13.ppSolutionOne(stdout, allocator);
    try day13.ppSolutionTwo(stdout, allocator);

    try stdout.print("day 14 solutions:\n", .{});
    try day14.ppSolutionOne(stdout, allocator);
    try day14.ppSolutionTwo(stdout, allocator);

    try stdout.print("day 15 solutions:\n", .{});
    try day15.ppSolutionOne(stdout, allocator);
    try day15.ppSolutionTwo(stdout, allocator);

    try stdout.print("day 16 solutions:\n", .{});
    try day16.ppSolutionOne(stdout, allocator);
    try day16.ppSolutionTwo(stdout, allocator);

    try stdout.print("day 17 solutions:\n", .{});
    try day17.ppSolutionOne(stdout, allocator);
    try day17.ppSolutionTwo(stdout, allocator);

    try stdout.print("day 18 solutions:\n", .{});
    try day18.ppSolutionOne(stdout, allocator);
    try day18.ppSolutionTwo(stdout, allocator);

    try stdout.print("day 19 solutions:\n", .{});
    try day19.ppSolutionOne(stdout, allocator);
    try day19.ppSolutionTwo(stdout, allocator);

    try bw.flush();
}
