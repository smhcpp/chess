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

pub fn filterPossibleMoves(c: *Chess) void {
    var i = c.max_possible_moves - 1;
    while (true) {
        const move = c.possible_moves[i];
        const king_loc = if (c.turn) c.white_king_location else c.black_king_location;
        const safe = isMoveSafe(&c.board, move, king_loc);
        if (!safe) {
            c.possible_moves[i] = c.possible_moves[c.max_possible_moves - 1];
            c.max_possible_moves -= 1;
        }
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

pub fn rookOrBishop(i: usize, is_white: bool) Piece {
    if (i < 4) {
        if (is_white) {
            return .BRook;
        } else {
            return .WRook;
        }
    } else {
        if (is_white) {
            return .BBishop;
        } else {
            return .WBishop;
        }
    }
}

pub fn isMoveSafe(board: *const [8][8]Piece, move: Move, king_locaction: rl.Vector2) bool {
    var king_loc = king_locaction;
    const piece = board[@intFromFloat(move.from.x)][@intFromFloat(move.from.y)];
    const target_piece = board[@intFromFloat(move.to.x)][@intFromFloat(move.to.y)];
    const is_white = board[@intFromFloat(king_loc.x)][@intFromFloat(king_loc.y)] == .WKing;
    // moved rook due to castling
    // var moved_rook: ?Move = null;
    // removed pawn due to enpassant
    var removed_pawn: ?rl.Vector2 = null;
    if (move.from.x == king_loc.x and move.from.y == king_loc.y) {
        king_loc = move.to;
        // if (move.from.x - move.to.x == -2) moved_rook = .{ .from = .{ .x = 0, .y = king_loc.y }, .to = .{ .x = 3, .y = king_loc.y } };
        // if (move.from.x - move.to.x == 2) moved_rook = .{ .from = .{ .x = 7, .y = king_loc.y }, .to = .{ .x = 5, .y = king_loc.y } };
    }
    if ((is_white and piece == .WPawn) or (!is_white and piece == .BPawn)) {
        if (target_piece == .None and move.from.x != move.to.x) {
            const locy = if (is_white) move.to.y + 1 else move.to.y - 1;
            removed_pawn = .{ .x = move.to.x, .y = locy };
        }
    }
    // we have to imaging that piece is now in to.x,to.y and from.x, from.y is empty
    const knight_moves = [_][2]f32{ .{ 2, 1 }, .{ 2, -1 }, .{ -2, 1 }, .{ -2, -1 }, .{ 1, 2 }, .{ 1, -2 }, .{ -1, 2 }, .{ -1, -2 } };
    const sliding_steps: [8][2]f32 = .{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 }, .{ 1, 1 }, .{ -1, 1 }, .{ -1, -1 }, .{ 1, -1 } };
    const loc_y = if (is_white) king_loc.y + 1 else king_loc.y - 1;
    const pawn_attacks: [2][2]f32 = .{ .{ king_loc.x - 1, loc_y }, .{ king_loc.x + 1, loc_y } };
    // castling and enpassant to be considered
    {
        // Enemy Pawns
        for (pawn_attacks) |loc| {
            if (loc[0] < 0 or loc[0] > 7 or loc[1] < 0 or loc[1] > 7) continue;
            var considered_piece = board[@intFromFloat(loc[0])][@intFromFloat(loc[1])];
            if (loc[0] == move.from.x and loc[1] == move.from.y) continue;
            if (loc[0] == move.to.x and loc[1] == move.to.y) considered_piece = piece;
            if (removed_pawn) |pawn_loc| {
                if (loc[0] == pawn_loc.x and loc[1] == pawn_loc.y) continue;
            }
            if (is_white and considered_piece == .BPawn) return false;
            if (!is_white and considered_piece == .WPawn) return false;
        }
    }
    {
        // Enemy King
        for (sliding_steps) |step| {
            const locx = king_loc.x + step[0];
            const locy = king_loc.y + step[1];
            if (locx < 0 or locx > 7 or locy < 0 or locy > 7) continue;
            const considered_piece = board[@intFromFloat(locx)][@intFromFloat(locy)];
            if (is_white and considered_piece == .BKing) return false;
            if (!is_white and considered_piece == .WKing) return false;
        }
    }
    {
        // Enemy Knights
        for (knight_moves) |step| {
            const locx = king_loc.x + step[0];
            const locy = king_loc.y + step[1];
            if (locx < 0 or locx > 7 or locy < 0 or locy > 7) continue;
            var considered_piece = board[@intFromFloat(locx)][@intFromFloat(locy)];
            if (locx == move.from.x and locy == move.from.y) continue;
            if (locx == move.to.x and locy == move.to.y) considered_piece = piece;
            if (is_white and considered_piece == .BKnight) return false;
            if (!is_white and considered_piece == .WKnight) return false;
        }
    }
    {
        // Enemy Rooks, Bishops and Queen(s)
        for (sliding_steps, 0..) |step, i| {
            const enemy_piece = rookOrBishop(i, is_white);
            var locx = king_loc.x;
            var locy = king_loc.y;
            while (true) {
                locx += step[0];
                locy += step[1];
                if (locx < 0 or locx > 7 or locy < 0 or locy > 7) break;
                var considered_piece = board[@intFromFloat(locx)][@intFromFloat(locy)];
                if (removed_pawn) |pawn_loc| {
                    if (locx == pawn_loc.x and locy == pawn_loc.y) considered_piece = .None;
                }
                if (locx == move.from.x and locy == move.from.y) continue;
                if (locx == move.to.x and locy == move.to.y) considered_piece = piece;
                const value = @intFromEnum(considered_piece);
                if (is_white and value < 7 and value > 0) break;
                if (!is_white and value > 7) break;
                if (is_white and (considered_piece == enemy_piece or considered_piece == .BQueen)) return false;
                if (!is_white and (considered_piece == enemy_piece or considered_piece == .WQueen)) return false;
                if (considered_piece != .None) break;
            }
        }
    }
    return true;
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
