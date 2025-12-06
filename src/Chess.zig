const rl = @import("raylib");
const std = @import("std");
const print = std.debug.print;
const H = @import("helper.zig");

pub const Piece = enum(u8) {
    None,
    WPawn,
    WKnight,
    WBishop,
    WRook,
    WQueen,
    WKing,
    BPawn,
    BKnight,
    BBishop,
    BRook,
    BQueen,
    BKing,
};

pub const Move = struct {
    from: rl.Vector2,
    to: rl.Vector2,
};

pub const GameResult = enum {
    D, // draw
    W, // white win
    B, // black win
    N, // none
};

pub const Event = struct {
    i: f32,
    j: f32,
    prev_piece: Piece,
    next_piece: Piece,
};

pub const Chess = struct {
    pub const PieceSize: f32 = 60;

    result: GameResult = .N,
    selected_piece: ?rl.Vector2 = null,
    board: [8][8]Piece = undefined,
    black_attack_map: [8][8]bool = undefined,
    white_attack_map: [8][8]bool = undefined,
    texture: rl.Texture2D = undefined,
    board_position: rl.Vector2 = .{ .x = 0, .y = 0 },
    enpassant_location: ?rl.Vector2 = null,
    can_castle_short_white: bool = true,
    can_castle_long_white: bool = true,
    can_castle_short_black: bool = true,
    can_castle_long_black: bool = true,
    // is_white_in_check: bool = false,
    // is_black_in_check: bool = false,
    black_king_location: rl.Vector2 = .{ .x = 4, .y = 0 },
    white_king_location: rl.Vector2 = .{ .x = 4, .y = 7 },
    //turn : white move, !turn : black move
    turn: bool = true,
    possible_moves: [256]Move = undefined,
    max_possible_moves: usize = 0,
    // square_size: f32 = 60,
    history: std.ArrayList(Event) = undefined,
    history_counter: usize = 0,


    pub fn init(allocator: std.mem.Allocator) !*Chess {
        const c = try allocator.create(Chess);
        c.* = .{
            .history = try std.ArrayList(Event).initCapacity(allocator, 200),
        };
        try c.setup();
        return c;
    }

    fn setup(c: *Chess) !void {
        setupBoard(c);
        c.updatePossibleMoves();
        rl.setTraceLogLevel(.err);
        const screenWidth = PieceSize * 8;
        const screenHeight = PieceSize * 8;
        rl.initWindow(screenWidth, screenHeight, "Chess");
        rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
        c.texture = try rl.loadTexture("assets/pieces.png");
    }

    pub fn deinit(c: *Chess, allocator: std.mem.Allocator) void {
        rl.unloadTexture(c.texture);
        c.history.deinit(allocator);
        allocator.destroy(c);
    }

    pub fn run(c: *Chess, allocator: std.mem.Allocator) !void {
        defer rl.closeWindow(); // Close window and OpenGL context
        while (!rl.windowShouldClose()) { // Detect window close button or ESC key
            // logic of the game and change piece location
            c.checkResults();
            if (c.result != .N) break;
            try c.checkMouse(allocator);
            rl.beginDrawing();
            defer rl.endDrawing();
            rl.clearBackground(.black);
            // draw logic
            c.draw();
        }
    }

    fn draw(c: *Chess) void {
        c.drawBoard();
    }

    fn checkResults(c: *Chess) void {
        var white_queen_counter: u8 = 0;
        var white_rook_counter: u8 = 0;
        var white_bishop_counter: u8 = 0;
        var white_knight_counter: u8 = 0;
        var white_pawn_counter: u8 = 0;
        var white_king_counter: u8 = 0;

        var black_queen_counter: u8 = 0;
        var black_rook_counter: u8 = 0;
        var black_bishop_counter: u8 = 0;
        var black_knight_counter: u8 = 0;
        var black_pawn_counter: u8 = 0;
        var black_king_counter: u8 = 0;

        for (0..8) |i| {
            for (0..8) |j| {
                switch (c.board[i][j]) {
                    .WKing => {
                        white_king_counter += 1;
                    },
                    .BKing => {
                        black_king_counter += 1;
                    },
                    .WQueen => {
                        white_queen_counter += 1;
                    },
                    .BQueen => {
                        black_queen_counter += 1;
                    },
                    .WPawn => {
                        white_pawn_counter += 1;
                    },
                    .BPawn => {
                        black_pawn_counter += 1;
                    },
                    .WRook => {
                        white_rook_counter += 1;
                    },
                    .BRook => {
                        black_rook_counter += 1;
                    },
                    .WBishop => {
                        white_bishop_counter += 1;
                    },
                    .BBishop => {
                        black_bishop_counter += 1;
                    },
                    .WKnight => {
                        white_knight_counter += 1;
                    },
                    .BKnight => {
                        black_knight_counter += 1;
                    },
                    else => {},
                }
            }
        }
        if (white_king_counter != 1 or black_king_counter != 1) unreachable;
        const white_no_piece = white_queen_counter == 0 and white_knight_counter == 0 and white_bishop_counter == 0 and white_rook_counter == 0 and white_pawn_counter == 0;
        const black_no_piece = black_queen_counter == 0 and black_knight_counter == 0 and black_bishop_counter == 0 and black_rook_counter == 0 and black_pawn_counter == 0;
        if (white_no_piece and black_no_piece) c.result = .D;
        if (c.possible_moves.len == 0) {
            if (c.turn) {
                if (c.black_attack_map[@intFromFloat(c.white_king_location.x)][@intFromFloat(c.white_king_location.y)]) {
                    c.result = .B;
                } else c.result = .D;
            } else {
                if (c.white_attack_map[@intFromFloat(c.black_king_location.x)][@intFromFloat(c.black_king_location.y)]) {
                    c.result = .W;
                } else c.result = .D;
            }
        }

        if (c.result != .N) {
            if (c.result == .D) {
                print("Draw!\n", .{});
            } else if (c.result == .W) {
                print("Checkmate!\n", .{});
                print("White wins!\n", .{});
            } else if (c.result == .B) {
                print("Checkmate!\n", .{});
                print("Black wins!\n", .{});
            }
        }
    }

    fn updatePossibleMoves(c: *Chess) void {
        c.max_possible_moves = 0;
        for (0..8) |i| {
            for (0..8) |j| {
                c.black_attack_map[i][j] = false;
                c.white_attack_map[i][j] = false;
            }
        }
        var wki: usize = 0;
        var wkj: usize = 0;
        var bki: usize = 0;
        var bkj: usize = 0;
        defer {
            // print("Updated attack maps {any}\n{any}\n", .{ c.black_attack_map, c.white_attack_map });
            H.checkKingMoves(
                &c.board,
                &c.black_attack_map,
                &c.white_attack_map,
                &c.possible_moves,
                &c.max_possible_moves,
                c.turn,
                @floatFromInt(wki),
                @floatFromInt(wkj),
                c.can_castle_short_white,
                c.can_castle_long_white,
            );
            H.checkKingMoves(
                &c.board,
                &c.black_attack_map,
                &c.white_attack_map,
                &c.possible_moves,
                &c.max_possible_moves,
                c.turn,
                @floatFromInt(bki),
                @floatFromInt(bkj),
                c.can_castle_short_black,
                c.can_castle_long_black,
            );
        }
        for (0..8) |i| {
            for (0..8) |j| {
                switch (c.board[i][j]) {
                    .None => {
                        continue;
                    },
                    .WPawn, .BPawn => {
                        H.checkPawnMoves(
                            &c.board,
                            &c.black_attack_map,
                            &c.white_attack_map,
                            &c.possible_moves,
                            &c.max_possible_moves,
                            c.turn,
                            @floatFromInt(i),
                            @floatFromInt(j),
                            c.enpassant_location,
                        );
                    },
                    .WRook, .BRook => {
                        H.checkRookMoves(
                            &c.board,
                            &c.black_attack_map,
                            &c.white_attack_map,
                            &c.possible_moves,
                            &c.max_possible_moves,
                            c.turn,
                            @floatFromInt(i),
                            @floatFromInt(j),
                        );
                    },
                    .WBishop, .BBishop => {
                        H.checkBishopMoves(
                            &c.board,
                            &c.black_attack_map,
                            &c.white_attack_map,
                            &c.possible_moves,
                            &c.max_possible_moves,
                            c.turn,
                            @floatFromInt(i),
                            @floatFromInt(j),
                        );
                    },
                    .WKnight, .BKnight => {
                        H.checkKnightMoves(
                            &c.board,
                            &c.black_attack_map,
                            &c.white_attack_map,
                            &c.possible_moves,
                            &c.max_possible_moves,
                            c.turn,
                            @floatFromInt(i),
                            @floatFromInt(j),
                        );
                    },
                    .WQueen, .BQueen => {
                        H.checkQueenMoves(
                            &c.board,
                            &c.black_attack_map,
                            &c.white_attack_map,
                            &c.possible_moves,
                            &c.max_possible_moves,
                            c.turn,
                            @floatFromInt(i),
                            @floatFromInt(j),
                        );
                    },
                    .WKing => {
                        wki = i;
                        wkj = j;
                        H.updateKingAttacks(&c.board, &c.black_attack_map, &c.white_attack_map, @floatFromInt(wki), @floatFromInt(wkj));
                    },
                    .BKing => {
                        bki = i;
                        bkj = j;
                        H.updateKingAttacks(&c.board, &c.black_attack_map, &c.white_attack_map, @floatFromInt(bki), @floatFromInt(bkj));
                    },
                }
            }
        }
    }

    fn setBoardPiece(c: *Chess, allocator: std.mem.Allocator, i: f32, j: f32, next_piece: Piece) !void {
        const prev_piece = c.board[@intFromFloat(i)][@intFromFloat(j)];
        c.board[@intFromFloat(i)][@intFromFloat(j)] = next_piece;
        try c.history.append(allocator, .{ .i = i, .j = j, .prev_piece = prev_piece, .next_piece = next_piece });
    }

    pub fn movePiece(c: *Chess, allocator: std.mem.Allocator, from: rl.Vector2, to: rl.Vector2) !void {
        // print("Here are the possible moves: {any}\n", .{c.possible_moves[0..c.max_possible_moves]});
        for (0..c.max_possible_moves) |i| {
            const from_equal = c.possible_moves[i].from.x == from.x and c.possible_moves[i].from.y == from.y;
            const to_equal = c.possible_moves[i].to.x == to.x and c.possible_moves[i].to.y == to.y;
            if (from_equal and to_equal) {
                const piece = c.board[@intFromFloat(from.x)][@intFromFloat(from.y)];
                // const target_piece = c.board[@intFromFloat(to.x)][@intFromFloat(to.y)];
                try c.setBoardPiece(allocator, from.x, from.y, .None);
                try c.setBoardPiece(allocator, to.x, to.y, piece);

                if (c.enpassant_location) |loc| {
                    if (loc.x == to.x and loc.y == to.y) {
                        const y = if (c.turn) loc.y + 1 else loc.y - 1;
                        try c.setBoardPiece(allocator, loc.x, y, .None);
                    }
                }
                c.enpassant_location = null;
                if (piece == .BPawn and from.y == 1 and to.y == 3) c.enpassant_location = .{ .x = to.x, .y = to.y - 1 };
                if (piece == .WPawn and from.y == 6 and to.y == 4) c.enpassant_location = .{ .x = to.x, .y = to.y + 1 };

                if (piece == .WKing) {
                    c.can_castle_short_white = false;
                    c.can_castle_long_white = false;
                    if (from.x - to.x == 2) {
                        const rook = c.board[0][7];
                        try c.setBoardPiece(allocator, 0, 7, .None);
                        try c.setBoardPiece(allocator, 3, 7, rook);
                    } else if (from.x - to.x == -2) {
                        const rook = c.board[7][7];
                        try c.setBoardPiece(allocator, 7, 7, .None);
                        try c.setBoardPiece(allocator, 5, 7, rook);
                    }
                    c.white_king_location = .{ .x = to.x, .y = to.y };
                }
                if (piece == .BKing) {
                    c.can_castle_short_black = false;
                    c.can_castle_long_black = false;
                    if (from.x - to.x == 2) {
                        const rook = c.board[0][0];
                        try c.setBoardPiece(allocator, 0, 0, .None);
                        try c.setBoardPiece(allocator, 3, 0, rook);
                    } else if (from.x - to.x == -2) {
                        const rook = c.board[7][0];
                        try c.setBoardPiece(allocator, 7, 0, .None);
                        try c.setBoardPiece(allocator, 5, 0, rook);
                    }
                    c.black_king_location = .{ .x = to.x, .y = to.y };
                }

                c.updatePossibleMoves();

                if ((c.turn and c.black_attack_map[@intFromFloat(c.white_king_location.x)][@intFromFloat(c.white_king_location.y)])) {
                    c.revertMoves();
                    break;
                }
                if ((!c.turn and c.white_attack_map[@intFromFloat(c.black_king_location.x)][@intFromFloat(c.black_king_location.y)])) {
                    c.revertMoves();
                    break;
                }
                if (from.x == 0 and from.y == 7) c.can_castle_long_white = false;
                if (from.x == 7 and from.y == 7) c.can_castle_short_white = false;
                if (from.x == 0 and from.y == 0) c.can_castle_long_black = false;
                if (from.x == 7 and from.y == 0) c.can_castle_short_black = false;
                if (to.x == 0 and to.y == 7) c.can_castle_long_white = false;
                if (to.x == 7 and to.y == 7) c.can_castle_short_white = false;
                if (to.x == 0 and to.y == 0) c.can_castle_long_black = false;
                if (to.x == 7 and to.y == 0) c.can_castle_short_black = false;

                c.turn = !c.turn;
                c.updatePossibleMoves();
                c.history_counter = c.history.items.len;
                break;
            }
        }
    }

    fn revertMoves(c: *Chess) void {
        const start = c.history_counter;
        const end = c.history.items.len;
        var index = end - 1;
        while (index >= start) : (index -= 1) {
            const prev = c.history.items[index].prev_piece;
            const i: usize = @intFromFloat(c.history.items[index].i);
            const j: usize = @intFromFloat(c.history.items[index].j);
            c.board[i][j] = prev;
            _ = c.history.swapRemove(index);
        }
        if (c.history_counter != c.history.items.len) unreachable;
    }

    fn checkMouse(c: *Chess, allocator: std.mem.Allocator) !void {
        const pressed = rl.isMouseButtonPressed(.left);
        // const hold = rl.isMouseButtonDown(.left);
        // if (!hold or !pressed) return;
        if (!pressed) return;
        const mouse_pos = rl.getMousePosition();
        const pos = mouse_pos.subtract(c.board_position);
        if (pos.x < 0 or pos.y < 0 or pos.x >= 8 * PieceSize or pos.y >= 8 * PieceSize) {
            c.selected_piece = null;
            return;
        }
        const piece_x = @floor(pos.x / PieceSize);
        const piece_y = @floor(pos.y / PieceSize);
        const to_piece = c.board[@intFromFloat(piece_x)][@intFromFloat(piece_y)];
        if (c.selected_piece) |from| {
            try c.movePiece(allocator, from, .{ .x = piece_x, .y = piece_y });
            c.selected_piece = null;
        } else if (to_piece != .None) c.selected_piece = .{ .x = piece_x, .y = piece_y };
    }

    fn drawBoard(c: *Chess) void {
        const startx = c.board_position.x;
        const starty = c.board_position.y;
        for (0..8) |i| {
            for (0..8) |j| {
                const x: i32 = @intFromFloat(startx + @as(f32, @floatFromInt(i)) * PieceSize);
                const y: i32 = @intFromFloat(starty + @as(f32, @floatFromInt(j)) * PieceSize);
                const colorw = rl.Color{ .r = 230, .g = 230, .b = 230, .a = 255 };
                const colorb = rl.Color{ .r = 70, .g = 70, .b = 70, .a = 255 };
                const color = if ((i + j) % 2 == 0) colorw else colorb;
                const redc = rl.Color{ .r = 255, .g = 0, .b = 0, .a = 150 };
                const bluec = rl.Color{ .r = 0, .g = 0, .b = 255, .a = 150 };
                const purplec = rl.Color{ .r = 128, .g = 0, .b = 128, .a = 150 };
                rl.drawRectangle(x, y, PieceSize, PieceSize, color);
                if (c.black_attack_map[i][j] and c.white_attack_map[i][j]) {
                    rl.drawRectangle(x, y, PieceSize, PieceSize, purplec);
                } else if (c.black_attack_map[i][j]) {
                    rl.drawRectangle(x, y, PieceSize, PieceSize, redc);
                } else if (c.white_attack_map[i][j]) {
                    rl.drawRectangle(x, y, PieceSize, PieceSize, bluec);
                }
            }
        }
        if (c.selected_piece) |selected_piece| {
            const selectedx: i32 = @intFromFloat(startx + selected_piece.x * PieceSize);
            const selectedy: i32 = @intFromFloat(starty + selected_piece.y * PieceSize);
            rl.drawRectangleLines(selectedx, selectedy, PieceSize, PieceSize, rl.Color{ .r = 0, .g = 255, .b = 0, .a = 255 });
        }
        for (0..8) |i| {
            for (0..8) |j| {
                if (c.board[i][j] == .None) continue;
                var source_rect = rl.Rectangle{
                    .x = 0,
                    .y = 0,
                    .width = PieceSize,
                    .height = PieceSize,
                };
                switch (c.board[i][j]) {
                    .WPawn => {
                        source_rect.x = 5 * PieceSize;
                        source_rect.y = PieceSize;
                    },
                    .WKing => {
                        source_rect.x = PieceSize;
                        source_rect.y = PieceSize;
                    },
                    .WQueen => {
                        source_rect.y = PieceSize;
                    },
                    .WRook => {
                        source_rect.x = 2 * PieceSize;
                        source_rect.y = PieceSize;
                    },
                    .WBishop => {
                        source_rect.x = 4 * PieceSize;
                        source_rect.y = PieceSize;
                    },
                    .WKnight => {
                        source_rect.x = 3 * PieceSize;
                        source_rect.y = PieceSize;
                    },
                    .BPawn => {
                        source_rect.x = 5 * PieceSize;
                    },
                    .BKing => {
                        source_rect.x = PieceSize;
                    },
                    .BQueen => {},
                    .BRook => {
                        source_rect.x = 2 * PieceSize;
                    },
                    .BBishop => {
                        source_rect.x = 4 * PieceSize;
                    },
                    .BKnight => {
                        source_rect.x = 3 * PieceSize;
                    },
                    .None => {
                        unreachable;
                    },
                }
                const dest_rect = rl.Rectangle{
                    .x = startx + @as(f32, @floatFromInt(i)) * PieceSize,
                    .y = starty + @as(f32, @floatFromInt(j)) * PieceSize,
                    .width = PieceSize,
                    .height = PieceSize,
                };
                rl.drawTexturePro(c.texture, source_rect, dest_rect, .{ .x = 0, .y = 0 }, 0, .white);
            }
        }
    }

    /// origin is top left.
    /// so bottom right is (7, 7)
    /// and top right is (0, 7)
    fn setupBoard(c: *Chess) void {
        c.board[0][0] = .BRook;
        c.board[1][0] = .BKnight;
        c.board[2][0] = .BBishop;
        c.board[3][0] = .BQueen;
        c.board[4][0] = .BKing;
        c.board[5][0] = .BBishop;
        c.board[6][0] = .BKnight;
        c.board[7][0] = .BRook;
        for (0..8) |i| {
            c.board[i][1] = .BPawn;
        }
        c.board[0][7] = .WRook;
        c.board[1][7] = .WKnight;
        c.board[2][7] = .WBishop;
        c.board[3][7] = .WQueen;
        c.board[4][7] = .WKing;
        c.board[5][7] = .WBishop;
        c.board[6][7] = .WKnight;
        c.board[7][7] = .WRook;
        for (0..8) |i| {
            c.board[i][6] = .WPawn;
        }
        for (0..8) |i| {
            for (2..6) |j| {
                c.board[i][j] = .None;
            }
        }
    }
};
