const std = @import("std");

pub fn Hashmap(comptime T: type) type {
    const Bucket = struct {
        key: []u8,
        value: T,
    };

    return struct {
        const Self = @This();

        array: []?Bucket,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) !Self {
            const array = try allocator.alloc(?Bucket, 10);
            errdefer allocator.free(array);
            @memset(array, null);
            return .{ .array = array, .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            defer self.allocator.free(self.array);
            for (self.array) |bucket| {
                if (bucket) |b| {
                    self.allocator.free(b.key);
                }
            }
        }

        pub fn key_to_index(self: *Self, key: []const u8) !usize {
            var count: u32 = 0;
            for (key) |char| {
                const ascii: u8 = @intCast(char);
                count += ascii;
            }

            return count % self.array.len;
        }

        pub fn insert(self: *Self, key: []const u8, value: T) !void {
            const key_buffer = try self.allocator.alloc(u8, key.len);
            errdefer self.allocator.free(key_buffer);

            @memcpy(key_buffer, key);
            const bucket = Bucket{ .value = value, .key = key_buffer };

            const index = try self.key_to_index(key);
            self.array[index] = bucket;
        }

        pub fn get(self: *Self, key: []const u8) !T {
            const index = try self.key_to_index(key);
            if (self.array[index]) |bucket| {
                return bucket.value;
            } else {
                return error.KeyNotFound;
            }
        }
    };
}

test "It should work" {
    const allocator = std.testing.allocator;

    var hashmap = try Hashmap(u16).init(allocator);
    defer hashmap.deinit();
    const index = try hashmap.key_to_index("A");
    std.debug.print("\nindex: {d}\n\n", .{index});

    try hashmap.insert("hello", 12);
    const value = try hashmap.get("hello");

    try std.testing.expectEqual(12, value);
    try std.testing.expectError(error.KeyNotFound, hashmap.get("invalidKey"));
}
