# File:     player.dsc
# Contains: Player base handler
# Package:  QLD Minecraft
# Build:    114
# URL:      http://play.qldminecraft.com.au/

player_handler:
    type: world
    debug: true
    events:

        on player joins:
            # Log login with web
            - webget http://play.qldminecraft.com.au/bridge.php 'data:{"cmd":"player_join","player":"<player.uuid>","viaversion":"<player.viaversion>"}' headers:<map.with[Content-Type].as[application/json]>
            
            # Load player data
            - ~run qm_player_yaml_load def:<player>

            - flag player playingStart:<util.time_now.epoch_millis>
            - yaml id:<player.uuid> set logins:++
            - yaml id:<player.uuid> set clientVersion:<player.viaversion>

            # Check [server].login_enabled
            - if <yaml[server].read[login_enabled]||1> == 0 && !<player.in_group[developer]>:
                - kick <player> "reason:<yaml[server].read[login_denied_reason]||Server is currently undergoing maintenance>"
                - stop

            # Check [player].login_enabled
            - if <yaml[<player.uuid>].read[login_enabled]||1> == 0 && !<player.in_group[developer]>:
                - kick <player> "reason:<yaml[player.uuid].read[login_denied_reason]||Account is currently suspended>"
                - stop

            # Update developer permissions
            - if <yaml[<player.uuid>].read[developer]||1>:
                - group add developer
                - group remove default
            - else:
                - group remove developer
                - group add default

            # First login
            - if <yaml[<player.uuid>].read[logins]||1> == 1:
                - flag player region:__default__
                - teleport <yaml[server].read[first_spawn]> <player>

            - flag player npc_engage:!
        

        after player joins:
            # Display MOTD
            - define motd:<yaml[server].read[motd].parsed||null>
            - if <[motd]> != null:
                - narrate format:notice ------------------------------<&nl><[motd]><&nl>------------------------------
            
            # Display money
            - ~run qm_player_money_narrate "def:You have|<player.money>"


        on player quits:
            # Update web database
            - webget http://play.qldminecraft.com.au/bridge.php 'data:{"cmd":"player_quit","player":"<player.uuid>"}' headers:<map.with[Content-Type].as[application/json]>

            # Update playing time and save player data
            - yaml id:<player.uuid> set playingTime:+:<util.time_now.epoch_millis.sub_int[<player.flag[playingStart]>]>
            - ~run qm_player_yaml_save def:<player>
            - ~run qm_player_yaml_unload def:<player>

            # Deop player for security
            - if <player.is_op>:
                - execute as_server "deop <player.name>"


        on player chats:
            - if <player.has_flag[npc_engage.npc]>:
                - if <player.location.find.npcs.within[3].contains[<player.flag[npc_engage.npc]>]>:
                    - ~run qm_npc_menu_handler def:<player.flag[npc_engage.npc]>|<context.message>
                    - determine cancelled
                    - stop
                - else:
                    - flag player npc_engage:!
            
            # Check if server chat enabled
            - if <yaml[server].read[chat_disabled]||0> == 0:
                - if <yaml[<player.uuid>].read[chat_disabled]||0> == 0:
                    - if <yaml[<player.uuid>].read[developer]||0> == 0:
                        - determine "format:player"
                    - else:
                        - determine "format:developer"
                - else:
                    - narrate format:notice "Chat is currently disabled for you"
                    - determine cancelled
            - else:
                - narrate format:notice "Chat is currently disabled for this server"
                - determine cancelled

                # - define recipients:li@
                # - foreach <context.recipients>:
                #     - if <[value].uuid> != <player.uuid>:
                #         - define recipients:|:<[value].uuid>
                
                # - if <[recipients].size> > 0:
                #     - define recipients <[recipients].separated_by[|]>


        on player drops item:
            - if <player.gamemode> == creative:
                - narrate format:notice "You cannot drop items in creative mode"
                - determine cancelled
        
        # on player places block:
        #     - if !<player.in_group[developer]>:
        #         - foreach <server.list_notables[cuboids]>:
        #             - define region_name:<[value].note_name>
        #             - define deny:0

        #             - if <context.location.is_within[<[value]>]> && <yaml[server].read[regions.<[region_name]>.type]> == town:
        #                 - define deny:1
        #                 - if <yaml[server].list_keys[plots].contains[<[region_name]>]>:
        #                     - foreach <yaml[server].list_keys[plots.<[region_name]>]>:
        #                         - if <context.location.is_within[<yaml[server].read[plots.<[region_name]>.<[value]>.cuboid]>]>:
        #                             - if <player.uuid> == <yaml[server].read[plots.<[region_name]>.<[value]>.owner]>:
        #                                 - define deny:0

        #             - if <[deny]> != 0:
        #                 - narrate format:notice "You Acannot place blocks outside your plot in a town"
        #                 - determine cancelled


        # on player breaks block:
        #     - if !<player.in_group[developer]>:
        #         - foreach <server.list_notables[cuboids]>:
        #             - define region_name:<[value].note_name>
        #             - define deny:0

        #             - if <context.location.is_within[<[value]>]> && <yaml[server].read[regions.<[region_name]>.type]> == town:
        #                 - define deny:1
        #                 - if <yaml[server].list_keys[plots].contains[<[region_name]>]>:
        #                     - foreach <yaml[server].list_keys[plots.<[region_name]>]>:
        #                         - if <context.location.is_within[<yaml[server].read[plots.<[region_name]>.<[value]>.cuboid]>]>:
        #                             - if <player.uuid> == <yaml[server].read[plots.<[region_name]>.<[value]>.owner]>:
        #                                 - define deny:0

        #             - if <[deny]> != 0:
        #                 - narrate format:notice "You cannot break blocks outside your plot in a town"
        #                 - determine cancelled


        on player enters *:
            # check if player entering new region
            - if <context.area||null> != null:
                - define region_id:<context.area.note_name>
                - define region_type:<yaml[server].read[regions.<[region_id]>.type]||ignore>
                - define region_name:<yaml[server].read[regions.<[region_id]>.name]||<[region_id]>>
                - define region_mode:<yaml[server].read[regions.<[region_id]>.mode]||null>
                - define region_deny:0

                - choose <[region_type]>:
                    - case town:
                        - actionbar "Entering town <[region_name]>" format:change_town
                    - case survival:
                        - actionbar "Entering area <[region_name]>" format:change_survival
                    - case creative:
                        - actionbar "Entering <[region_name]> (Creative Area)" format:change_creative
                        - if <[region_mode]> == null:
                            - define region_mode:creative
                    - case pvp:
                        - actionbar "Entering <[region_name]> (PVP Area)" format:change_pvp
                    - case restricted:
                        - if <player.in_group[developer]> || <player.in_group[qldminecraft.area.<[region_id]>]>:
                            - actionbar "Entering <[region_name]>" format:change_restricted
                        - else:
                            - define region_deny:1
                    - case area:
                        - if <yaml[<player.uuid>].read[regions.<[region_name]>.discovered]||0> == 0:
                            - actionbar "Discovered: <[region_name]>" format:change_town
            
                - yaml id:<player.uuid> set regions.discovered:->:<[region_id]>

                # player allowed entry?
                - if <[region_deny]> == 1:
                    - actionbar "You cannot enter this area" format:change_town
                    - determine cancelled
                - else:
                    # change gamemode?
                    - if <[region_mode]> != null && <player.gamemode> != <[region_mode]>:
                        - if !<player.in_group[developer]>:
                            - adjust <player> gamemode:<[region_mode]>
                        - else:
                            - narrate format:debug "Change gamemode to <[region_mode]> ignored"
                    
                    # Append region to player list
                    - flag player region:->:<[region_id]>
                
        on player exits *:
            - if <context.area||null> != null:
                - define region_id:<context.area.note_name>
                - define region_type:<yaml[server].read[regions.<[region_id]>.type]||null>
                - define region_name:<yaml[server].read[regions.<[region_id]>.name]||null>

                - choose <[region_type]>:
                    - case town:
                        - actionbar "Leaving town <[region_name]>" format:change_town
                    - case survival:
                        - actionbar "Leaving area <[region_name]>" format:change_survival
                    - case creative:
                        - actionbar "Leaving <[region_name]> (Creative Area)" format:change_creative
                    - case pvp:
                        - actionbar "Leaving <[region_name]> (PVP Area)" format:change_pvp
                    - case restricted:
                        - if <player.in_group[developer]> || <player.in_group[qldminecraft.area.<[region_id]>]>:
                            - actionbar "Leaving <[region_name]>" format:change_restricted

                - flag player region:<-:<[region_id]>

                # Change gamemode
                - define region_mode:<yaml[server].read[regions.<player.flag[region].last>.mode]||survival>
                - if <[region_mode]> != null && <player.gamemode> != <[region_mode]>:
                    - if !<player.in_group[developer]>:
                        - adjust <player> gamemode:<[region_mode]>
                    - else:
                        - narrate format:debug "Change gamemode to <[region_mode]> ignored"


        after player respawns:
            - define spawnLoc:<yaml[server].read[regions.<player.flag[region].last>.death_spawn]||null>

            - if <[spawnLoc]> != null:
                - teleport <[spawnLoc]> <player>
            - else:
                - teleport <yaml[server].read[first_spawn]> <player>

        on player breaks block:
            - if !<player.in_group[developer]>:
                - define region_list:<yaml[server].list_keys[regions]||null>
                - if <[region_list]> != null:
                    - foreach <[region_list]>:
                        - define region_id:<[value]>
                        - if <context.location.is_within[<[region_id]>]>:
                            # block inside towns
                            - if <yaml[server].read[regions.<[region_id]>.type]||ignore> == town:
                                - narrate format:notice "You cannot break blocks outside your plot inside a town"
                                - determine cancelled
                                - stop

                            # record breakage
                            - yaml id:<player.uuid> set regions.<[region_id]>.blocks.break.<context.material>:++

                            # update quest counts
                            - foreach <yaml[<player.uuid>].read[quests.active]>:
                                - define quest_id:<[value]>
                                - define quest_region:<yaml[<player.uuid>].read[quests.active.<[quest_id]>.region]||null>
                                - if <[quest_region]> == null && <[quest_region]> == <[region_id]>:
                                    - if <yaml[<player.uuid>].read[quests.active.<[quest_id]>.action]||null> == break_block:
                                        - if <yaml[<player.uuid>].read[quests.active.<[quest_id]>.block]||null> == <context.material>:
                                            - yaml id:<player.uuid> set quests.active.<[quest_id]>.amount:++
                                            - run qm_player_quests_update


        on player places block:
            - if !<player.in_group[developer]>:
                - define region_list:<yaml[server].list_keys[regions]||null>
                - if <[region_list]> != null:
                    - foreach <[region_list]>:
                        - define region_id:<[value]>
                        - if <context.location.is_within[<[region_id]>]>:
                            # block inside towns
                            - if <yaml[server].read[regions.<[region_id]>.type]||ignore> == town:
                                - narrate format:notice "You cannot place blocks outside your plot inside a town"
                                - determine cancelled
                                - stop

                            # record placement
                            - yaml id:<player.uuid> set regions.<[region_id]>.blocks.places.<context.material>:++

                            # update quest counts
                            - foreach <yaml[<player.uuid>].read[quests.active]>:
                                - define quest_id:<[value]>
                                - define quest_region:<yaml[<player.uuid>].read[quests.active.<[quest_id]>.region]||null>
                                - if <[quest_region]> == null && <[quest_region]> == <[region_id]>:
                                    - if <yaml[<player.uuid>].read[quests.active.<[quest_id]>.action]||null> == places_block:
                                        - if <yaml[<player.uuid>].read[quests.active.<[quest_id]>.block]||null> == <context.material>:
                                            - yaml id:<player.uuid> set quests.active.<[quest_id]>.amount:++
                                            - run qm_player_quests_update

        on player changes gamemode:
            - if <context.gamemode> == spectator || <player.gamemode> == spectator:
                - stop
            - ~run qm_player_save_state def:<player.gamemode>
            - run qm_player_load_state def:<context.gamemode>

        on entity teleports:
            - if <context.entity.is_player>:
                - flag player tp_cooldown:<util.time_now.epoch_millis>

        on entity damaged:
            - if <context.entity> == <player>:
                - if <util.time_now.epoch_millis.sub[<player.flag[tp_cooldown]||0>]> < 5000:
                    - determine cancelled
                - else
                    - flag player tp_cooldown:!

