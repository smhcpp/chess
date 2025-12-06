const rl = @import("raylib");
const std = @import("std");
const C = @import("chess.zig").Chess;
const print = std.debug.print;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const game = try C.init(allocator);
    try game.run(allocator);
    game.deinit(allocator);
    const leak = gpa.deinit(); // Checks for leaks in debug
    print("\nLeaks:\n {}", .{leak});
}
