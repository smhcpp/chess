const C = @import("chess.zig");
const std = @import("std");
const rl = @import("raylib");
const print = std.debug.print;

pub fn checkKnightMoves(board: *[8][8] C.Piece, possible_moves: *[256]C.Move, max_possible_moves: *usize, turn: bool, i: f32, j: f32) void {
    const color = @intFromEnum(board[@intFromFloat(i)][@intFromFloat(j)]) < 7;
    if (color != turn) return;
    const moves = [_][2]f32{ .{ 2, 1 }, .{ 2, -1 }, .{ -2, 1 }, .{ -2, -1 }, .{ 1, 2 }, .{ 1, -2 }, .{ -1, 2 }, .{ -1, -2 } };
    for (moves) |move| {
        const newi = i + move[0];
        const newj = j + move[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) continue;
        const piece = board[@intFromFloat(newi)][@intFromFloat(newj)];
        const tempo = @intFromEnum(piece);
        const piece_color = tempo > 0 and tempo < 7;
        if (piece_color == turn) continue;
        print("Checking move: from {d}, {d} to {d}, {d}\n", .{i, j, newi, newj});
        possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = newi, .y = newj } };
        max_possible_moves.* += 1;
    }
}


pub fn checkBishopMoves(board: *[8][8] C.Piece, possible_moves: *[256]C.Move, max_possible_moves: *usize, turn: bool, i: f32, j: f32) void {
    _=board;
    _=possible_moves;
    _=max_possible_moves;
    _=turn;
    _=i;
    _=j;
}

pub fn checkRookMoves(board: *[8][8] C.Piece, possible_moves: *[256]C.Move, max_possible_moves: *usize, turn: bool, i: f32, j: f32) void {
    _=board;
    _=possible_moves;
    _=max_possible_moves;
    _=turn;
    _=i;
    _=j;
}

pub fn checkQueenMoves(board: *[8][8] C.Piece, possible_moves: *[256]C.Move, max_possible_moves: *usize, turn: bool, i: f32, j: f32) void {
    _=board;
    _=possible_moves;
    _=max_possible_moves;
    _=turn;
    _=i;
    _=j;
}

pub fn checkPawnMoves(board: *[8][8] C.Piece, possible_moves: *[256]C.Move, max_possible_moves: *usize, turn: bool, i: f32, j: f32) void {
    _=board;
    _=possible_moves;
    _=max_possible_moves;
    _=turn;
    _=i;
    _=j;
}

pub fn checkKingMoves(board: *[8][8] C.Piece, possible_moves: *[256]C.Move, max_possible_moves: *usize, turn: bool, i: f32, j: f32) void {
    _=board;
    _=possible_moves;
    _=max_possible_moves;
    _=turn;
    _=i;
    _=j;
}