# Load a players data
qm_player_yaml_load:
    type: task
    definitions: player
    script:
        - if <server.has_file[/serverdata/players/<[player].uuid>.yml]>:
            - yaml load:/serverdata/players/<[player].uuid>.yml id:<[player].uuid>
        - else:
            - yaml create id:<[player].uuid>

        # Update player name
        - define currname:<yaml[<[player].uuid>].read[name]||null>
        - if <[currname]> != null && <[currname]> != <[player].name>:
            - yaml id:<[player].uuid> set prevNames:->:<[currname]>
        - yaml id:<[player].uuid> set name:<[player].name>

        # Save data
        - run qm_player_yaml_save def:<[player]>


# Save players data
qm_player_yaml_save:
    type: task
    definitions: player
    script:
        - yaml savefile:/serverdata/players/<[player].uuid>.yml id:<[player].uuid>


# Saves players data and unloads it from the server
qm_player_yaml_unload:
    type: task
    definitions: player
    script:
        - yaml unload id:<[player].uuid>


# Narrates a money amount
qm_player_money_narrate:
    type: task
    definitions: prefix|money|target
    script:
        - define gold:<[money].div[10000].round_down>
        - define silver:<[money].mod[10000].div[100].round_down>
        - define copper:<[money].mod[100].round_down>
        - define "text:<&f><[prefix]>   <&e><&chr[2B24]><&f><[gold].pad_left[1].with[0]>  <&7><&chr[2B24]><&f><[silver].pad_left[2].with[0]>  <&6><&chr[2B24]><&f><[copper].pad_left[2].with[0]>"

        - if <queue.definitions.contains[target]>:
            - narrate format:notice <[text]> target:<[target]>
        - else:
            - narrate format:notice <[text]>


