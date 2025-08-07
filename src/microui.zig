const std = @import("std");
const c = @cImport(@cInclude("microui.h"));

const assert = std.debug.assert;
const MuContext = c.mu_Context;
const MuCommand = c.mu_Command;

const FnTextWidth = fn (c.mu_Font, [*:0]const u8, c_int) callconv(.c) c_int;
const FnTextHeight = fn (c.mu_Font) callconv(.c) c_int;
const FnDrawFrame = fn (*c.mu_Context, c.mu_Rect, c_int) callconv(.c) void;

comptime {
    _ = patch; // So that patch is evaluated and functions are exported.
}

const patch = struct {
    //! Patch the c implementation with some zig code.

    /// Push draw command into a buffer.
    export fn mu_push_command(ctx: *MuContext, @"type": c_int, size: c_int) *MuCommand {
        assert(ctx.command_list.idx + size < ctx.command_list.items.len);

        // std.debug.print("{}, {} \n", .{ size, ctx.command_list.idx });
        const cmd_addr = @intFromPtr(&ctx.command_list.items[@intCast(ctx.command_list.idx)]);
        const cmd: *MuCommand = @ptrFromInt(cmd_addr);
        cmd.base.type = @"type";
        cmd.base.size = size;
        ctx.command_list.idx += size;
        return cmd;
    }

    /// Iterate draw commands.
    export fn mu_next_command(ctx: *MuContext, cmd: *?*MuCommand) c_int {
        // Move to next command if pointing to a command. If not, move
        // to the first command.
        if (cmd.* != null) {
            cmd.* = @ptrFromInt(@intFromPtr(cmd.*) + @as(usize, @intCast(cmd.*.?.base.size)));
        } else {
            cmd.* = @ptrFromInt(@intFromPtr(&ctx.command_list.items[0]));
        }

        while (@intFromPtr(cmd.*) < @intFromPtr(&ctx.command_list.items[@intCast(ctx.command_list.idx)])) {
            if (cmd.*.?.type != c.MU_COMMAND_JUMP) {
                return 1;
            }
            cmd.* = @ptrCast(@alignCast(cmd.*.?.jump.dst));
        }

        return 0;
    }
};

/// Zig wraper for mu_Context. Stage 1.
const Context = struct {
    inner: c.mu_Context,

    const Self = @This();
    pub fn init(text_width: *const FnTextHeight, text_height: *const FnTextHeight, draw_frame: ?*const FnDrawFrame) Self {
        var self: Self = undefined;
        c.mu_init(&self.inner);
        self.inner.text_width = text_width;
        self.inner.text_height = text_height;
        self.inner.draw_frame = draw_frame;
        return self;
    }

    pub fn injectStage(self: Self) InjectStage {
        const stage: InjectStage = .{ .ctx = &self.inner };
        return stage;
    }
};

/// Stage 2
const InjectStage = struct {
    ctx: *c.mu_Context,

    const Self = @This();

    pub fn mouseMove(self: Self, x: c_int, y: c_int) Self {
        c.mu_input_mousemove(self.ctx, x, y);
        return self;
    }

    pub fn mouseDown(self: Self, x: c_int, y: c_int, btn: c_int) Self {
        c.mu_input_mousedown(self.ctx, x, y, btn);
        return self;
    }

    pub fn mouseUp(self: Self, x: c_int, y: c_int, btn: c_int) Self {
        c.mu_input_mouseup(self.ctx, x, y, btn);
        return self;
    }

    pub fn scroll(self: Self, x: c_int, y: c_int) Self {
        c.mu_input_scroll(self.ctx, x, y);
        return self;
    }

    pub fn keyDown(self: Self, key: c_int) Self {
        c.mu_input_keydown(self.ctx, key);
        return self;
    }

    pub fn keyUp(self: Self, key: c_int) Self {
        c.mu_input_keyup(self.ctx, key);
        return self;
    }

    pub fn text(self: Self, content: [*:0]const u8) Self {
        c.mu_input_text(self.ctx, content);
        return self;
    }
};
