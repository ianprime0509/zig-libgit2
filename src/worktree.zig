const std = @import("std");
const raw = @import("internal/raw.zig");
const internal = @import("internal/internal.zig");
const log = std.log.scoped(.git);

const git = @import("git.zig");

pub const Worktree = opaque {
    pub fn deinit(self: *Worktree) void {
        log.debug("Worktree.deinit called", .{});

        raw.git_worktree_free(@ptrCast(*raw.git_worktree, self));

        log.debug("worktree freed successfully", .{});
    }

    pub fn repositoryOpen(self: *Worktree) !*git.Repository {
        log.debug("Worktree.repositoryOpen called", .{});

        var repo: *git.Repository = undefined;

        try internal.wrapCall("git_repository_open_from_worktree", .{
            @ptrCast(*?*raw.git_repository, &repo),
            @ptrCast(*raw.git_worktree, self),
        });

        log.debug("repository opened successfully", .{});

        return repo;
    }

    comptime {
        std.testing.refAllDecls(@This());
    }
};

comptime {
    std.testing.refAllDecls(@This());
}