qm_player_money_format:
    type: procedure
    definitions: money
    script:
        - define text:el@
        - define gold:<[money].div[10000].round_down>
        - define silver:<[money].mod[10000].div[100].round_down>
        - define copper:<[money].mod[100].round_down>

        - if <[gold]> > 0:
            - define "text:<[text]><&e><&chr[2B24]><&7><[gold]>"
        - if <[silver]> > 0:
            - define "text:<[text]><&7><&chr[2B24]><&7><[silver]>"
        - if <[copper]> > 0:
            - define "text:<[text]><&6><&chr[2B24]><&7><[copper]>"

        # - if <[gold]> > 0:
        #     - define "text:<[text]><&e><&chr[2B24]><&7><[gold]> "
        # - if <[silver]> > 0:
        #     - if <[gold]> > 0:
        #         - define "text:<[text]><&7><&chr[2B24]><&7><[silver].pad_left[2].with[0]> "
        #     - else:
        #         - define "text:<[text]><&7><&chr[2B24]><&7><[silver]> "
        #     - define "text:<[text]><&6><&chr[2B24]><&7><[copper].pad_left[2].with[0]>"
        # - else:
        #     - define "text:<[text]><&6><&chr[2B24]><&7><[copper]>"


        #- define "text:<&e><&chr[2B24]><&6><[gold].pad_left[1].with[0]>  <&7><&chr[2B24]><&<[colour]>><[silver].pad_left[2].with[0]>  <&6><&chr[2B24]><&<[colour]>><[copper].pad_left[2].with[0]>"

        - determine <[text]>


