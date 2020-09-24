qmc_command:
    type: command
    debug: true
    name: qm
    description: Displays or sets areas
    usage: /qm [option]
    tab complete:
        - determine <proc[qmp_command_tabcomplete].context[<list[qm|command_tabcomplete].include_single[<context.raw_args.escaped>]>]>
    script:
        - define command:<context.args.get[1]||<empty>>
        - define option:<context.args.get[2]||<empty>>
        - choose <[command]>:
            - default:
                - define cmd_registered:0

                - foreach <yaml[commands].list_keys[command_aliases]||<list[]>>:
                    - if <yaml[commands].read[command_aliases.<[value]>].contains[<[command]>]||false>:
                        - define action:<[value]>
                        - foreach stop
                        
                # there can only be 1?
                # - foreach <yaml[commands].list_keys[commands]||<list[]>>:
                #    - if <[value]> == <[command]>:
                - if <yaml[commands].list_keys[commands].contains[<[command]>]||false>:
                    - define permission:<yaml[commands].read[commands.<[command]>.permission]||<empty>>
                    - if <[permission]> == <empty> || <[permission]> == default || <player.in_group[<[permission]>]||true>:
                    # - if <proc[qmp_server.player.in_developer_mode].context[<player||null>]>:
                        - define callback_value:<yaml[commands].read[commands.<[command]>.option_callback.<[option]>]||<empty>>
                        - if <[callback_value]> == <empty>:
                            - define callback_value:<yaml[commands].read[commands.<[command]>.callback]>

                        - define args:<list[]>
                        - define cb_map:<map[command/<[command]>|option/<[option]>|player/<player||<empty>>]>

                        - foreach <context.args.remove[1|2]>:
                            - if <[value].contains[:]> && !<[value].contains[://]>:
                                - define cb_map:<[cb_map].with[<[value].before[:]>].as[<[value].after[:]>]>
                            - else:
                                - define args:|:<[value]>

                        - define cb_map:<[cb_map].with[args].as[<[args]>]>
                        
                        - run <[callback_value]> def:<[cb_map]>
                    - else:
                        - narrate <proc[qmp_language].context[command_not_permitted|server]>
                - else:
                    - narrate <proc[qmp_language].context[cmd_not_found|server]>

                # - if <[cmd_registered]> == 0:
                #     - define p_target:<player||null>
                #     - narrate <proc[qmp_lang].context[<[p_target]>|cmd_not_found|command]>


qm_command:
    type: task
    debug: false
    script:
        - narrate na
    add:
        command:
            - define callback:<[1]||null>
            - define cmd:<[2]||null>
            - define permission:<[3]||default>
            
            - if <[callback]> != null && <[cmd]> != null && <server.scripts.contains[<script[<[callback]>]>]||false>:
                - yaml id:commands set commands.<[cmd]>.callback:<[callback]>
                - yaml id:commands set commands.<[cmd]>.permission:<[permission]>
                - if <yaml[command_tabcomplete].read[qm.<[cmd]>]||null> == null:
                    - yaml id:command_tabcomplete set qm.<[cmd]>:end
        
        aliases:
            - define cmd:<[1]||null>
            - define alias_list:<[2]||<list[]>>

            - foreach <[alias_list]>:
                - if <yaml[commands].read[command_aliases.<[cmd]>].contains[<[value]>]||false> == false:
                    - yaml id:commands set command_aliases.<[cmd]>:->:<[value]>
        
        option:
            - define callback:<[1]||null>
            - define cmd:<[2]||null>
            - define option:<[3]||null>

            - if <[callback]> != null && <[cmd]> != null && <[option]> != null && <server.scripts.contains[<script[<[callback]>]||null>]||false>:
                - yaml id:commands set commands.<[cmd]>.option_callback.<[option]>:<[callback]>
        
        tabcomplete:
            - yaml id:command_tabcomplete set qm.<queue.definition_map.exclude[raw_context].values.separated_by[.]>:end
            
            
qmw_command:
    type: world
    debug: false
    events:
        on server start:
            - ~yaml create id:commands
            - ~yaml create id:command_tabcomplete
            - yaml id:command_tabcomplete set qm:end
        
        on pre script reload:
            - ~yaml create id:commands
            - ~yaml create id:command_tabcomplete
            - yaml id:command_tabcomplete set qm:end


#todo tabcomplete is showing dev options for non devs

qmp_command_tabcomplete:
    type: procedure
    debug: false
    definitions: command|data|raw_args
    script:
        - define raw_args:<[raw_args]||<empty>>
        - define path:<[command]>
        - define 'args:|:<[raw_args].split[ ]>'
        - if <[args].get[1]> == <empty>:
            - define args:!|:<[args].remove[1]>
        - define argsSize:<[args].size>
        - define newArg:<[raw_args].ends_with[<&sp>].or[<[raw_args].is[==].to[<empty>]>]>
        - if <[newArg]>:
            - define argsSize:+:1
        - repeat <[argsSize].sub[1]> as:index:
            - define value:<[args].get[<[index]>]>
            - define keys:!|:<yaml[<[data]>].list_keys[<[path]>]>
            - define permLockedKeys:!|:<[keys].filter[starts_with[?]]>
            - define keys:<-:<[permLockedKeys]>
            - if <[value]> == <empty>:
                - foreach next
            - if <[keys].contains[<[value]>]>:
                - define path:<[path]>.<[value]>
            - else:
                - if <[permLockedKeys].size> > 0:
                    - define permMap:'<[permLockedKeys].parse[after[ ]].map_with[<[permLockedKeys].parse[before[ ]]>]>'
                    - define perm:<[permMap].get[<[value]>]||null>
                    - if <[perm]> != null && <player.has_permission[<[perm].after[?]>]>:
                        - define path:'<[path]>.<[perm]> <[value]>'
                        - repeat next
                - define default <[keys].filter[starts_with[_]].get[1]||null>
                - if <[default]> == null:
                    - determine <list[]>
                - define path:<[path]>.<[default]>
            - if <yaml[<[data]>].read[<[path]>]> == end:
                - determine <list[]>
        - foreach <yaml[<[data]>].list_keys[<[path]>]||<list[]>>:
            - if <[value].starts_with[_]>:
                - define value:<[value].after[_]>
                - if <[value].starts_with[*]>:
                    - define ret:|:<proc[qmp_<[data]>_<[value].after[*]>].context[<[args]>]>
            - else if <[value].starts_with[?]>:
                - define perm:'<[value].before[ ].after[?]>'
                - if <player.has_permission[<[perm]>]>:
                    - define 'ret:|:<[value].after[ ]>'
            - else:
                - define ret:->:<[value]>
        - if !<definition[ret].exists>:
            - determine <list[]>
        - if <[newArg]>:
            - determine <[ret]>
        - determine <[ret].filter[starts_with[<[args].last>]]>


qmp_command_tabcomplete_number:
    type: procedure
    debug: false
    script:
        - determine <list[0|1|2|3|4|5]>


qmp_command_tabcomplete_boolean:
    type: procedure
    debug: false
    script:
        - determine <list[true|false]>


qmp_command_tabcomplete_switch:
    type: procedure
    debug: false
    script:
        - determine <list[on|off]>


qmp_command_tabcomplete_players:
    type: procedure
    debug: false
    script:
        - define player_list:<server.players>
        - foreach <[player_list]>:
            - define player_names:->:<[value].name>
        - determine <[player_names]>


qmp_command_tabcomplete_materials:
    type: procedure
    debug: false
    script:
        - define materials_raw_list:<server.material_types>
        - foreach <[materials_raw_list]>:
            - define materials_list:->:<[value].name>
        - determine <[materials_list]>
