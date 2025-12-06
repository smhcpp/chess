const C = @import("chess.zig");
const std = @import("std");
const rl = @import("raylib");
const print = std.debug.print;


pub fn addPossibleMove(c: *C.Chess, i: f32, j: f32, newi: f32, newj: f32) void {
    const prev = c.board[@intFromFloat(i)][@intFromFloat(j)];
    const next = c.board[@intFromFloat(newi)][@intFromFloat(newj)];
    c.setBoardPiece
    c.possible_moves[c.max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = newi, .y = newj } };
    c.max_possible_moves.* += 1;
}

pub fn updateKnightAttacks(
    board: *[8][8]C.Piece,
    black_attack_map: *[8][8]bool,
    white_attack_map: *[8][8]bool,
    i: f32,
    j: f32,
) void {
    const color = board[@intFromFloat(i)][@intFromFloat(j)] == .WKnight;
    const moves = [_][2]f32{ .{ 2, 1 }, .{ 2, -1 }, .{ -2, 1 }, .{ -2, -1 }, .{ 1, 2 }, .{ 1, -2 }, .{ -1, 2 }, .{ -1, -2 } };
    for (moves) |move| {
        const newi = i + move[0];
        const newj = j + move[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) continue;
        if (color) {
            white_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
        } else {
            black_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
        }
    }
}

pub fn checkKnightMoves(
    board: *[8][8]C.Piece,
    possible_moves: *[256]C.Move,
    max_possible_moves: *usize,
    turn: bool,
    i: f32,
    j: f32,
) void {
    const color = board[@intFromFloat(i)][@intFromFloat(j)] == .WKnight;
    if (color != turn) return;
    const moves = [_][2]f32{ .{ 2, 1 }, .{ 2, -1 }, .{ -2, 1 }, .{ -2, -1 }, .{ 1, 2 }, .{ 1, -2 }, .{ -1, 2 }, .{ -1, -2 } };
    for (moves) |move| {
        const newi = i + move[0];
        const newj = j + move[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) continue;
        const target_piece = board[@intFromFloat(newi)][@intFromFloat(newj)];
        const target_color = @intFromEnum(target_piece) < 7;
        if (target_color == color and target_piece != .None) continue;
        possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = newi, .y = newj } };
        max_possible_moves.* += 1;
    }
}

pub fn updateBishopAttacks(
    board: *[8][8]C.Piece,
    black_attack_map: *[8][8]bool,
    white_attack_map: *[8][8]bool,
    i: f32,
    j: f32,
) void {
    const color = board[@intFromFloat(i)][@intFromFloat(j)] == .WBishop;
    const steps: [4][2]f32 = .{ .{ 1, 1 }, .{ -1, 1 }, .{ -1, -1 }, .{ 1, -1 } };
    for (steps) |step| {
        var newi = i;
        var newj = j;
        while (true) {
            newi += step[0];
            newj += step[1];
            if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break;
            if (color) {
                white_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
            } else {
                black_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
            }
            const target_piece = board[@intFromFloat(newi)][@intFromFloat(newj)];
            if (target_piece != .None) break;
        }
    }
}

pub fn checkBishopMoves(
    board: *[8][8]C.Piece,
    possible_moves: *[256]C.Move,
    max_possible_moves: *usize,
    turn: bool,
    i: f32,
    j: f32,
) void {
    const color = board[@intFromFloat(i)][@intFromFloat(j)] == .WBishop;
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
            const target_color = @intFromEnum(target_piece) < 7;
            if (target_color == color and target_piece != .None) break;
            possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = newi, .y = newj } };
            max_possible_moves.* += 1;
            if (target_piece != .None) break;
        }
    }
}

pub fn updateRookAttacks(
    board: *[8][8]C.Piece,
    black_attack_map: *[8][8]bool,
    white_attack_map: *[8][8]bool,
    i: f32,
    j: f32,
) void {
    const color = board[@intFromFloat(i)][@intFromFloat(j)] == .WRook;
    const steps: [4][2]f32 = .{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 } };
    for (steps) |step| {
        var newi = i;
        var newj = j;
        while (true) {
            newi += step[0];
            newj += step[1];
            if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break;
            if (color) {
                white_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
            } else {
                black_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
            }
            const target_piece = board[@intFromFloat(newi)][@intFromFloat(newj)];
            if (target_piece != .None) break;
        }
    }
}
pub fn checkRookMoves(
    c: *Chess,
    i: f32,
    j: f32
) void {
    const color = c.board[@intFromFloat(i)][@intFromFloat(j)] == .WRook;
    if (color != c.turn) return;
    const steps: [4][2]f32 = .{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 } };
    for (steps) |step| {
        var newi = i;
        var newj = j;
        while (true) {
            newi += step[0];
            newj += step[1];
            if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break;
            const target_piece = c.board[@intFromFloat(newi)][@intFromFloat(newj)];
            const target_color = @intFromEnum(target_piece) < 7;
            if (target_color == color and target_piece != .None) break;
            addPossibleMove(c,i,j,newi,newj);
            if (target_piece != .None) break;
        }
    }
}

