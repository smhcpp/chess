const Chess = @import("chess.zig").Chess;
const Move = @import("chess.zig").Move;
const Piece = @import("chess.zig").Piece;
const std = @import("std");
const rl = @import("raylib");
const print = std.debug.print;

pub fn addPossibleMove(c: *Chess, i: f32, j: f32, newi: f32, newj: f32) void {
    c.possible_moves[c.max_possible_moves] = Move{ .from = rl.Vector2{ .x = i, .y = j }, .to = rl.Vector2{ .x = newi, .y = newj } };
    c.max_possible_moves += 1;
}

pub fn fakeMove(c: *Chess, move: Move) void {
    const piece = c.board[@intFromFloat(move.from.x)][@intFromFloat(move.from.y)];
    const target_piece = c.board[@intFromFloat(move.to.x)][@intFromFloat(move.to.y)];
    c.board[@intFromFloat(move.from.x)][@intFromFloat(move.from.y)] = .None;
    c.board[@intFromFloat(move.to.x)][@intFromFloat(move.to.y)] = piece;
    if (piece == .WKing) {
        if (move.from.x - move.to.x == 2) {
            const rook = c.board[0][7];
            c.board[0][7] = .None;
            c.board[3][7] = rook;
        } else if (move.from.x - move.to.x == -2) {
            const rook = c.board[7][7];
            c.board[7][7] = .None;
            c.board[5][7] = rook;
        }
    }
    if (piece == .BKing) {
        if (move.from.x - move.to.x == 2) {
            const rook = c.board[0][0];
            c.board[0][0] = .None;
            c.board[3][0] = rook;
        } else if (move.from.x - move.to.x == -2) {
            const rook = c.board[7][0];
            c.board[7][0] = .None;
            c.board[5][0] = rook;
        }
    }
    if (piece == .BPawn and target_piece == .None and move.from.x != move.to.x) {
        c.board[@intFromFloat(move.to.x)][@intFromFloat(move.to.y + 1)] = .None;
    }
    if (piece == .WPawn and target_piece == .None and move.from.x != move.to.x) {
        c.board[@intFromFloat(move.to.x)][@intFromFloat(move.to.y - 1)] = .None;
    }
}

pub fn revertFakeMove(c: *Chess, move: Move, target_piece: Piece) void {
    const piece = c.board[@intFromFloat(move.to.x)][@intFromFloat(move.to.y)];
    const prev_target_piece = c.board[@intFromFloat(move.to.x)][@intFromFloat(move.to.y)];
    c.board[@intFromFloat(move.from.x)][@intFromFloat(move.from.y)] = piece;
    c.board[@intFromFloat(move.to.x)][@intFromFloat(move.to.y)] = target_piece;
    if (piece == .WKing) {
        if (move.from.x - move.to.x == 2) {
            const rook = c.board[3][7];
            c.board[3][7] = .None;
            c.board[0][7] = rook;
        } else if (move.from.x - move.to.x == -2) {
            const rook = c.board[5][7];
            c.board[5][7] = .None;
            c.board[7][7] = rook;
        }
    }
    if (piece == .BKing) {
        if (move.from.x - move.to.x == 2) {
            const rook = c.board[3][0];
            c.board[3][0] = .None;
            c.board[0][0] = rook;
        } else if (move.from.x - move.to.x == -2) {
            const rook = c.board[5][0];
            c.board[5][0] = .None;
            c.board[7][0] = rook;
        }
    }
    if (piece == .BPawn and prev_target_piece == .None and move.from.x != move.to.x) {
        c.board[@intFromFloat(move.to.x)][@intFromFloat(move.to.y + 1)] = .WPawn;
    }
    if (piece == .WPawn and prev_target_piece == .None and move.from.x != move.to.x) {
        c.board[@intFromFloat(move.to.x)][@intFromFloat(move.to.y - 1)] = .BPawn;
    }
}

