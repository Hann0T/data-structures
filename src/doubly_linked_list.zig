const std = @import("std");

pub fn DoublyLinkedList(comptime T: type) type {
    const Node = struct {
        const Self = @This();
        value: T,
        prev: ?*Self,
        next: ?*Self,
    };

    return struct {
        const Self = @This();

        head: ?*Node,
        tail: ?*Node,
        allocator: std.mem.Allocator,
        len: usize,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .len = 0, .head = null, .tail = null, .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            var curr = self.head;
            for (0..self.len) |_| {
                if (curr) |node| {
                    defer self.allocator.destroy(node);
                    curr = node.next;
                } else {
                    break;
                }
            }
            self.head = null;
            self.tail = null;
            self.len = 0;
        }

        pub fn append(self: *Self, item: T) !void {
            var node = try self.allocator.create(Node);
            errdefer self.allocator.destroy(node);
            node.* = Node{ .value = item, .prev = null, .next = null };

            self.len += 1;

            if (self.tail) |tail| {
                tail.next = node;
                node.prev = tail;
                self.tail = node;
            } else {
                self.tail = node;
                self.head = node;
            }
        }

        pub fn prepend(self: *Self, item: T) !void {
            var node = try self.allocator.create(Node);
            errdefer self.allocator.destroy(node);
            node.* = Node{ .value = item, .prev = null, .next = null };

            if (self.head) |head| {
                node.next = head;
                head.prev = node;
            }

            if (self.tail == null) {
                self.tail = node;
            }

            self.head = node;
            self.len += 1;
        }

        pub fn insert_at(self: *Self, item: T, index: usize) !void {
            if (index > self.len or self.head == null) return error.OutOfBounds;
            if (index == 0) return self.prepend(item);
            if (index == self.len) return self.append(item);

            var node = self.head.?;
            for (0..index) |_| {
                if (node.next) |next| {
                    node = next;
                }
            }

            var new_node = try self.allocator.create(Node);
            errdefer self.allocator.destroy(new_node);
            new_node.* = Node{ .value = item, .next = null, .prev = null };

            if (node.prev) |prev| {
                prev.next = new_node;
                new_node.prev = prev;
            }

            node.prev = new_node;
            new_node.next = node;

            self.len += 1;
        }

        pub fn remove(self: *Self, item: T) ?T {
            if (self.len <= 0) return null;
            if (self.head == null and self.tail == null) return null;

            var current = self.head.?;
            for (0..self.len) |_| {
                if (current.value == item) {
                    break;
                }
                if (current.next) |next| {
                    current = next;
                } else return null;
            }
            defer self.allocator.destroy(current);

            self.len -= 1;

            return self.remove_node(current);
        }

        pub fn remove_at(self: *Self, index: usize) ?T {
            if (self.len <= 0) return null;
            if (self.head == null and self.tail == null) return null;

            var current = self.head.?;
            for (0..index) |_| {
                if (current.next) |next| {
                    current = next;
                } else return null;
            }
            defer self.allocator.destroy(current);

            self.len -= 1;

            return self.remove_node(current);
        }

        fn remove_node(self: *Self, node: *Node) ?T {
            if (node.prev) |prev| {
                if (node.next) |next| {
                    prev.next = next;
                    next.prev = prev;
                } else {
                    self.tail = prev;
                    prev.next = null;
                }
            } else {
                if (node.next) |next| {
                    self.head = next;
                    next.prev = null;
                } else {
                    self.head = null;
                    self.tail = null;
                }
            }

            return node.value;
        }

        pub fn get(self: *Self, index: usize) ?T {
            if (self.len <= 0) return null;
            if (self.head == null and self.tail == null) return null;
            if (index >= self.len) return null;

            var current = self.head.?;
            for (0..index) |_| {
                if (current.next) |next| {
                    current = next;
                }
            }

            return current.value;
        }
    };
}

