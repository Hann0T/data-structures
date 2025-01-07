const std = @import("std");

pub fn Stack(comptime T: type) type {
    const Node = struct {
        const Self = @This();

        value: T,
        prev: ?*Self,
    };

    return struct {
        const Self = @This();

        len: usize,
        head: ?*Node,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .len = 0, .head = null, .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            while (self.head) |head| {
                defer self.allocator.destroy(head);

                self.head = head.prev;
            }
        }

        pub fn push(self: *Self, item: T) !void {
            var node = try self.allocator.create(Node);
            node.* = .{ .value = item, .prev = null };
            self.len += 1;

            if (self.head) |head| {
                node.prev = head;
                self.head = node;
                return;
            }

            self.head = node;
        }

        pub fn pop(self: *Self) ?T {
            if (self.head) |head| {
                defer self.allocator.destroy(head);
                self.head = head.prev;
                self.len -= 1;
                return head.value;
            }

            return null;
        }

        pub fn peek(self: Self) ?T {
            if (self.head) |head| {
                return head.value;
            }

            return null;
        }
    };
}

test "Stack" {
    const allocator = std.testing.allocator;

    var stack = Stack(u16).init(allocator);
    defer stack.deinit();

    try std.testing.expectEqual(0, stack.len);

    try stack.push(12);
    try std.testing.expectEqual(1, stack.len);
    try std.testing.expectEqual(12, stack.peek());
    try std.testing.expectEqual(12, stack.pop());
    try std.testing.expectEqual(null, stack.peek());
    try std.testing.expectEqual(null, stack.head);
    try std.testing.expectEqual(null, stack.pop());
    try std.testing.expectEqual(null, stack.head);
    try std.testing.expectEqual(0, stack.len);
}