pub fn filterPossibleMoves(c: *Chess) void {
    var i = c.max_possible_moves - 1;
    while (true) {
        const move = c.possible_moves[i];
        var wking_loc = c.white_king_location;
        var bking_loc = c.black_king_location;
        const piece = c.board[@intFromFloat(move.from.x)][@intFromFloat(move.from.y)];
        const target_piece = c.board[@intFromFloat(move.to.x)][@intFromFloat(move.to.y)];
        if (piece == .WKing) wking_loc = move.to;
        if (piece == .BKing) bking_loc = move.to;
        fakeMove(c, move);
        updateAttackMaps(c);
        const color = @intFromEnum(piece) < 7;
        const cond1 = color and c.black_attack_map[@intFromFloat(wking_loc.x)][@intFromFloat(wking_loc.y)];
        const cond2 = !color and c.white_attack_map[@intFromFloat(bking_loc.x)][@intFromFloat(bking_loc.y)];
        if (cond1 or cond2) {
            c.possible_moves[i] = c.possible_moves[c.max_possible_moves - 1];
            c.max_possible_moves -= 1;
        }
        revertFakeMove(c, move, target_piece);
        if (i > 0) {
            i -= 1;
        } else break;
    }
}

pub fn updatePossibleMoves(c: *Chess) void {
    c.max_possible_moves = 0;
    for (0..8) |i| {
        for (0..8) |j| {
            switch (c.board[i][j]) {
                .None => {
                    continue;
                },
                .WPawn, .BPawn => {
                    checkPawnMoves(c, @floatFromInt(i), @floatFromInt(j));
                },
                .WRook, .BRook => {
                    checkRookMoves(c, @floatFromInt(i), @floatFromInt(j));
                },
                .WBishop, .BBishop => {
                    checkBishopMoves(c, @floatFromInt(i), @floatFromInt(j));
                },
                .WKnight, .BKnight => {
                    checkKnightMoves(c, @floatFromInt(i), @floatFromInt(j));
                },
                .WQueen, .BQueen => {
                    checkQueenMoves(c, @floatFromInt(i), @floatFromInt(j));
                },
                .WKing => {
                    checkKingMoves(c, @floatFromInt(i), @floatFromInt(j));
                },
                .BKing => {
                    checkKingMoves(c, @floatFromInt(i), @floatFromInt(j));
                },
            }
        }
    }
}

pub fn updateAttackMaps(c: *Chess) void {
    for (0..8) |i| {
        for (0..8) |j| {
            c.black_attack_map[i][j] = false;
            c.white_attack_map[i][j] = false;
        }
    }
    for (0..8) |i| {
        for (0..8) |j| {
            switch (c.board[i][j]) {
                .None => {
                    continue;
                },
                .WPawn, .BPawn => {
                    updatePawnAttacks(c, @floatFromInt(i), @floatFromInt(j));
                },
                .WRook, .BRook => {
                    updateRookAttacks(c, @floatFromInt(i), @floatFromInt(j));
                },
                .WBishop, .BBishop => {
                    updateBishopAttacks(c, @floatFromInt(i), @floatFromInt(j));
                },
                .WKnight, .BKnight => {
                    updateKnightAttacks(c, @floatFromInt(i), @floatFromInt(j));
                },
                .WQueen, .BQueen => {
                    updateKingAttacks(c, @floatFromInt(i), @floatFromInt(j));
                },
                .WKing, .BKing => {
                    updateKingAttacks(c, @floatFromInt(i), @floatFromInt(j));
                },
            }
        }
    }
}

pub fn updateKnightAttacks(
    c: *Chess,
    i: f32,
    j: f32,
) void {
    const color = c.board[@intFromFloat(i)][@intFromFloat(j)] == .WKnight;
    const moves = [_][2]f32{ .{ 2, 1 }, .{ 2, -1 }, .{ -2, 1 }, .{ -2, -1 }, .{ 1, 2 }, .{ 1, -2 }, .{ -1, 2 }, .{ -1, -2 } };
    for (moves) |move| {
        const newi = i + move[0];
        const newj = j + move[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) continue;
        if (color) {
            c.white_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
        } else {
            c.black_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
        }
    }
}

