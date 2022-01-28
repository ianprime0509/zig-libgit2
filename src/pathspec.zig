const std = @import("std");
const c = @import("internal/c.zig");
const internal = @import("internal/internal.zig");
const log = std.log.scoped(.git);

const git = @import("git.zig");

pub const Pathspec = opaque {
    /// Free a pathspec
    pub fn deinit(self: *Pathspec) void {
        if (internal.trace_log) log.debug("Pathspec.deinit called", .{});

        c.git_pathspec_free(@ptrCast(*c.git_pathspec, self));
    }

    /// Try to match a path against a pathspec
    ///
    /// Unlike most of the other pathspec matching functions, this will not fall back on the native case-sensitivity for your
    /// platform. You must explicitly pass options to control case sensitivity or this will fall back on being case sensitive.
    ///
    /// ## Parameters
    /// * `options` - Options to control match
    /// * `path` - The pathname to attempt to match
    pub fn matchesPath(self: *const Pathspec, options: PathspecMatchOptions, path: [:0]const u8) !bool {
        if (internal.trace_log) log.debug("Pathspec.matchesPath called", .{});

        return (try internal.wrapCallWithReturn("git_pathspec_matches_path", .{
            @ptrCast(*const c.git_pathspec, self),
            @bitCast(c.git_pathspec_flag_t, options),
            path.ptr,
        })) != 0;
    }

    comptime {
        std.testing.refAllDecls(@This());
    }
};

/// Options controlling how pathspec match should be executed
pub const PathspecMatchOptions = packed struct {
    /// `ignore_case` forces match to ignore case; otherwise match will use native case sensitivity of platform filesystem
    ignore_case: bool = false,

    /// `use_case` forces case sensitive match; otherwise match will use native case sensitivity of platform filesystem
    use_case: bool = false,

    /// `no_glob` disables glob patterns and just uses simple string comparison for matching
    no_glob: bool = false,

    /// `no_match_error` means the match functions return error `GitError.NotFound` if no matches are found; otherwise no
    /// matches is still success (return 0) but `PathspecMatchList.entryCount` will indicate 0 matches.
    no_match_error: bool = false,

    /// `find_failures` means that the `PathspecMatchList` should track which patterns matched which files so that at the end of
    /// the match we can identify patterns that did not match any files.
    find_failures: bool = false,

    /// failures_only means that the `PathspecMatchList` does not need to keep the actual matching filenames.
    /// Use this to just test if there were any matches at all or in combination with `find_failures` to validate a pathspec.
    failures_only: bool = false,

    z_padding: u26 = 0,

    pub fn format(
        value: PathspecMatchOptions,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        return internal.formatWithoutFields(
            value,
            options,
            writer,
            &.{"z_padding"},
        );
    }

    test {
        try std.testing.expectEqual(@sizeOf(c.git_pathspec_flag_t), @sizeOf(PathspecMatchOptions));
        try std.testing.expectEqual(@bitSizeOf(c.git_pathspec_flag_t), @bitSizeOf(PathspecMatchOptions));
    }

    comptime {
        std.testing.refAllDecls(@This());
    }
};

/// list of filenames matching a pathspec
pub const PathspecMatchList = opaque {
    /// Free a pathspec match list
    pub fn deinit(self: *PathspecMatchList) void {
        if (internal.trace_log) log.debug("PathspecMatchList.deinit called", .{});

        c.git_pathspec_match_list_free(@ptrCast(*c.git_pathspec_match_list, self));
    }

    /// Get the number of items in a match list.
    pub fn entryCount(self: *const PathspecMatchList) usize {
        if (internal.trace_log) log.debug("PathspecMatchList.entryCount called", .{});

        return c.git_pathspec_match_list_entrycount(
            @ptrCast(*const c.git_pathspec_match_list, self),
        );
    }

    /// Get a matching filename by position.
    ///
    /// This routine cannot be used if the match list was generated by `Diff.pathspecMatch`. If so, it will always return `null`.
    ///
    /// ## Parameters
    /// * `index` - The index into the list
    pub fn getEntry(self: *const PathspecMatchList, index: usize) ?[:0]const u8 {
        if (internal.trace_log) log.debug("PathspecMatchList.getEntry called", .{});

        const opt_c_ptr = c.git_pathspec_match_list_entry(
            @ptrCast(*const c.git_pathspec_match_list, self),
            index,
        );

        return if (opt_c_ptr) |c_ptr| std.mem.sliceTo(c_ptr, 0) else null;
    }

    /// Get a matching diff delta by position.
    ///
    /// This routine can only be used if the match list was generated by `Diff.pathspecMatch`.
    /// Otherwise it will always return `null`.
    ///
    /// ## Parameters
    /// * `index` - The index into the list
    pub fn getDiffEntry(self: *const PathspecMatchList, index: usize) ?*const git.DiffDelta {
        if (internal.trace_log) log.debug("PathspecMatchList.getDiffEntry called", .{});

        return @ptrCast(
            ?*const git.DiffDelta,
            c.git_pathspec_match_list_diff_entry(
                @ptrCast(*const c.git_pathspec_match_list, self),
                index,
            ),
        );
    }

    /// Get the number of pathspec items that did not match.
    ///
    /// This will be zero unless you passed `PathspecMatchOptions.find_failures` when generating the `PathspecMatchList`.
    pub fn failedEntryCount(self: *const PathspecMatchList) usize {
        if (internal.trace_log) log.debug("PathspecMatchList.failedEntryCount called", .{});

        return c.git_pathspec_match_list_failed_entrycount(
            @ptrCast(*const c.git_pathspec_match_list, self),
        );
    }

    /// Get an original pathspec string that had no matches.
    ///
    /// This will be return `null` for positions out of range.
    ///
    /// ## Parameters
    /// * `index` - The index into the failed items
    pub fn getFailedEntry(self: *const PathspecMatchList, index: usize) ?[:0]const u8 {
        if (internal.trace_log) log.debug("PathspecMatchList.getFailedEntry called", .{});

        const opt_c_ptr = c.git_pathspec_match_list_failed_entry(
            @ptrCast(*const c.git_pathspec_match_list, self),
            index,
        );

        return if (opt_c_ptr) |c_ptr| std.mem.sliceTo(c_ptr, 0) else null;
    }

    comptime {
        std.testing.refAllDecls(@This());
    }
};

comptime {
    std.testing.refAllDecls(@This());
}
