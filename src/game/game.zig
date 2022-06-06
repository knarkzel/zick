const c = @import("../ogc/c.zig");
const Video = @import("../ogc/Video.zig");
const Texture = @import("../ogc/Texture.zig");
const Pad = @import("../ogc/Pad.zig");
const utils = @import("../ogc/utils.zig");

const Player = struct {
    const State = union(enum) {
        regular,
        dash: struct {
            time_left: u32,
            direction: f32,
        },
    };

    x: f32,
    y: f32,
    velocity: f32,
    state: State,

    fn init(x: f32, y: f32) Player {
        return Player{ .x = x, .y = y, .velocity = 0, .state = .regular };
    }

    fn setState(self: *Player, state: State) void {
        self.*.state = state;
    }
};

pub fn run(video: *Video) void {
    // Texture
    var texture = Texture.init();
    texture.load_tpl("textures/textures.tpl");

    // Players
    var players: [4]?Player = .{null} ** 4;

    while (true) {
        // Handle new players
        for (Pad.update()) |controller, i| {
            if (controller and players[i] == null) players[i] = Player.init(128, 32);
        }

        video.start();

        // Players logic
        const colors = [4]utils.Rectangle{
            utils.rectangle(0, 0, 0.5, 0.5),
            utils.rectangle(0, 0.5, 0.5, 0.5),
            utils.rectangle(0.5, 0, 0.5, 0.5),
            utils.rectangle(0.5, 0.5, 0.5, 0.5),
        };

        for (players) |*object, i| {
            if (object.*) |*player| {
                // Exit
                if (Pad.button_down(.start, i)) return;

                // Bounds
                if (player.*.x > 640) player.*.x = -64;
                if (player.*.x + 64 < 0) player.*.x = 640;
                const speed: f32 = if (Pad.button_held(.b, i)) 15 else 10;

                // Graphics
                var coords = colors[0]; // Idle animation
                const points = utils.rectangle(player.x, player.y, 64, 64);

                // States
                switch (player.*.state) {
                    .regular => {
                        // Sprites
                        if (player.*.velocity < 0) coords = colors[2]; // Falling animation
                        if (player.*.velocity > 0) coords = colors[3]; // Jumping animation

                        // Movement
                        const stick_x = Pad.stick_x(i);
                        player.*.x += stick_x * speed;

                        // Jumping
                        if (player.*.velocity > -6) player.*.velocity -= 0.25;
                        if (player.*.y + 64 > 480) player.*.velocity = 0;
                        if (Pad.button_down(.a, i)) {
                            const jump = @embedFile("audio/jump.mp3");
                            c.MP3Player_Stop();
                            _ = c.MP3Player_PlayBuffer(jump, jump.len, null);
                            player.*.velocity = speed;
                        }
                        player.*.y -= player.*.velocity;

                        // Dash
                        if (Pad.button_down(.y, i)) {
                            const dash = @embedFile("audio/dash.mp3");
                            c.MP3Player_Stop();
                            _ = c.MP3Player_PlayBuffer(dash, dash.len, null);
                            player.*.velocity = 0;
                            const direction: f32 = if (stick_x > 0) 1 else -1;
                            player.setState(.{ .dash = .{ .time_left = 10, .direction = direction } });
                        }
                    },
                    .dash => |*dash| {
                        // Sprites
                        coords = colors[1]; // Dash animation

                        // Movement
                        player.*.x += speed * dash.*.direction * 1.5;
                        dash.*.time_left -= 1;
                        if (dash.*.time_left == 0) player.setState(.regular);
                    },
                }
                utils.texture(points, coords);
            }
        }

        video.finish();
    }
}