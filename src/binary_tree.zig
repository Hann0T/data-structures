const std = @import("std");
const Queue = @import("./queue_2.zig").Queue;

const DepthFirstSearchMethod = enum {
    INORDER,
    PREORDER,
    POSTORDER,
};

pub fn BinaryTreeNode(comptime T: type) type {
    return struct {
        const Self = @This();

        value: T,
        left: ?*BinaryTreeNode(T),
        right: ?*BinaryTreeNode(T),
        allocator: std.mem.Allocator,

        pub fn init(arena: std.mem.Allocator, value: T) Self {
            return .{
                .left = null,
                .right = null,
                .value = value,
                .allocator = arena,
            };
        }

        pub fn insert(self: *Self, value: T) !void {
            if (self.value == value) return;

            if (self.value > value) {
                if (self.left) |left| {
                    try left.insert(value);
                    return;
                }
                const node = try self.allocator.create(BinaryTreeNode(T));
                errdefer self.allocator.destroy(node);
                node.* = BinaryTreeNode(T).init(self.allocator, value);
                self.left = node;
            } else {
                if (self.right) |right| {
                    try right.insert(value);
                    return;
                }
                const node = try self.allocator.create(BinaryTreeNode(T));
                errdefer self.allocator.destroy(node);
                node.* = BinaryTreeNode(T).init(self.allocator, value);
                self.right = node;
            }
        }

        pub fn delete(self: *Self, value: T) Self {
            // TODO
            _ = self;
            _ = value;
        }

        // Preorder
        // inorder
        // postorder
        pub fn depth_first_search(self: *Self, visited: *std.ArrayList(T), method: DepthFirstSearchMethod) !void {
            switch (method) {
                .PREORDER => try self.preorder(visited),
                .INORDER => try self.inorder(visited),
                .POSTORDER => try self.postorder(visited),
            }
        }

        pub fn inorder(self: *Self, visited: *std.ArrayList(T)) !void {
            if (self.left) |left| {
                try left.inorder(visited);
            }
            try visited.append(self.value);
            if (self.right) |right| {
                try right.inorder(visited);
            }
        }

        pub fn preorder(self: *Self, visited: *std.ArrayList(T)) !void {
            try visited.append(self.value);
            if (self.left) |left| {
                try left.preorder(visited);
            }
            if (self.right) |right| {
                try right.preorder(visited);
            }
        }

        pub fn postorder(self: *Self, visited: *std.ArrayList(T)) !void {
            if (self.left) |left| {
                try left.postorder(visited);
            }
            if (self.right) |right| {
                try right.postorder(visited);
            }
            try visited.append(self.value);
        }

        pub fn breadth_first_search(self: *Self, visited: *std.ArrayList(T)) !void {
            var queue = Queue(*BinaryTreeNode(T)).init(self.allocator);
            try queue.enqueue(self);

            while (queue.dequeue()) |node| {
                if (node.left) |left| {
                    try queue.enqueue(left);
                }

                if (node.right) |right| {
                    try queue.enqueue(right);
                }

                try visited.append(node.value);
            }
        }

        pub fn BFS_walk(self: *Self) !void {
            _ = self;
        }

        pub fn min(self: *Self) T {
            var current = self;
            while (current.left != null) {
                current = current.left.?;
            }
            return current.value;
        }

        pub fn max(self: *Self) T {
            var current = self;
            while (current.right != null) {
                current = current.right.?;
            }
            return current.value;
        }
    };
}

test "should work" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tree = BinaryTreeNode(i32).init(allocator, 12);
    try tree.insert(11);
    try tree.insert(13);

    try std.testing.expectEqual(11, tree.min());
    try std.testing.expectEqual(13, tree.max());

    try tree.insert(4);
    try tree.insert(30);
    try std.testing.expectEqual(4, tree.min());
    try std.testing.expectEqual(30, tree.max());
}

test "min max empty" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tree = BinaryTreeNode(i32).init(allocator, 12);
    try std.testing.expectEqual(12, tree.min());
    try std.testing.expectEqual(12, tree.max());
}

test "preorder" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tree = BinaryTreeNode(i32).init(allocator, 4);
    try tree.insert(2);
    try tree.insert(1);
    try tree.insert(7);
    try tree.insert(6);

    var list = std.ArrayList(i32).init(allocator);
    defer list.deinit();

    try tree.depth_first_search(&list, .PREORDER);

    const expected = [_]i32{ 4, 2, 1, 7, 6 };
    try std.testing.expectEqualSlices(i32, &expected, try list.toOwnedSlice());
}

test "postorder" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tree = BinaryTreeNode(i32).init(allocator, 4);
    try tree.insert(2);
    try tree.insert(1);
    try tree.insert(7);
    try tree.insert(6);

    var list = std.ArrayList(i32).init(allocator);
    defer list.deinit();

    try tree.depth_first_search(&list, .POSTORDER);

    const expected = [_]i32{ 1, 2, 6, 7, 4 };
    try std.testing.expectEqualSlices(i32, &expected, try list.toOwnedSlice());
}

test "inorder" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tree = BinaryTreeNode(i32).init(allocator, 4);
    try tree.insert(2);
    try tree.insert(1);
    try tree.insert(7);
    try tree.insert(6);

    var list = std.ArrayList(i32).init(allocator);
    defer list.deinit();

    try tree.depth_first_search(&list, .INORDER);

    const expected = [_]i32{ 1, 2, 4, 6, 7 };
    try std.testing.expectEqualSlices(i32, &expected, try list.toOwnedSlice());
}

test "BFS" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tree = BinaryTreeNode(i32).init(allocator, 4);
    try tree.insert(2);
    try tree.insert(1);
    try tree.insert(7);
    try tree.insert(6);

    var visited = std.ArrayList(i32).init(allocator);
    defer visited.deinit();

    try tree.breadth_first_search(&visited);

    const expected = [_]i32{ 4, 2, 7, 1, 6 };
    try std.testing.expectEqualSlices(i32, &expected, try visited.toOwnedSlice());
}
