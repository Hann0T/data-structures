const std = @import("std");
const print = std.debug.print;

const Position = struct {
    x: u8,
    y: u8,
};

const movement = [4][2]i8{
    [_]i8{ -1, 0 },
    [_]i8{ 0, 1 },
    [_]i8{ 1, 0 },
    [_]i8{ 0, -1 },
};

fn walk(maze: []const []const u8, wall: u8, current: Position, end: Position, path: *std.ArrayList(Position), seen: [][]bool) !bool {
    if (current.y < 0 or maze.len <= current.y or current.x < 0 or maze[0].len <= current.x) {
        return false;
    }

    if (maze[current.y][current.x] == wall) {
        return false;
    }

    if (seen[current.y][current.x]) {
        return false;
    }

    if (current.x == end.x and current.y == end.y) {
        try path.append(current);
        return true;
    }

    // pre recursion
    try path.append(current);
    seen[current.y][current.x] = true;

    for (movement) |coord| {
        const pos = Position{
            .x = @intCast(@as(i16, current.x) + coord[0]),
            .y = @intCast(@as(i16, current.y) + coord[1]),
        };

        if (try walk(maze, wall, pos, end, path, seen)) {
            return true;
        }
    }

    // If the current position did not lead to a valid path (dead-end), we remove it from the path.
    _ = path.pop();

    return false;
}

pub fn solve(allocator: std.mem.Allocator, maze: []const []const u8, wall: u8, start: Position, end: Position, seen: [][]bool) ![]Position {
    var path = std.ArrayList(Position).init(allocator);
    errdefer path.deinit();

    _ = try walk(maze, wall, start, end, &path, seen);
    print("final path: {any}\n", .{path.items});
    print("final seen: {any}\n", .{seen});

    return path.toOwnedSlice();
}

test "Maze Solver" {
    const allocator = std.testing.allocator;
    const maze = [_][]const u8{
        "xxxxxxxxxx x",
        "x        x x",
        "x        x x",
        "x xxxxxxxx x",
        "x          x",
        "x xxxxxxxxxx",
    };

    var seen: [6][12]bool = undefined; // Define as a fixed-size array
    for (&seen) |*row| {
        row.* = [_]bool{false} ** row.len;
    }

    var seenSlice = [_][]bool{
        seen[0][0..],
        seen[1][0..],
        seen[2][0..],
        seen[3][0..],
        seen[4][0..],
        seen[5][0..],
    };

    const solution = try solve(allocator, &maze, 'x', .{ .x = 10, .y = 0 }, .{ .x = 1, .y = 5 }, &seenSlice);
    defer allocator.free(solution);

    const expected = [_]Position{
        Position{ .x = 10, .y = 0 },
        Position{ .x = 10, .y = 1 },
        Position{ .x = 10, .y = 2 },
        Position{ .x = 10, .y = 3 },
        Position{ .x = 10, .y = 4 },
        Position{ .x = 9, .y = 4 },
        Position{ .x = 8, .y = 4 },
        Position{ .x = 7, .y = 4 },
        Position{ .x = 6, .y = 4 },
        Position{ .x = 5, .y = 4 },
        Position{ .x = 4, .y = 4 },
        Position{ .x = 3, .y = 4 },
        Position{ .x = 2, .y = 4 },
        Position{ .x = 1, .y = 4 },
        Position{ .x = 1, .y = 5 },
    };

    try std.testing.expectEqualSlices(Position, &expected, solution);
}