pub fn checkKnightMoves(
    c: *Chess,
    i: f32,
    j: f32,
) void {
    const color = c.board[@intFromFloat(i)][@intFromFloat(j)] == .WKnight;
    if (color != c.turn) return;
    const moves = [_][2]f32{ .{ 2, 1 }, .{ 2, -1 }, .{ -2, 1 }, .{ -2, -1 }, .{ 1, 2 }, .{ 1, -2 }, .{ -1, 2 }, .{ -1, -2 } };
    for (moves) |move| {
        const newi = i + move[0];
        const newj = j + move[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) continue;
        const target_piece = c.board[@intFromFloat(newi)][@intFromFloat(newj)];
        const target_color = @intFromEnum(target_piece) < 7;
        if (target_color == color and target_piece != .None) continue;
        addPossibleMove(c, i, j, newi, newj);
    }
}

pub fn updateBishopAttacks(
    c: *Chess,
    i: f32,
    j: f32,
) void {
    const color = c.board[@intFromFloat(i)][@intFromFloat(j)] == .WBishop;
    const steps: [4][2]f32 = .{ .{ 1, 1 }, .{ -1, 1 }, .{ -1, -1 }, .{ 1, -1 } };
    for (steps) |step| {
        var newi = i;
        var newj = j;
        while (true) {
            newi += step[0];
            newj += step[1];
            if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break;
            if (color) {
                c.white_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
            } else {
                c.black_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
            }
            const target_piece = c.board[@intFromFloat(newi)][@intFromFloat(newj)];
            if (target_piece != .None) break;
        }
    }
}

pub fn checkBishopMoves(
    c: *Chess,
    i: f32,
    j: f32,
) void {
    const color = c.board[@intFromFloat(i)][@intFromFloat(j)] == .WBishop;
    if (color != c.turn) return;
    const steps: [4][2]f32 = .{ .{ 1, 1 }, .{ -1, 1 }, .{ -1, -1 }, .{ 1, -1 } };
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
            addPossibleMove(c, i, j, newi, newj);
            if (target_piece != .None) break;
        }
    }
}

pub fn updateRookAttacks(
    c: *Chess,
    i: f32,
    j: f32,
) void {
    const color = c.board[@intFromFloat(i)][@intFromFloat(j)] == .WRook;
    const steps: [4][2]f32 = .{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 } };
    for (steps) |step| {
        var newi = i;
        var newj = j;
        while (true) {
            newi += step[0];
            newj += step[1];
            if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break;
            if (color) {
                c.white_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
            } else {
                c.black_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
            }
            const target_piece = c.board[@intFromFloat(newi)][@intFromFloat(newj)];
            if (target_piece != .None) break;
        }
    }
}
pub fn checkRookMoves(c: *Chess, i: f32, j: f32) void {
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
            addPossibleMove(c, i, j, newi, newj);
            if (target_piece != .None) break;
        }
    }
}

pub fn updateQueenAttacks(
    c: *Chess,
    i: f32,
    j: f32,
) void {
    const color = c.board[@intFromFloat(i)][@intFromFloat(j)] == .WQueen;
    const steps: [8][2]f32 = .{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 }, .{ 1, 1 }, .{ -1, 1 }, .{ -1, -1 }, .{ 1, -1 } };
    for (steps) |step| {
        var newi = i;
        var newj = j;
        while (true) {
            newi += step[0];
            newj += step[1];
            if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break;
            if (color) {
                c.white_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
            } else {
                c.black_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
            }
            const target_piece = c.board[@intFromFloat(newi)][@intFromFloat(newj)];
            if (target_piece != .None) break;
        }
    }
}

