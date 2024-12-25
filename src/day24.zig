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

// Assumes the input takes the form of a ripple adder.
// All z-outputs must be the result of an XOR instruction except for the final z-output
// which is the result of and OR instruction.
// Each x,y-input must be XOR'ed together first.
// x(n) XOR y(n) -> a
// a XOR carry(n-1) -> z(n)
// carry(n-1) AND a -> b
// x(n) AND y(n) -> c
// b AND c -> carry(n-1)
// In total -> check carry chain and check adders.
pub fn solutionTwo(allocator: Allocator) !void {
    _ = allocator;
}