test "Doubly linked list" {
    const allocator = std.testing.allocator;
    var linked_list = DoublyLinkedList(u16).init(allocator);
    defer linked_list.deinit();

    try std.testing.expectEqual(null, linked_list.head);

    try linked_list.prepend(7);
    try std.testing.expectEqual(7, linked_list.head.?.value);
    try std.testing.expectEqual(1, linked_list.len);
}

test "Doubly linked list insert_at" {
    const allocator = std.testing.allocator;
    var linked_list = DoublyLinkedList(u16).init(allocator);
    defer linked_list.deinit();

    try std.testing.expectEqual(null, linked_list.head);
    try std.testing.expectEqual(null, linked_list.tail);
    try std.testing.expectEqual(0, linked_list.len);

    try linked_list.prepend(8);
    try std.testing.expectEqual(8, linked_list.head.?.value);
    try std.testing.expectEqual(8, linked_list.tail.?.value);
    try std.testing.expectEqual(1, linked_list.len);

    try linked_list.prepend(7);
    try std.testing.expectEqual(7, linked_list.head.?.value);
    try std.testing.expectEqual(8, linked_list.tail.?.value);
    try std.testing.expectEqual(2, linked_list.len);

    try linked_list.prepend(6);
    try std.testing.expectEqual(6, linked_list.head.?.value);
    try std.testing.expectEqual(8, linked_list.tail.?.value);
    try std.testing.expectEqual(3, linked_list.len);

    try linked_list.insert_at(9, 1);
    try std.testing.expectEqual(6, linked_list.head.?.value);
    try std.testing.expectEqual(8, linked_list.tail.?.value);
    try std.testing.expectEqual(4, linked_list.len);

    try std.testing.expectEqual(9, linked_list.head.?.next.?.value);
}

test "Doubly linked list insert_at out of bounds" {
    const allocator = std.testing.allocator;
    var linked_list = DoublyLinkedList(u16).init(allocator);
    defer linked_list.deinit();

    try std.testing.expectEqual(null, linked_list.head);
    try std.testing.expectEqual(0, linked_list.len);

    try std.testing.expectError(error.OutOfBounds, linked_list.insert_at(9, 10));

    try linked_list.prepend(6);
    try std.testing.expectError(error.OutOfBounds, linked_list.insert_at(9, 10));
}

test "Doubly linked list append" {
    const allocator = std.testing.allocator;
    var linked_list = DoublyLinkedList(u16).init(allocator);
    defer linked_list.deinit();

    try std.testing.expectEqual(null, linked_list.head);
    try std.testing.expectEqual(0, linked_list.len);

    try linked_list.append(6);
    try std.testing.expectEqual(1, linked_list.len);
    try std.testing.expectEqual(6, linked_list.head.?.value);
    try std.testing.expectEqual(6, linked_list.tail.?.value);

    try linked_list.append(7);
    try std.testing.expectEqual(2, linked_list.len);
    try std.testing.expectEqual(6, linked_list.head.?.value);
    try std.testing.expectEqual(7, linked_list.tail.?.value);

    try linked_list.append(8);
    try std.testing.expectEqual(3, linked_list.len);
    try std.testing.expectEqual(6, linked_list.head.?.value);
    try std.testing.expectEqual(8, linked_list.tail.?.value);
}

test "Doubly linked list remove at the middle" {
    const allocator = std.testing.allocator;
    var linked_list = DoublyLinkedList(u16).init(allocator);
    defer linked_list.deinit();

    try std.testing.expectEqual(null, linked_list.head);
    try std.testing.expectEqual(0, linked_list.len);

    try linked_list.append(1);
    try linked_list.append(2);
    try linked_list.append(3);
    try std.testing.expectEqual(3, linked_list.len);

    const removed = linked_list.remove(2);
    try std.testing.expectEqual(2, linked_list.len);
    try std.testing.expectEqual(2, removed.?);
    try std.testing.expectEqual(1, linked_list.head.?.value);
    try std.testing.expectEqual(3, linked_list.tail.?.value);
}