# Update player quests
qm_player_quests_update:
    type: task
    script:
        - foreach <yaml[<player.uuid>].list_keys[quests.active]>:
            - define quest_id:<[value]>
            - define completed:0

            - if <yaml[<player.uuid>].list_keys[quests.active.<[quest_id]>].contains[action]>:
                - if <yaml[<player.uuid>].read[quests.active.<[quest_id]>.qty]> <= <yaml[<player.uuid>].read[quests.active.<[quest_id]>.amount]>:
                    - define completed:1
            - else:
                - define completed:1

            - if <[completed]> == 1:
                - ~yaml id:<player.uuid> copykey:quests.active.<[quest_id]> quests.complete.<[quest_id]>
                - yaml id:<player.uuid> set quests.active.<[quest_id]:!


# Procedure Get XP
get_xp:
  type: procedure
  definitions: player
  script:
    - define lvl <player.xp_level>
    - if <[lvl]> <= 16:
      - define level_xp <[lvl].add[6].mul[<[lvl]>]>
    - else if <[lvl]> <= 31:
      - define level_xp <[lvl].mul[<[lvl]>].mul[2.5].sub[<[lvl].mul[40.5]>].add[360]>
    - else:
      - define level_xp <[lvl].mul[<[lvl]>].mul[4.5].sub[<[lvl].mul[162.5]>].add[2220]>
    - define curr_xp <[player].xp.mul[<[player].xp_to_next_level>].div[100]>
    - determine <[level_xp].add[<[curr_xp]>].round>


