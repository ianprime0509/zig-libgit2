const std = @import("std");
const c = @import("internal/c.zig");
const internal = @import("internal/internal.zig");
const log = std.log.scoped(.git);

const git = @import("git.zig");

/// Array of object ids
pub const OidArray = extern struct {
    ids: [*]git.Oid,
    count: usize,

    /// Free the OID array
    ///
    /// This method must (and must only) be called on `OidArray` objects where the array is allocated by the library.
    /// Not doing so, will result in a memory leak.
    pub fn deinit(self: *OidArray) void {
        log.debug("OidArray.deinit called", .{});

        c.git_oidarray_free(@ptrCast(*c.git_oidarray, self));

        log.debug("Oid array freed successfully", .{});
    }

    test {
        try std.testing.expectEqual(@sizeOf(c.git_oidarray), @sizeOf(OidArray));
        try std.testing.expectEqual(@bitSizeOf(c.git_oidarray), @bitSizeOf(OidArray));
    }

    comptime {
        std.testing.refAllDecls(@This());
    }
};

comptime {
    std.testing.refAllDecls(@This());
}
