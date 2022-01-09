const std = @import("std");
const c = @import("internal/c.zig");
const internal = @import("internal/internal.zig");
const log = std.log.scoped(.git);

const git = @import("git.zig");

pub const Pathspec = opaque {
    /// Compile a pathspec
    ///
    /// ## Parameters
    /// * `pathspec` - a `git.StrArray` of the paths to match
    pub fn new(pathspec: git.StrArray) !*Pathspec {
        log.debug("Pathspec.new called", .{});

        var ret: *Pathspec = undefined;

        try internal.wrapCall("git_pathspec_new", .{
            @ptrCast(*?*c.git_pathspec, &ret),
            @ptrCast(*const c.git_strarray, &pathspec),
        });

        log.debug("successfully created pathspec: {*}", .{ret});

        return ret;
    }

    /// Free a pathspec
    pub fn deinit(self: *Pathspec) void {
        log.debug("Pathspec.deinit called", .{});

        c.git_pathspec_free(@ptrCast(*c.git_pathspec, self));

        log.debug("pathspec freed successfully", .{});
    }

    /// Try to match a path against a pathspec
    ///
    /// Unlike most of the other pathspec matching functions, this will not fall back on the native case-sensitivity for your
    /// platform. You must explicitly pass options to control case sensitivity or this will fall back on being case sensitive.
    ///
    /// ## Parameters
    /// * `options` - options to control match
    /// * `path` - the pathname to attempt to match
    pub fn matchesPath(self: *const Pathspec, options: MatchOptions, path: [:0]const u8) !bool {
        log.debug("Pathspec.matchesPath called, options: {}, path: {s}", .{ options, path });

        const ret = (try internal.wrapCallWithReturn("git_pathspec_matches_path", .{
            @ptrCast(*const c.git_pathspec, self),
            @bitCast(c.git_pathspec_flag_t, options),
            path.ptr,
        })) != 0;

        log.debug("match: {}", .{ret});

        return ret;
    }

    /// Options controlling how pathspec match should be executed
    pub const MatchOptions = packed struct {
        /// `IGNORE_CASE` forces match to ignore case; otherwise match will use native case sensitivity of platform filesystem
        IGNORE_CASE: bool = false,

        /// `USE_CASE` forces case sensitive match; otherwise match will use native case sensitivity of platform filesystem
        USE_CASE: bool = false,

        /// `NO_GLOB` disables glob patterns and just uses simple string comparison for matching
        NO_GLOB: bool = false,

        /// `NO_MATCH_ERROR` means the match functions return error `GitError.NotFound` if no matches are found; otherwise no
        /// matches is still success (return 0) but `PathspecMatchList.entryCount` will indicate 0 matches.
        NO_MATCH_ERROR: bool = false,

        /// `FIND_FAILURES` means that the `PathspecMatchList` should track which patterns matched which files so that at the end of
        /// the match we can identify patterns that did not match any files.
        FIND_FAILURES: bool = false,

        /// FAILURES_ONLY means that the `PathspecMatchList` does not need to keep the actual matching filenames.
        /// Use this to just test if there were any matches at all or in combination with `FIND_FAILURES` to validate a pathspec.
        FAILURES_ONLY: bool = false,

        z_padding: u26 = 0,

        pub fn format(
            value: MatchOptions,
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
            try std.testing.expectEqual(@sizeOf(c.git_pathspec_flag_t), @sizeOf(MatchOptions));
            try std.testing.expectEqual(@bitSizeOf(c.git_pathspec_flag_t), @bitSizeOf(MatchOptions));
        }

        comptime {
            std.testing.refAllDecls(@This());
        }
    };

    comptime {
        std.testing.refAllDecls(@This());
    }
};

/// list of filenames matching a pathspec
pub const PathspecMatchList = opaque {
    /// Free a pathspec match list
    pub fn deinit(self: *PathspecMatchList) void {
        log.debug("PathspecMatchList.deinit called", .{});

        c.git_pathspec_match_list_free(@ptrCast(*c.git_pathspec_match_list, self));

        log.debug("pathspec match list freed successfully", .{});
    }

    /// Get the number of items in a match list.
    pub fn entryCount(self: *const PathspecMatchList) usize {
        log.debug("PathspecMatchList.entryCount called", .{});

        const ret = c.git_pathspec_match_list_entrycount(
            @ptrCast(*const c.git_pathspec_match_list, self),
        );

        log.debug("entry count: {}", .{ret});

        return ret;
    }

    /// Get a matching filename by position.
    ///
    /// This routine cannot be used if the match list was generated by `Diff.pathspecMatch`. If so, it will always return `null`.
    ///
    /// ## Parameters
    /// * `index` - the index into the list
    pub fn getEntry(self: *const PathspecMatchList, index: usize) ?[:0]const u8 {
        log.debug("PathspecMatchList.getEntry called, index: {}", .{index});

        const opt_c_ptr = c.git_pathspec_match_list_entry(
            @ptrCast(*const c.git_pathspec_match_list, self),
            index,
        );

        if (opt_c_ptr) |c_ptr| {
            const slice = std.mem.sliceTo(c_ptr, 0);
            log.debug("entry: {s}", .{slice});
            return slice;
        } else {
            log.debug("no such match", .{});
            return null;
        }
    }

    /// Get a matching diff delta by position.
    ///
    /// This routine can only be used if the match list was generated by `Diff.pathspecMatch`.
    /// Otherwise it will always return `null`.
    ///
    /// ## Parameters
    /// * `index` - the index into the list
    pub fn getDiffEntry(self: *const PathspecMatchList, index: usize) ?*const git.DiffDelta {
        log.debug("PathspecMatchList.getDiffEntry called, index: {}", .{index});

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
    /// This will be zero unless you passed `MatchOptions.FIND_FAILURES` when generating the `PathspecMatchList`.
    pub fn failedEntryCount(self: *const PathspecMatchList) usize {
        log.debug("PathspecMatchList.failedEntryCount called", .{});

        const ret = c.git_pathspec_match_list_failed_entrycount(
            @ptrCast(*const c.git_pathspec_match_list, self),
        );

        log.debug("non-matching entry count: {}", .{ret});

        return ret;
    }

    /// Get an original pathspec string that had no matches.
    ///
    /// This will be return `null` for positions out of range.
    ///
    /// ## Parameters
    /// * `index` - the index into the failed items
    pub fn getFailedEntry(self: *const PathspecMatchList, index: usize) ?[:0]const u8 {
        log.debug("PathspecMatchList.getFailedEntry called, index: {}", .{index});

        const opt_c_ptr = c.git_pathspec_match_list_failed_entry(
            @ptrCast(*const c.git_pathspec_match_list, self),
            index,
        );

        if (opt_c_ptr) |c_ptr| {
            const slice = std.mem.sliceTo(c_ptr, 0);
            log.debug("entry: {s}", .{slice});
            return slice;
        } else {
            log.debug("no such failed match", .{});
            return null;
        }
    }

    comptime {
        std.testing.refAllDecls(@This());
    }
};

comptime {
    std.testing.refAllDecls(@This());
}
