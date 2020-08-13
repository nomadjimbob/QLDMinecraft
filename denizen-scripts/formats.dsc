# File:     formats.dsc
# Contains: Text formats
# Package:  QLD Minecraft
# Version:  Season 1 (012)
# URL:      http://play.qldminecraft.com.au/

# Notices for players
notice:
    type: format
    format: <&e><text>

# Player chat (handled by ChatManager). Player NPC Engagement in dnenizen config.yml
player:
    type: format
    format: "<&f>[<player.name>]: <text>"

developer:
    type: format
    format: "<&d>[<player.name>]: <text>"

# NPC
npc:
    type: format
    format: "<&f>[<npc.name>]: <text>"

npc_action:
    type: format
    format: "<&f><npc.name> <text>"

# Channel notices (NPC hit|miss, channel left|joined|changed)
channel:
    type: format
    format: <&d><text>

# Hit|Miss messages
action_battle:
    type: format
    format: <&d><text>

# NPC actions
action_npc:
    type: format
    format: <&f><text>

# NPC announce
announce_npc:
    type: format
    format: "<&e><npc.name> says: <text>"

# Server alert
server:
    type: format
    format: "<&e>[SERVER] <text>"

# Actionbar
change_town:
    type: format
    format: "<&e><text>"

change_survival:
    type: format
    format: "<&f><text>"

change_creative:
    type: format
    format: "<&a><text>"

change_pvp:
    type: format
    format: "<&c><text>"

change_restricted:
    type: format
    format: "<&d><text>"

# Debugger
debug:
    type: format
    format: "<&3>[DEBUG] <text>"