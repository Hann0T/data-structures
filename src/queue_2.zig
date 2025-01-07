const std = @import("std");

pub fn Queue(comptime T: type) type {
    const Node = struct {
        const Self = @This();

        value: T,
        next: ?*Self,
        prev: ?*Self,
    };

    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        head: ?*Node,
        tail: ?*Node,
        len: usize,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .head = null,
                .tail = null,
                .len = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            while (self.head) |head| {
                defer self.allocator.destroy(head);
                self.head = head.next;
            }

            return;
        }

        pub fn enqueue(self: *Self, item: T) !void {
            var node = try self.allocator.create(Node);
            node.* = .{ .value = item, .next = null, .prev = null };

            if (self.head == null) {
                self.head = node;
            }

            if (self.tail) |tail| {
                tail.next = node;
                node.prev = tail;
            }

            self.tail = node;
            self.len += 1;
        }

        pub fn dequeue(self: *Self) ?T {
            if (self.head) |head| {
                defer self.allocator.destroy(head);
                self.len -= 1;
                self.head = head.next;
                if (self.len == 0) self.tail = null;
                return head.value;
            }

            return null;
        }

        pub fn peek(self: *Self) ?T {
            if (self.head) |head| {
                return head.value;
            }

            return null;
        }
    };
}

test "Queue" {
    const allocator = std.testing.allocator;

    var queue = Queue(u16).init(allocator);
    defer queue.deinit();

    try std.testing.expectEqual(0, queue.len);
    try std.testing.expectEqual(null, queue.head);
    try std.testing.expectEqual(null, queue.tail);

    try queue.enqueue(12);
    try std.testing.expectEqual(1, queue.len);
    try std.testing.expectEqual(12, queue.head.?.value);
    try std.testing.expectEqual(12, queue.tail.?.value);
    try std.testing.expectEqual(12, queue.peek());

    try queue.enqueue(13);
    try std.testing.expectEqual(2, queue.len);
    try std.testing.expectEqual(12, queue.head.?.value);
    try std.testing.expectEqual(13, queue.tail.?.value);
    try std.testing.expectEqual(12, queue.peek());

    try std.testing.expectEqual(12, queue.dequeue().?);
    try std.testing.expectEqual(13, queue.dequeue().?);
    try std.testing.expectEqual(null, queue.dequeue());
    try std.testing.expectEqual(0, queue.len);
}

test "Queue one item" {
    const allocator = std.testing.allocator;

    var queue = Queue(u16).init(allocator);
    defer queue.deinit();

    try std.testing.expectEqual(0, queue.len);
    try std.testing.expectEqual(null, queue.head);
    try std.testing.expectEqual(null, queue.tail);

    try queue.enqueue(12);
    try std.testing.expectEqual(1, queue.len);
    try std.testing.expectEqual(12, queue.head.?.value);
    try std.testing.expectEqual(12, queue.tail.?.value);
    try std.testing.expectEqual(12, queue.peek());

    try std.testing.expectEqual(12, queue.dequeue().?);
    try std.testing.expectEqual(null, queue.dequeue());
    try std.testing.expectEqual(0, queue.len);
    try std.testing.expectEqual(null, queue.peek());
    try std.testing.expectEqual(null, queue.head);
    try std.testing.expectEqual(null, queue.tail);
}

test "Queue memory leak" {
    const allocator = std.testing.allocator;

    var queue = Queue(u16).init(allocator);
    defer queue.deinit();

    try queue.enqueue(12);

    try std.testing.expectEqual(12, queue.peek());
    try std.testing.expectEqual(12, queue.dequeue());
    try std.testing.expectEqual(null, queue.tail);
    try std.testing.expectEqual(null, queue.head);
}