test "Doubly linked list remove at start" {
    const allocator = std.testing.allocator;
    var linked_list = DoublyLinkedList(u16).init(allocator);
    defer linked_list.deinit();

    try std.testing.expectEqual(null, linked_list.head);
    try std.testing.expectEqual(0, linked_list.len);

    try linked_list.append(1);
    try linked_list.append(2);
    try std.testing.expectEqual(2, linked_list.len);

    const removed = linked_list.remove(1);
    try std.testing.expectEqual(1, linked_list.len);
    try std.testing.expectEqual(1, removed.?);

    try std.testing.expectEqual(2, linked_list.head.?.value);
    try std.testing.expectEqual(2, linked_list.tail.?.value);
}

test "Doubly linked list remove at end" {
    const allocator = std.testing.allocator;
    var linked_list = DoublyLinkedList(u16).init(allocator);
    defer linked_list.deinit();

    try std.testing.expectEqual(null, linked_list.head);
    try std.testing.expectEqual(0, linked_list.len);

    try linked_list.append(1);
    try linked_list.append(2);
    try std.testing.expectEqual(2, linked_list.len);

    const removed = linked_list.remove(2);
    try std.testing.expectEqual(1, linked_list.len);
    try std.testing.expectEqual(2, removed.?);

    try std.testing.expectEqual(1, linked_list.head.?.value);
    try std.testing.expectEqual(1, linked_list.tail.?.value);
}

test "Doubly linked list remove only one item" {
    const allocator = std.testing.allocator;
    var linked_list = DoublyLinkedList(u16).init(allocator);
    defer linked_list.deinit();

    try std.testing.expectEqual(null, linked_list.head);
    try std.testing.expectEqual(0, linked_list.len);

    try linked_list.append(1);
    try std.testing.expectEqual(1, linked_list.len);

    const removed = linked_list.remove(1);
    try std.testing.expectEqual(0, linked_list.len);
    try std.testing.expectEqual(1, removed.?);

    try std.testing.expectEqual(null, linked_list.head);
    try std.testing.expectEqual(null, linked_list.tail);
}

test "Doubly linked list remove empty" {
    const allocator = std.testing.allocator;
    var linked_list = DoublyLinkedList(u16).init(allocator);
    defer linked_list.deinit();

    try std.testing.expectEqual(null, linked_list.head);
    try std.testing.expectEqual(0, linked_list.len);

    const removed = linked_list.remove(1);
    try std.testing.expectEqual(0, linked_list.len);
    try std.testing.expectEqual(null, removed);
    try std.testing.expectEqual(null, linked_list.head);
    try std.testing.expectEqual(null, linked_list.tail);
}

test "Doubly linked list remove at" {
    const allocator = std.testing.allocator;
    var linked_list = DoublyLinkedList(u16).init(allocator);
    defer linked_list.deinit();

    try linked_list.append(12);
    try linked_list.append(13);
    try linked_list.append(14);
    try linked_list.append(15);
    try linked_list.append(16);
    try linked_list.append(17);
    try std.testing.expectEqual(6, linked_list.len);

    const val = linked_list.remove_at(2);
    try std.testing.expectEqual(5, linked_list.len);
    try std.testing.expectEqual(14, val.?);
}

test "Doubly linked list deinit" {
    const allocator = std.testing.allocator;
    var linked_list = DoublyLinkedList(u16).init(allocator);

    try linked_list.append(12);
    try linked_list.append(13);
    try linked_list.append(14);
    try linked_list.append(15);
    try linked_list.append(16);
    try linked_list.append(17);
    try std.testing.expectEqual(6, linked_list.len);

    linked_list.deinit();

    try std.testing.expectEqual(0, linked_list.len);
    try std.testing.expectEqual(null, linked_list.head);
    try std.testing.expectEqual(null, linked_list.tail);
}
