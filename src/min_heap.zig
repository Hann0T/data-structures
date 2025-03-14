const std = @import("std");

pub fn MinHeap(comptime T: type) type {
    return struct {
        const Self = @This();

        length: usize,
        data: std.ArrayList(T),
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            var data = std.ArrayList(T).init(allocator);
            errdefer data.deinit();

            return .{ .data = data, .length = 0, .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            self.data.deinit();
        }

        pub fn insert(self: *Self, value: T) !void {
            try self.data.append(value);
            self.heapify_up(self.length);
            self.length += 1;
        }

        // another name should be "pop", because is a Priority queue
        pub fn delete(self: *Self) !T {
            if (self.length == 0) {
                return error.EmptyHeap;
            }

            const current_value = self.data.items[0];
            const last_value = self.data.items[self.length - 1];

            self.data.items[0] = last_value;
            self.data.items[self.length - 1] = current_value;

            _ = self.data.pop();

            self.length -= 1;
            self.heapify_down(0);

            return current_value;
        }

        pub fn heapify_up(self: *Self, index: usize) void {
            if (index == 0 or index >= self.length) {
                return;
            }

            const parent_index = parent(index);

            const current_value = self.data.items[index];
            const parent_value = self.data.items[parent_index];

            if (parent_value > current_value) {
                self.data.items[index] = parent_value;
                self.data.items[parent_index] = current_value;
                self.heapify_up(parent_index);
            }
        }

        pub fn heapify_down(self: *Self, index: usize) void {
            if (index >= self.length) {
                return;
            }

            const left_child_index = left_child(index);
            const right_child_index = right_child(index);

            if (left_child_index >= self.length or right_child_index >= self.length) {
                return;
            }

            const left = self.data.items[left_child_index];
            const right = self.data.items[right_child_index];
            const value = self.data.items[index];

            if (left > right and right < value) {
                self.data.items[right_child_index] = value;
                self.data.items[index] = right;
                self.heapify_down(right_child_index);
            } else if (right > left and left < value) {
                self.data.items[left_child_index] = value;
                self.data.items[index] = left;
                self.heapify_down(left_child_index);
            }
        }

        pub fn parent(index: usize) usize {
            return (index - 1) / 2;
        }

        pub fn left_child(index: usize) usize {
            return index * 2 + 1;
        }

        pub fn right_child(index: usize) usize {
            return index * 2 + 2;
        }
    };
}

test "it should work" {
    const allocator = std.testing.allocator;
    var heap = MinHeap(i32).init(allocator);
    defer heap.deinit();

    try std.testing.expectEqual(0, heap.length);

    try heap.insert(1);
    try heap.insert(10);
    try heap.insert(40);
    try heap.insert(20);
    try heap.insert(30);

    try std.testing.expectEqual(5, heap.length);
    try std.testing.expectEqual(1, try heap.delete());
    try std.testing.expectEqual(10, try heap.delete());
    try std.testing.expectEqual(20, try heap.delete());
    try std.testing.expectEqual(40, try heap.delete());
    try std.testing.expectEqual(30, try heap.delete());
    try std.testing.expectEqual(0, heap.length);
    try std.testing.expectError(error.EmptyHeap, heap.delete());
    try std.testing.expectEqual(0, heap.length);
}