# Load player state
qm_player_load_state:
    type: task
    definitions: gamemode
    script:
        - define id <player.uuid>
        - define path:gamestate.<[gamemode]>
        
        - inventory clear 
        - inventory d:<player.enderchest> clear 
        
        # Inventory 
        - define slots <yaml[<[id]>].read[<[path]>.inventory]||<map[]>> 
        - if !<[slots].is_empty>: 
            - inventory set d:<player.inventory> o:<[slots]> 
        
        # Enderchest 
        - define slots <yaml[<[id]>].read[<[path]>.enderchest]||<map[]>> 
        - if !<[slots].is_empty>: 
            - inventory set d:<player.enderchest> o:<[slots]> 
        
        # Equipment 
        - define slots <yaml[<[id]>].read[<[path]>.equipment]||<map[]>> 
        - if !<[slots].is_empty>: 
            - adjust <player> equipment:<[slots]> 
        
        # Offhand 
        - define slots <yaml[<[id]>].read[<[path]>.offhand]||null> 
        - if <[slots]> != null: 
            - adjust <player> item_in_offhand:<[slots]> 
        
        # Stats 
        - adjust <player> max_health:<yaml[<[id]>].read[<[path]>.stats.health_max]||20> 
        - adjust <player> health:<yaml[<[id]>].read[<[path]>.stats.health]||20> 
        - adjust <player> food_level:<yaml[<[id]>].read[<[path]>.stats.food_level]||20> 
        - adjust <player> saturation:<yaml[<[id]>].read[<[path]>.stats.saturation]||0> 
        - adjust <player> exhaustion:<yaml[<[id]>].read[<[path]>.stats.exhaustion]||1> 
        - adjust <player> fall_distance:<yaml[<[id]>].read[<[path]>.stats.fall_distance]||0> 
        - adjust <player> fire_time:<yaml[<[id]>].read[<[path]>.stats.fire_time]||0> 
        - adjust <player> oxygen:<yaml[<[id]>].read[<[path]>.stats.oxygen]||15> 
        - adjust <player> remove_effects 
        - adjust <player> potion_effects:<yaml[<[id]>].read[<[path]>.stats.potion_effects]||<list[]>> 
        - experience take <util.int_max> 
        - experience give <yaml[<[id]>].read[<[path]>.stats.xp]||0> 


# Save player state
qm_player_save_state:
    type: task
    definitions: gamemode
    script:

    - define id:<player.uuid>
    - define path:gamestate.<[gamemode]>

    # Inventory
    - define slots <player.inventory.map_slots.get_subset[<player.inventory.map_slots.keys.filter[is[less].than[37]]>]>
    - if <[slots].is_empty>:
      - yaml set <[path]>.inventory:! id:<[id]>
    - else:
      - yaml set <[path]>.inventory:<[slots]> id:<[id]>

    # Enderchest
    - define slots <player.enderchest.map_slots>
    - if <[slots].is_empty>:
      - yaml set <[path]>.enderchest:! id:<[id]>
    - else:
      - yaml set <[path]>.enderchest:<[slots]> id:<[id]>

    # Equipment
    - define slots <player.equipment_map>
    - if <[slots].is_empty>:
      - yaml set <[path]>.equipment:! id:<[id]>
    - else:
      - yaml set <[path]>.equipment:<[slots]> id:<[id]>

    # Offhand
    - yaml set <[path]>.offhand:<player.item_in_offhand> id:<[id]>

   # Stats
    - yaml set <[path]>.stats.health_max:<player.health_max> id:<[id]>
    - yaml set <[path]>.stats.health:<player.health> id:<[id]>
    - yaml set <[path]>.stats.food_level:<player.food_level> id:<[id]>
    - yaml set <[path]>.stats.saturation:<player.saturation> id:<[id]>
    - yaml set <[path]>.stats.exhaustion:<player.exhaustion> id:<[id]>
    - yaml set <[path]>.stats.fall_distance:<player.fall_distance> id:<[id]>
    - yaml set <[path]>.stats.fire_time:<player.fire_time> id:<[id]>
    - yaml set <[path]>.stats.oxygen:<player.oxygen> id:<[id]>
    - yaml set <[path]>.stats.potion_effects:<player.list_effects> id:<[id]>
    - yaml set <[path]>.stats.xp:<proc[get_xp].context[<player>]> id:<[id]>