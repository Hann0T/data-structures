const std = @import("std");
const print = std.debug.print;

pub fn Queue(comptime T: type) type {
    const Node = struct {
        const Self = @This();
        value: T,
        next: ?*Self,
    };

    return struct {
        const Self = @This();

        head: ?*Node,
        tail: ?*Node,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .head = null,
                .tail = null,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            while (self.head) |head| {
                defer self.allocator.destroy(head);
                self.head = head.next;
            }
        }

        pub fn push(self: *Self, value: T) !void {
            const new_node = try self.allocator.create(Node);
            errdefer self.allocator.destroy(new_node);
            new_node.* = Node{ .value = value, .next = null };

            if (self.tail) |tail| {
                tail.next = new_node; // implicit struct dereferencing | tail.*.next
            } else {
                self.head = new_node;
            }

            self.tail = new_node;
        }

        pub fn pop(self: *Self) ?T {
            if (self.head) |head| {
                defer self.allocator.destroy(head);

                self.head = head.next; // implicit struct dereferencing | head.*.next

                if (head.next == null) {
                    self.tail = null;
                }

                return head.value;
            }

            return null;
        }
    };
}

test "Queue test" {
    const allocator = std.testing.allocator;

    var queue = Queue(u16).init(allocator);
    defer queue.deinit();

    try std.testing.expectEqual(queue.pop(), null);

    try queue.push(11);
    try queue.push(12);
    try std.testing.expectEqual(queue.head.?.value, 11);
    try std.testing.expectEqual(queue.tail.?.value, 12);

    try queue.push(13);
    try std.testing.expectEqual(queue.head.?.value, 11);
    try std.testing.expectEqual(queue.tail.?.value, 13);

    try std.testing.expectEqual(queue.pop().?, 11);
    try std.testing.expectEqual(queue.pop().?, 12);
    try std.testing.expectEqual(queue.pop().?, 13);
    try std.testing.expectEqual(queue.pop(), null);
}

test "Queue memory leak test" {
    const allocator = std.testing.allocator;

    var queue = Queue(u16).init(allocator);
    defer queue.deinit();

    try std.testing.expectEqual(queue.pop(), null);

    try queue.push(14);
    try queue.push(15);
    try queue.push(16);
    try queue.push(17);

    try std.testing.expectEqual(queue.pop().?, 14);
}

test "Queue segmentation fault test" {
    const allocator = std.testing.allocator;

    var queue = Queue(u16).init(allocator);
    defer queue.deinit();

    try std.testing.expectEqual(queue.pop(), null);

    try queue.push(14);
    try std.testing.expectEqual(queue.pop().?, 14);

    // seg fault?
    try std.testing.expectEqual(queue.tail, null);
    try std.testing.expectEqual(queue.head, null);
}
