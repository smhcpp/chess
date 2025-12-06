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

pub const Chess = struct {
    pub const PieceSize: f32 = 60;

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
    //turn : white move, !turn : black move
    turn: bool = true,
    possible_moves: [256]Move = undefined,
    max_possible_moves: usize = 0,
    // square_size: f32 = 60,

    pub fn init(allocator: std.mem.Allocator) !*Chess {
        const c = try allocator.create(Chess);
        c.* = .{};
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
        allocator.destroy(c);
    }

    pub fn run(c: *Chess) void {
        defer rl.closeWindow(); // Close window and OpenGL context
        while (!rl.windowShouldClose()) { // Detect window close button or ESC key
            // logic of the game and change piece location
            c.checkMouse();
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

    pub fn movePiece(c: *Chess, from: rl.Vector2, to: rl.Vector2) void {
        // print("Here are the possible moves: {any}\n", .{c.possible_moves[0..c.max_possible_moves]});
        for (0..c.max_possible_moves) |i| {
            const from_equal = c.possible_moves[i].from.x == from.x and c.possible_moves[i].from.y == from.y;
            const to_equal = c.possible_moves[i].to.x == to.x and c.possible_moves[i].to.y == to.y;
            if (from_equal and to_equal) {
                const piece = c.board[@intFromFloat(from.x)][@intFromFloat(from.y)];
                c.board[@intFromFloat(from.x)][@intFromFloat(from.y)] = .None;
                c.board[@intFromFloat(to.x)][@intFromFloat(to.y)] = piece;

                if (c.enpassant_location) |loc| {
                    if (loc.x == to.x and loc.y == to.y) {
                        const y = if (c.turn) loc.y + 1 else loc.y - 1;
                        c.board[@intFromFloat(loc.x)][@intFromFloat(y)] = .None;
                    }
                }
                c.enpassant_location = null;
                if (piece == .BPawn and from.y == 1 and to.y == 3) c.enpassant_location = .{ .x = to.x, .y = to.y - 1 };
                if (piece == .WPawn and from.y == 6 and to.y == 4) c.enpassant_location = .{ .x = to.x, .y = to.y + 1 };

                if (piece == .WKing) {
                    c.can_castle_short_white = false;
                    c.can_castle_long_white = false;
                    if( from.x-to.x == 2) {
                        const rook = c.board[0][7];
                        c.board[0][7] = .None;
                        c.board[3][7] = rook;
                    }else if(from.x-to.x == -2) {
                        const rook = c.board[7][7];
                        c.board[7][7] = .None;
                        c.board[5][7] = rook;
                    }
                }
                if (piece == .BKing) {
                    c.can_castle_short_black = false;
                    c.can_castle_long_black = false;
                    if( from.x-to.x == 2) {
                        const rook = c.board[0][0];
                        c.board[0][0] = .None;
                        c.board[3][0] = rook;
                    }else if(from.x-to.x == -2) {
                        const rook = c.board[7][7];
                        c.board[7][0] = .None;
                        c.board[5][0] = rook;
                    }
                }
                if (from.x == 0 and from.y == 7) c.can_castle_long_white = false;
                if (from.x == 7 and from.y == 7) c.can_castle_short_white = false;
                if (from.x == 0 and from.y == 0) c.can_castle_long_black = false;
                if (from.x == 7 and from.y == 0) c.can_castle_short_black = false;

                c.turn = !c.turn;
                c.updatePossibleMoves();
                break;
            }
        }
    }

    fn checkMouse(c: *Chess) void {
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
            // const from_piece = c.board[@intFromFloat(from.x)][@intFromFloat(from.y)];
            // const t = @intFromEnum(to_piece);
            // const f = @intFromEnum(from_piece);
            // const wmove = c.turn and f < 7 and (t == 0 or t > 6);
            // const bmove = !c.turn and f > 6 and t < 7;
            // if (wmove or bmove) c.movePiece(from, .{ .x = piece_y, .y = piece_x });
            c.movePiece(from, .{ .x = piece_x, .y = piece_y });
            c.selected_piece = null;
        } else if (to_piece != .None) c.selected_piece = .{ .x = piece_x, .y = piece_y };
    }

    fn drawBoard(c: *Chess) void {
        const startx = c.board_position.x;
        const starty = c.board_position.y;
        for (0..8) |i| {
            for (0..8) |j| {
                const colorw = rl.Color{ .r = 230, .g = 230, .b = 230, .a = 255 };
                const colorb = rl.Color{ .r = 70, .g = 70, .b = 70, .a = 255 };
                var color = if ((i + j) % 2 == 0) colorw else colorb;
                const redc = rl.Color{ .r = 255, .g = 0, .b = 0, .a = 255 };
                const bluec = rl.Color{ .r = 0, .g = 0, .b = 255, .a = 255 };
                const purplec = rl.Color{ .r = 128, .g = 0, .b = 128, .a = 255 };
                if (c.black_attack_map[i][j] and c.white_attack_map[i][j]) {
                    color = purplec;
                } else if (c.black_attack_map[i][j]) {
                    color = redc;
                } else if (c.white_attack_map[i][j]) {
                    color = bluec;
                }
                const x: i32 = @intFromFloat(startx + @as(f32, @floatFromInt(i)) * PieceSize);
                const y: i32 = @intFromFloat(starty + @as(f32, @floatFromInt(j)) * PieceSize);
                rl.drawRectangle(x, y, PieceSize, PieceSize, color);
                // if (c.black_attack_map[i][j]) {
                //     rl.drawCircle(x + 5, y + 5, 4, redc);
                // }
                // if (c.white_attack_map[i][j]) {
                //     rl.drawCircle(x + @as(i32, @intFromFloat(PieceSize)) - 5, y + 5, 4, bluec);
                // }
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
