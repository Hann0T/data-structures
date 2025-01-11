const std = @import("std");
const print = std.debug.print;
const Queue = @import("queue.zig").Queue;

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

        // type of depth first search:
        // preorder
        // inorder
        // postorder
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

        pub fn breadth_first_search(self: *Self, needle: T) !bool {
            var queue = Queue(*Self).init(self.allocator);
            defer queue.deinit();

            try queue.push(self);
            while (queue.pop()) |node| {
                if (node.value == needle) {
                    return true;
                }

                if (node.left) |left| {
                    try queue.push(left);
                }

                if (node.right) |right| {
                    try queue.push(right);
                }

                print("breadth_first_search node: {any}\n", .{node.value});
            }

            return false;
        }

        pub fn compare(a: ?*Self, b: ?*Self) bool {
            if (a == null and b == null) {
                return true;
            }

            if (a == null or b == null) {
                return false;
            }

            if (a.?.value != b.?.value) {
                return false;
            }

            return Self.compare(a.?.left, b.?.left) and Self.compare(a.?.right, b.?.right);
            // return compare(a.?.left, b.?.left) and compare(a.?.right, b.?.right); // works too!
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

test "Binary Tree breadth_first_search" {
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

    print("BFS Testing new needle\n", .{});
    try std.testing.expect(try b_tree.breadth_first_search(12));
    // should print:
    // nothing
    print("nothing\n", .{});

    print("BFS Testing new needle\n", .{});
    try std.testing.expect(try b_tree.breadth_first_search(6));
    // should print:
    // breadth_first_search node: 12
    // breadth_first_search node: 5
    // breadth_first_search node: 16
    // breadth_first_search node: 4
    // breadth_first_search node: 7
    // breadth_first_search node: 14
    // breadth_first_search node: 26

    print("BFS Testing new needle\n", .{});
    try std.testing.expect(!try b_tree.breadth_first_search(6000));
    // should print:
    // breadth_first_search node: 12
    // breadth_first_search node: 5
    // breadth_first_search node: 16
    // breadth_first_search node: 4
    // breadth_first_search node: 7
    // breadth_first_search node: 14
    // breadth_first_search node: 26
    // breadth_first_search node: 6
}

test "Binary Tree comparition" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var a_tree = BinaryTree(u16).init(allocator, 12);
    try std.testing.expectEqual(a_tree.left, null);
    try std.testing.expectEqual(a_tree.right, null);
    try a_tree.insert(5);
    try a_tree.insert(16);
    try a_tree.insert(4);
    try a_tree.insert(7);
    try a_tree.insert(6);
    try a_tree.insert(14);
    try a_tree.insert(26);

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

    var c_tree = BinaryTree(u16).init(allocator, 500);
    try std.testing.expectEqual(c_tree.left, null);
    try std.testing.expectEqual(c_tree.right, null);
    try c_tree.insert(16);

    try std.testing.expect(BinaryTree(u16).compare(&a_tree, &b_tree));
    try std.testing.expectEqual(false, BinaryTree(u16).compare(&a_tree, &c_tree));
    try std.testing.expectEqual(false, BinaryTree(u16).compare(&b_tree, &c_tree));
}
