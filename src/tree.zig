const std = @import("std");
const print = std.debug.print;

pub fn BinaryTree(comptime T: type) type {
    return struct {
        const Self = @This();

        value: T,
        allocator: std.mem.Allocator,
        left: ?*BinaryTree(T),
        right: ?*BinaryTree(T),

        pub fn init(allocator: std.mem.Allocator, value: T) BinaryTree(T) {
            return .{
                .value = value,
                .allocator = allocator,
                .left = null,
                .right = null,
            };
        }

        pub fn insert(self: *Self, value: T) !void {
            if (self.value == value) return;

            if (value < self.value) {
                if (self.left) |left| {
                    try left.insert(value);
                    return;
                }
                const left = try self.allocator.create(BinaryTree(T));
                errdefer self.allocator.destroy(left);

                left.* = BinaryTree(T).init(self.allocator, value);
                self.left = left;
            }

            if (value > self.value) {
                if (self.right) |right| {
                    try right.insert(value);
                    return;
                }
                const right = try self.allocator.create(BinaryTree(T));
                errdefer self.allocator.destroy(right);

                right.* = BinaryTree(T).init(self.allocator, value);
                self.right = right;
            }
        }

        pub fn min(self: Self) !T {
            if (self.left) |left| {
                return left.min();
            } else {
                return self.value;
            }
        }

        pub fn max(self: Self) !T {
            if (self.right) |right| {
                return right.max();
            } else {
                return self.value;
            }
        }

        pub fn inorder(self: Self, visited: *std.ArrayList(T)) !void {
            if (self.left) |left| {
                try left.inorder(visited);
            }

            try visited.append(self.value);

            if (self.right) |right| {
                try right.inorder(visited);
            }

            return;
        }
    };
}

test "Binary Tree" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var b_tree = BinaryTree(u16).init(allocator, 12);

    try std.testing.expectEqual(b_tree.left, null);
    try std.testing.expectEqual(b_tree.right, null);

    try b_tree.insert(5);
    try b_tree.insert(16);

    try std.testing.expectEqual(b_tree.left.?.value, 5);
    try std.testing.expectEqual(b_tree.right.?.value, 16);

    const left = b_tree.left.?;
    try std.testing.expectEqual(left.left, null);
    try std.testing.expectEqual(left.right, null);

    try b_tree.insert(4);
    try b_tree.insert(6);
    try std.testing.expectEqual(left.left.?.value, 4);
    try std.testing.expectEqual(left.right.?.value, 6);

    const right = b_tree.right.?;
    try std.testing.expectEqual(right.left, null);
    try std.testing.expectEqual(right.right, null);

    try b_tree.insert(14);
    try b_tree.insert(26);
    try std.testing.expectEqual(right.left.?.value, 14);
    try std.testing.expectEqual(right.right.?.value, 26);
}

test "Binary Tree min and max" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var b_tree = BinaryTree(u16).init(allocator, 12);
    try std.testing.expectEqual(b_tree.left, null);
    try std.testing.expectEqual(b_tree.right, null);
    try std.testing.expectEqual(b_tree.min(), 12);
    try std.testing.expectEqual(b_tree.max(), 12);

    try b_tree.insert(5);
    try b_tree.insert(16);

    try std.testing.expectEqual(b_tree.min(), 5);
    try std.testing.expectEqual(b_tree.max(), 16);

    try b_tree.insert(4);
    try b_tree.insert(6);
    try b_tree.insert(14);
    try b_tree.insert(26);

    try std.testing.expectEqual(b_tree.min(), 4);
    try std.testing.expectEqual(b_tree.max(), 26);
}

test "Binary Tree inorder" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var b_tree = BinaryTree(u16).init(allocator, 12);
    try std.testing.expectEqual(b_tree.left, null);
    try std.testing.expectEqual(b_tree.right, null);

    try b_tree.insert(5);
    try b_tree.insert(16);
    try b_tree.insert(4);
    try b_tree.insert(7);
    try b_tree.insert(6);
    try b_tree.insert(14);
    try b_tree.insert(26);

    const expected = [_]u16{ 4, 5, 6, 7, 12, 14, 16, 26 };
    var actual = std.ArrayList(u16).init(allocator);
    try b_tree.inorder(&actual);

    try std.testing.expectEqualSlices(u16, expected[0..], try actual.toOwnedSlice());
}
