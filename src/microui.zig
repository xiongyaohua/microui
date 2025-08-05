const std = @import("std");
const c = @cImport(@cInclude("microui.h"));

const assert = std.debug.assert;
const Context = c.mu_Context;
const Command = c.mu_Command;

export fn mu_push_command(ctx: *Context, @"type": c_int, size: c_int) *Command {
    assert(ctx.command_list.idx + size < ctx.command_list.items.len);

    // std.debug.print("{}, {} \n", .{ size, ctx.command_list.idx });
    const cmd_addr = @intFromPtr(&ctx.command_list.items[@intCast(ctx.command_list.idx)]);
    const cmd: *Command = @ptrFromInt(cmd_addr);
    cmd.base.type = @"type";
    cmd.base.size = size;
    ctx.command_list.idx += size;
    return cmd;
}

export fn mu_next_command(ctx: *Context, cmd: *?*Command) c_int {
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
