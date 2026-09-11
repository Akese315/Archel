-- Add the daemons and apps you want to start at Hyprland launch.
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("hyprpaper")
end)