pub fn updateQueenAttacks(
    board: *[8][8]C.Piece,
    black_attack_map: *[8][8]bool,
    white_attack_map: *[8][8]bool,
    i: f32,
    j: f32,
) void {
    const color = board[@intFromFloat(i)][@intFromFloat(j)] == .WQueen;
    const steps: [8][2]f32 = .{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 }, .{ 1, 1 }, .{ -1, 1 }, .{ -1, -1 }, .{ 1, -1 } };
    for (steps) |step| {
        var newi = i;
        var newj = j;
        while (true) {
            newi += step[0];
            newj += step[1];
            if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break;
            if (color) {
                white_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
            } else {
                black_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
            }
            const target_piece = board[@intFromFloat(newi)][@intFromFloat(newj)];
            if (target_piece != .None) break;
        }
    }
}

pub fn checkQueenMoves(
    board: *[8][8]C.Piece,
    possible_moves: *[256]C.Move,
    max_possible_moves: *usize,
    turn: bool,
    i: f32,
    j: f32,
) void {
    const color = board[@intFromFloat(i)][@intFromFloat(j)] == .WQueen;
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
            const target_color = @intFromEnum(target_piece) < 7;
            if (target_color == color and target_piece != .None) break;
            possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = newi, .y = newj } };
            max_possible_moves.* += 1;
            if (target_piece != .None) break;
        }
    }
}
pub fn updatePawnAttacks(
    board: *[8][8]C.Piece,
    black_attack_map: *[8][8]bool,
    white_attack_map: *[8][8]bool,
    i: f32,
    j: f32,
) void {
    const color = board[@intFromFloat(i)][@intFromFloat(j)] == .WPawn;
    take_left: {
        const take_move_left = if (color) [2]f32{ -1, -1 } else [2]f32{ -1, 1 };
        const newi = i + take_move_left[0];
        const newj = j + take_move_left[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break :take_left;
        if (color) {
            white_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
        } else {
            black_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
        }
    }
    take_right: {
        const take_move_right = if (color) [2]f32{ 1, -1 } else [2]f32{ 1, 1 };
        const newi = i + take_move_right[0];
        const newj = j + take_move_right[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break :take_right;
        if (color) {
            white_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
        } else {
            black_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
        }
    }
}

pub fn checkPawnMoves(
    board: *[8][8]C.Piece,
    possible_moves: *[256]C.Move,
    max_possible_moves: *usize,
    turn: bool,
    i: f32,
    j: f32,
    enpassant_loc: ?rl.Vector2,
) void {
    const color = board[@intFromFloat(i)][@intFromFloat(j)] == .WPawn;
    if(color != turn) return;
    // const promotion = (turn and j==7) or (!turn and j==0);
    if (enpassant_loc) |loc| {
        const jj = if (color) j - 1 else j + 1;
        if ((loc.x == i + 1 or loc.x == i - 1) and loc.y == jj) {
            possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = loc.x, .y = jj } };
            max_possible_moves.* += 1;
        }
    }
    const move1 = if (color) [2]f32{ 0, -1 } else [2]f32{ 0, 1 };
    var one_move_flag = false;
    one_move: {
        if (color != turn) break :one_move;
        const newj = j + move1[1];
        if (newj < 0 or newj >= 8) break :one_move;
        const target_piece = board[@intFromFloat(i)][@intFromFloat(newj)];
        if (target_piece != .None) break :one_move;
        possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = i, .y = newj } };
        max_possible_moves.* += 1;
        one_move_flag = true;
    }
    two_move: {
        if (color != turn) break :two_move;
        if (!((color and j == 6) or (!color and j == 1)) or !one_move_flag) break :two_move;
        const newj = j + 2 * move1[1];
        if (newj < 0 or newj >= 8) break :two_move;
        const target_piece = board[@intFromFloat(i)][@intFromFloat(newj)];
        if (target_piece != .None) break :two_move;
        possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = i, .y = newj } };
        max_possible_moves.* += 1;
    }
    take_left: {
        const take_move_left = if (color) [2]f32{ -1, -1 } else [2]f32{ -1, 1 };
        const newi = i + take_move_left[0];
        const newj = j + take_move_left[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break :take_left;
        const target_piece = board[@intFromFloat(newi)][@intFromFloat(newj)];
        if (target_piece == .None) break :take_left;
        const target_color = @intFromEnum(target_piece)< 7;
        if (target_color == color) break :take_left;
        possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = newi, .y = newj } };
        max_possible_moves.* += 1;
    }
    take_right: {
        const take_move_right = if (color) [2]f32{ 1, -1 } else [2]f32{ 1, 1 };
        const newi = i + take_move_right[0];
        const newj = j + take_move_right[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break :take_right;
        const target_piece = board[@intFromFloat(newi)][@intFromFloat(newj)];
        if (target_piece == .None) break :take_right;
        const target_color = @intFromEnum(target_piece)< 7;
        if (target_color == color) break :take_right;
        possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = newi, .y = newj } };
        max_possible_moves.* += 1;
    }
}

