const std = @import("std");
const print = std.debug.print;

pub fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();
        items: ?std.ArrayList(T),
        allocator: std.mem.Allocator,
        len: usize,

        pub fn init(allocator: std.mem.Allocator) Stack(T) {
            return .{
                .len = 0,
                .items = null,
                .allocator = allocator,
            };
        }

        pub fn init_items(self: *Self) void {
            if (self.items == null) {
                self.items = std.ArrayList(T).init(self.allocator);
            }
        }

        pub fn deinit(self: Self) void {
            if (self.items) |items| {
                items.deinit();
            }
        }

        pub fn push(self: *Self, item: T) !void {
            self.init_items();

            if (self.items) |*items| {
                try items.append(item);
                self.len += 1;
            }
        }

        pub fn pop(self: *Self) ?T {
            if (self.len <= 0 or self.items == null) return null;

            if (self.items) |*items| {
                self.len -= 1;
                return items.pop();
            }

            return null;
        }
    };
}

test "Stack test" {
    const allocator = std.testing.allocator;

    var my_stack = Stack(u16).init(allocator);
    defer my_stack.deinit();

    const x = my_stack.pop();
    try std.testing.expectEqual(null, x);

    try my_stack.push(8);
    try my_stack.push(16);
    try my_stack.push(32);
    try my_stack.push(64);
    try std.testing.expectEqual(my_stack.len, 4);

    try std.testing.expectEqual(my_stack.pop().?, 64);
    try std.testing.expectEqual(my_stack.pop().?, 32);
    try std.testing.expectEqual(my_stack.pop().?, 16);
    try std.testing.expectEqual(my_stack.pop().?, 8);

    try std.testing.expectEqual(my_stack.len, 0);
}