pub fn checkQueenMoves(
    c: *Chess,
    i: f32,
    j: f32,
) void {
    const color = c.board[@intFromFloat(i)][@intFromFloat(j)] == .WQueen;
    if (color != c.turn) return;
    const steps: [8][2]f32 = .{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 }, .{ 1, 1 }, .{ -1, 1 }, .{ -1, -1 }, .{ 1, -1 } };
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
            addPossibleMove(c, i, j, newi, newj);
            if (target_piece != .None) break;
        }
    }
}
pub fn updatePawnAttacks(
    c: *Chess,
    i: f32,
    j: f32,
) void {
    const color = c.board[@intFromFloat(i)][@intFromFloat(j)] == .WPawn;
    take_left: {
        const take_move_left = if (color) [2]f32{ -1, -1 } else [2]f32{ -1, 1 };
        const newi = i + take_move_left[0];
        const newj = j + take_move_left[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break :take_left;
        if (color) {
            c.white_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
        } else {
            c.black_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
        }
    }
    take_right: {
        const take_move_right = if (color) [2]f32{ 1, -1 } else [2]f32{ 1, 1 };
        const newi = i + take_move_right[0];
        const newj = j + take_move_right[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break :take_right;
        if (color) {
            c.white_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
        } else {
            c.black_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
        }
    }
}

pub fn checkPawnMoves(
    c: *Chess,
    i: f32,
    j: f32,
) void {
    const color = c.board[@intFromFloat(i)][@intFromFloat(j)] == .WPawn;
    if (color != c.turn) return;
    // const promotion = (turn and j==7) or (!turn and j==0);
    if (c.enpassant_location) |loc| {
        const jj = if (color) j - 1 else j + 1;
        if ((loc.x == i + 1 or loc.x == i - 1) and loc.y == jj) {
            addPossibleMove(c, i, j, loc.x, jj);
        }
    }
    const move1 = if (color) [2]f32{ 0, -1 } else [2]f32{ 0, 1 };
    var one_move_flag = false;
    one_move: {
        if (color != c.turn) break :one_move;
        const newj = j + move1[1];
        if (newj < 0 or newj >= 8) break :one_move;
        const target_piece = c.board[@intFromFloat(i)][@intFromFloat(newj)];
        if (target_piece != .None) break :one_move;
        addPossibleMove(c, i, j, i, newj);
        one_move_flag = true;
    }
    two_move: {
        if (color != c.turn) break :two_move;
        if (!((color and j == 6) or (!color and j == 1)) or !one_move_flag) break :two_move;
        const newj = j + 2 * move1[1];
        if (newj < 0 or newj >= 8) break :two_move;
        const target_piece = c.board[@intFromFloat(i)][@intFromFloat(newj)];
        if (target_piece != .None) break :two_move;
        addPossibleMove(c, i, j, i, newj);
    }
    take_left: {
        const take_move_left = if (color) [2]f32{ -1, -1 } else [2]f32{ -1, 1 };
        const newi = i + take_move_left[0];
        const newj = j + take_move_left[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break :take_left;
        const target_piece = c.board[@intFromFloat(newi)][@intFromFloat(newj)];
        if (target_piece == .None) break :take_left;
        const target_color = @intFromEnum(target_piece) < 7;
        if (target_color == color) break :take_left;
        addPossibleMove(c, i, j, newi, newj);
    }
    take_right: {
        const take_move_right = if (color) [2]f32{ 1, -1 } else [2]f32{ 1, 1 };
        const newi = i + take_move_right[0];
        const newj = j + take_move_right[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) break :take_right;
        const target_piece = c.board[@intFromFloat(newi)][@intFromFloat(newj)];
        if (target_piece == .None) break :take_right;
        const target_color = @intFromEnum(target_piece) < 7;
        if (target_color == color) break :take_right;
        addPossibleMove(c, i, j, newi, newj);
    }
}

pub fn checkKingMoves(
    c: *Chess,
    i: f32,
    j: f32,
) void {
    const color = c.board[@intFromFloat(i)][@intFromFloat(j)] == .WKing;
    if (color != c.turn) return;
    const steps: [8][2]f32 = .{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 }, .{ 1, 1 }, .{ -1, 1 }, .{ -1, -1 }, .{ 1, -1 } };
    for (steps) |step| {
        const newi = i + step[0];
        const newj = j + step[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) continue;
        const target_piece = c.board[@intFromFloat(newi)][@intFromFloat(newj)];
        const target_color = @intFromEnum(target_piece) < 7;
        if (target_color == c.turn and target_piece != .None) continue;
        if (color and c.black_attack_map[@intFromFloat(newi)][@intFromFloat(newj)]) continue;
        if (!color and c.white_attack_map[@intFromFloat(newi)][@intFromFloat(newj)]) continue;
        addPossibleMove(c, i, j, newi, newj);
    }
    const can_castle_short = if (color) c.can_castle_short_white else c.can_castle_short_black;
    const can_castle_long = if (color) c.can_castle_long_white else c.can_castle_long_black;
    if (can_castle_short) {
        const locx: f32 = 4;
        const locy: f32 = if (color) 7 else 0;
        const is_empty = c.board[@intFromFloat(locx + 1)][@intFromFloat(locy)] == .None and c.board[@intFromFloat(locx + 2)][@intFromFloat(locy)] == .None;
        const is_attacked = if (color)
            c.black_attack_map[@intFromFloat(locx)][@intFromFloat(locy)] or c.black_attack_map[@intFromFloat(locx + 1)][@intFromFloat(locy)] or c.black_attack_map[@intFromFloat(locx + 2)][@intFromFloat(locy)]
        else
            c.white_attack_map[@intFromFloat(locx)][@intFromFloat(locy)] or c.white_attack_map[@intFromFloat(locx + 1)][@intFromFloat(locy)] or c.white_attack_map[@intFromFloat(locx + 2)][@intFromFloat(locy)];
        if (is_empty and !is_attacked) {
            addPossibleMove(c, i, j, locx + 2, locy);
        }
    }
    if (can_castle_long) {
        const locx: f32 = 4;
        const locy: f32 = if (color) 7 else 0;
        const is_empty = c.board[@intFromFloat(locx - 1)][@intFromFloat(locy)] == .None and c.board[@intFromFloat(locx - 2)][@intFromFloat(locy)] == .None;
        const is_attacked = if (color)
            c.black_attack_map[@intFromFloat(locx)][@intFromFloat(locy)] or c.black_attack_map[@intFromFloat(locx - 1)][@intFromFloat(locy)] or c.black_attack_map[@intFromFloat(locx - 2)][@intFromFloat(locy)]
        else
            c.white_attack_map[@intFromFloat(locx)][@intFromFloat(locy)] or c.white_attack_map[@intFromFloat(locx - 1)][@intFromFloat(locy)] or c.white_attack_map[@intFromFloat(locx - 2)][@intFromFloat(locy)];

        if (is_empty and !is_attacked) {
            addPossibleMove(c, i, j, locx - 2, locy);
        }
    }
}

pub fn updateKingAttacks(
    c: *Chess,
    i: f32,
    j: f32,
) void {
    const color = @intFromEnum(c.board[@intFromFloat(i)][@intFromFloat(j)]) < 7;
    const steps: [8][2]f32 = .{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 }, .{ 1, 1 }, .{ -1, 1 }, .{ -1, -1 }, .{ 1, -1 } };
    for (steps) |step| {
        const newi = i + step[0];
        const newj = j + step[1];
        if (newi < 0 or newi >= 8 or newj < 0 or newj >= 8) continue;
        if (color) {
            c.white_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
        } else {
            c.black_attack_map[@intFromFloat(newi)][@intFromFloat(newj)] = true;
        }
    }
}