pub fn checkKingMoves(
    board: *[8][8]C.Piece,
    black_attack_map: *[8][8]bool,
    white_attack_map: *[8][8]bool,
    possible_moves: *[256]C.Move,
    max_possible_moves: *usize,
    turn: bool,
    i: f32,
    j: f32,
    can_castle_short: bool,
    can_castle_long: bool,
) void {
    const color = board[@intFromFloat(i)][@intFromFloat(j)] == .WKing;
    if (color != turn) return;
    const steps: [8][2]f32 = .{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 }, .{ 1, 1 }, .{ -1, 1 }, .{ -1, -1 }, .{ 1, -1 } };
    for (steps) |step| {
        const newi = i + step[0];
        const newj = j + step[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) continue;
        const target_piece = board[@intFromFloat(newi)][@intFromFloat(newj)];
        const target_color = @intFromEnum(target_piece) < 7;
        if (target_color == turn and target_piece != .None) continue;
        if (color and black_attack_map[@intFromFloat(newi)][@intFromFloat(newj)]) continue;
        if (!color and white_attack_map[@intFromFloat(newi)][@intFromFloat(newj)]) continue;
        possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = newi, .y = newj } };
        max_possible_moves.* += 1;
    }
    if (can_castle_short) {
        const locx: f32 = 4;
        const locy: f32 = if (color) 7 else 0;
        const is_empty = board[@intFromFloat(locx + 1)][@intFromFloat(locy)] == .None and board[@intFromFloat(locx + 2)][@intFromFloat(locy)] == .None;
        const is_attacked = if (color)
            black_attack_map[@intFromFloat(locx)][@intFromFloat(locy)] or black_attack_map[@intFromFloat(locx + 1)][@intFromFloat(locy)] or black_attack_map[@intFromFloat(locx + 2)][@intFromFloat(locy)]
        else
            white_attack_map[@intFromFloat(locx)][@intFromFloat(locy)] or white_attack_map[@intFromFloat(locx + 1)][@intFromFloat(locy)] or white_attack_map[@intFromFloat(locx + 2)][@intFromFloat(locy)];
        if (is_empty and !is_attacked) {
            possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = locx + 2, .y = locy } };
            max_possible_moves.* += 1;
        }
    }
    if (can_castle_long) {
        const locx: f32 = 4;
        const locy: f32 = if (color) 7 else 0;
        const is_empty = board[@intFromFloat(locx - 1)][@intFromFloat(locy)] == .None and board[@intFromFloat(locx - 2)][@intFromFloat(locy)] == .None;
        const is_attacked = if (color)
            black_attack_map[@intFromFloat(locx)][@intFromFloat(locy)] or black_attack_map[@intFromFloat(locx - 1)][@intFromFloat(locy)] or black_attack_map[@intFromFloat(locx - 2)][@intFromFloat(locy)]
        else
            white_attack_map[@intFromFloat(locx)][@intFromFloat(locy)] or white_attack_map[@intFromFloat(locx - 1)][@intFromFloat(locy)] or white_attack_map[@intFromFloat(locx - 2)][@intFromFloat(locy)];

        if (is_empty and !is_attacked) {
            possible_moves[max_possible_moves.*] = C.Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = locx - 2, .y = locy } };
            max_possible_moves.* += 1;
        }
    }
}

pub fn updateKingAttacks(
    board: *[8][8]C.Piece,
    black_attack_map: *[8][8]bool,
    white_attack_map: *[8][8]bool,
    i: f32,
    j: f32,
) void {
    const color = @intFromEnum(board[@intFromFloat(i)][@intFromFloat(j)]) < 7;
    const steps: [8][2]f32 = .{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 }, .{ 1, 1 }, .{ -1, 1 }, .{ -1, -1 }, .{ 1, -1 } };
    for (steps) |step| {
        const newi = i + step[0];
        const newj = j + step[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) continue;
        if (color) {
            white_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
        } else {
            black_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
        }
    }
}
