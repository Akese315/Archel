local programs = require("modules.programs")

hl.bind("ALT + T", hl.dsp.exec_cmd(programs.terminal))
hl.bind("ALT + E", hl.dsp.exec_cmd(programs.fileManager))
hl.bind("ALT + R", hl.dsp.exec_cmd(programs.menu))
hl.bind("ALT + B", hl.dsp.exec_cmd(programs.browser))
hl.bind("ALT + Z", hl.dsp.exec_cmd(programs.zed))
hl.bind("SUPER + L", hl.dsp.exec_cmd(programs.hyprlock))