const C = @import("chess.zig");
const std = @import("std");
const rl = @import("raylib");
const print = std.debug.print;

pub fn checkKnightMoves(board: *[8][8]C.Piece, possible_moves: *[256]C.Move, max_possible_moves: *usize, turn: bool, i: f32, j: f32) void {
    const color = @intFromEnum(board[@intFromFloat(i)][@intFromFloat(j)]) < 7;
    if (color != turn) return;
    const moves = [_][2]f32{ .{ 2, 1 }, .{ 2, -1 }, .{ -2, 1 }, .{ -2, -1 }, .{ 1, 2 }, .{ 1, -2 }, .{ -1, 2 }, .{ -1, -2 } };
    for (moves) |move| {
        const newi = i + move[0];
        const newj = j + move[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) continue;
        const target_piece = board[@intFromFloat(newi)][@intFromFloat(newj)];
        const tempo = @intFromEnum(target_piece);
        const target_color = tempo < 7;
        if (target_color == turn and target_piece != .None) continue;
        possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = newi, .y = newj } };
        max_possible_moves.* += 1;
    }
}

pub fn checkBishopMoves(board: *[8][8]C.Piece, possible_moves: *[256]C.Move, max_possible_moves: *usize, turn: bool, i: f32, j: f32) void {
    const color = @intFromEnum(board[@intFromFloat(i)][@intFromFloat(j)]) < 7;
    if (color != turn) return;
    const steps: [4][2]f32 = .{ .{ 1, 1 }, .{ -1, 1 }, .{ -1, -1 }, .{ 1, -1 } };
    for (steps) |step| {
        var newi = i;
        var newj = j;
        while (true) {
            newi += step[0];
            newj += step[1];
            if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break;
            const target_piece = board[@intFromFloat(newi)][@intFromFloat(newj)];
            const tempo = @intFromEnum(target_piece);
            const target_color = tempo < 7;
            if (target_color == turn and target_piece != .None) break;
            possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = newi, .y = newj } };
            max_possible_moves.* += 1;
        }
    }
}

pub fn checkRookMoves(board: *[8][8]C.Piece, possible_moves: *[256]C.Move, max_possible_moves: *usize, turn: bool, i: f32, j: f32) void {
    const color = @intFromEnum(board[@intFromFloat(i)][@intFromFloat(j)]) < 7;
    if (color != turn) return;
    const steps: [4][2]f32 = .{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 } };
    for (steps) |step| {
        var newi = i;
        var newj = j;
        while (true) {
            newi += step[0];
            newj += step[1];
            if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break;
            const target_piece = board[@intFromFloat(newi)][@intFromFloat(newj)];
            const tempo = @intFromEnum(target_piece);
            const target_color = tempo < 7;
            if (target_color == turn and target_piece != .None) break;
            possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = newi, .y = newj } };
            max_possible_moves.* += 1;
        }
    }
}

pub fn checkQueenMoves(board: *[8][8]C.Piece, possible_moves: *[256]C.Move, max_possible_moves: *usize, turn: bool, i: f32, j: f32) void {
    const color = @intFromEnum(board[@intFromFloat(i)][@intFromFloat(j)]) < 7;
    if (color != turn) return;
    const steps: [8][2]f32 = .{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 }, .{ 1, 1 }, .{ -1, 1 }, .{ -1, -1 }, .{ 1, -1 } };
    for (steps) |step| {
        var newi = i;
        var newj = j;
        while (true) {
            newi += step[0];
            newj += step[1];
            if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break;
            const target_piece = board[@intFromFloat(newi)][@intFromFloat(newj)];
            const tempo = @intFromEnum(target_piece);
            const target_color = tempo < 7;
            if (target_color == turn and target_piece != .None) break;
            possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = newi, .y = newj } };
            max_possible_moves.* += 1;
        }
    }
}

pub fn checkPawnMoves(board: *[8][8]C.Piece, possible_moves: *[256]C.Move, max_possible_moves: *usize, turn: bool, i: f32, j: f32) void {
    const color = @intFromEnum(board[@intFromFloat(i)][@intFromFloat(j)]) < 7;
    if (color != turn) return;
    // const promotion = (turn and j==7) or (!turn and j==0);
    // const enpassant = (turn and j==6) or (!turn and j==1);
    const move1 = if (turn) [2]f32{ 0, -1 } else [2]f32{ 0, 1 };
    var one_move_flag = false;
    one_move: {
        const newj = j + move1[1];
        if (newj < 0 or newj >= 8) break :one_move;
        const target_piece = board[@intFromFloat(i)][@intFromFloat(newj)];
        if (target_piece != .None) break :one_move;
        possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = i, .y = newj } };
        max_possible_moves.* += 1;
        one_move_flag = true;
    }
    two_move: {
        if (!((turn and j == 6) or (!turn and j == 1)) or !one_move_flag) break :two_move;
        const newj = j + 2 * move1[1];
        if (newj < 0 or newj >= 8) break :two_move;
        const target_piece = board[@intFromFloat(i)][@intFromFloat(newj)];
        if (target_piece != .None) break :two_move;
        possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = i, .y = newj } };
        max_possible_moves.* += 1;
    }
    take_left: {
        const take_move_left = if (turn) [2]f32{ -1, -1 } else [2]f32{ -1, 1 };
        const newi = i + take_move_left[0];
        const newj = j + take_move_left[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break :take_left;
        const target_piece = board[@intFromFloat(newi)][@intFromFloat(newj)];
        if (target_piece == .None) break :take_left;
        const tempo = @intFromEnum(target_piece);
        const target_color = tempo < 7;
        if (target_color == turn) break :take_left;
        possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = newi, .y = newj } };
        max_possible_moves.* += 1;
    }
    take_right: {
        const take_move_right = if (turn) [2]f32{ 1, -1 } else [2]f32{ 1, 1 };
        const newi = i + take_move_right[0];
        const newj = j + take_move_right[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break :take_right;
        const target_piece = board[@intFromFloat(newi)][@intFromFloat(newj)];
        if (target_piece == .None) break :take_right;
        const tempo = @intFromEnum(target_piece);
        const target_color = tempo < 7;
        if (target_color == turn) break :take_right;
        possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = newi, .y = newj } };
        max_possible_moves.* += 1;
    }
    // print("Checking move: from {d}, {d} to {d}, {d}\n", .{i, j, newi, newj});
}

pub fn checkKingMoves(board: *[8][8]C.Piece, possible_moves: *[256]C.Move, max_possible_moves: *usize, turn: bool, i: f32, j: f32) void {
    const color = @intFromEnum(board[@intFromFloat(i)][@intFromFloat(j)]) < 7;
    if (color != turn) return;
    _ = possible_moves;
    _ = max_possible_moves;
}
