const std = @import("std");

const c = @cImport({
    @cInclude("lua.h");
    @cInclude("lualib.h");
    @cInclude("lauxlib.h");
    @cInclude("luajit.h");
});

const State = struct {
    l: *c.lua_State,

    const Self = @This();

    pub fn init() !Self {
        if (c.luaL_newstate()) |l| {
            c.luaL_openlibs(l);
            return .{ .l = l };
        }
        return error.FailedNewState;
    }

    pub fn deinit(self: *const Self) void {
        c.lua_close(self.l);
    }

    pub fn runFile(self: *const Self, path: [*:0]const u8) !void {
        if (c.luaL_loadfile(self.l, path) != 0) {
            return error.FailedLoad;
        }
        if (c.lua_pcall(self.l, 0, 0, 0) != 0) {
            return error.FailedCall;
        }
    }
};

pub fn main() !void {
    if (std.os.argv.len > 1) {
        const s = try State.init();
        defer s.deinit();
        try s.runFile(std.os.argv[1]);
    } else {
        std.debug.print("lua file not provided\n", .{});
    }
}
