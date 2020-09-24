# setting key/- places the menu item as just text

qmw_menu:
    type: world
    debug: false
    events:
        on player chats:
            - if <proc[qmp_menu.exists]>:
                - run qm_menu.chat def:<player>|<context.message> save:chat_state
                - if <entry[chat_state].created_queue.determination.get[1]||true> != false:
                    - determine cancelled

qm_menu:
    type: task
    debug: true
    max_menu_items: 6
    script:
        - narrate 'invalid call to qm_menu'
    
    add:
        - if <[1]||null> != null:
            - flag player menu.items:->:<[1]>

    back:
        - flag player menu.back_count:<[1]||1>
    
    header:
        - flag player menu.header:<[1]||null>

    chat:
        - define target:<[1]||null>
        - define chat:<[2]||null>
        - define show_max_menu_items:<script[qm_menu].data_key[max_menu_items]||6>

        - if <[target]> != null && <[chat]> != null:
            - define menu:<[target].flag[menu.items]||null>
            
            - if <[menu]> != null || <[target].flag[menu.path].size||0> > 1:
                - if <[target].has_flag[menu.state_handler]>:
                    - ~run <[target].flag[menu.state_handler]> def:<[target]>|<[target].flag[menu.data]||null> save:chat_state
                    - if <entry[chat_state].created_queue.determination.get[1]||true> == false:
                        - run qm_menu.close
                        - determine false
                
                - determine passively true

                - define menu_offset:<[target].flag[menu.offset]||0>
                # - narrate <[menu_offset]>
                - foreach <[menu].as_list>:
                    - if <[loop_index]> > <[menu_offset]>:
                        - if <[value].get[key]> != '*' && <[value].get[key]> == <[chat]>:
                            - define menu_handler:<[value].get[handler]||null>
                            - if <[menu_handler]> != null && <server.scripts.contains[<script[<[menu_handler]>]>]>:
                                - run qm_menu.clear
                                - run <[menu_handler]> def:<[value].get[id]>|<[target].flag[menu.data]||null>
                                - run qm_menu.run def:<[menu_handler]>$<[value].get[id]>
                            - else:
                                - narrate <proc[qmp_lang].context[<player||null>|menu_item_not_defined|menu]>
                                - run qm_menu.close
                            - stop
                        - else if <[value].get[key]> == '*' && <[chat]> != b:
                            - define menu_handler:<[value].get[handler]||null>
                            - if <[menu_handler]> != null:
                                - run qm_menu.clear
                                - run <[menu_handler]> def:<[value].get[id]>|<[target].flag[menu.data]||null>|<[chat]>
                                - run qm_menu.run def:<[menu_handler]>$<[value].get[id]>
                            - stop
                
                - if <[menu_offset]> > 0 && <[chat]> == 'b':
                    - narrate "<&nl.pad_right[7750].with[<&sp><&nl>]>"
                    - flag <[target]> menu.offset:-:<[show_max_menu_items]>
                - else if <[menu_offset]> == 0 && <[chat]> == 'b' && <[target].flag[menu.path].size> > 0:
                    - if <player.has_flag[menu.back_count]>:
                        - while <player.flag[menu.back_count]> > 0:
                            - flag <[target]> menu.path:<-:<[target].flag[menu.path].last>
                            - flag player menu.back_count:--
                    - else:
                        - flag <[target]> menu.path:<-:<[target].flag[menu.path].last>
                    - run qm_menu.clear
                    - flag player menu.back_count:!
                    # - run <[target].flag[menu.path].last> def:null|<[target].flag[menu.data]||null>
                    # - run qm_menu.run def:<[target].flag[menu.path].last>
                    - run <[target].flag[menu.path].last.before[$]> def:<[target].flag[menu.path].last.after_last[$]>|<[target].flag[menu.data]||null>
                    - run qm_menu.run def:<[target].flag[menu.path].last>
                    - stop
                - else if <[menu_offset].add_int[<[show_max_menu_items]>]> < <[menu].size> && <[chat]> == 'n':
                    - narrate "<&nl.pad_right[7750].with[<&sp><&nl>]>"
                    - flag <[target]> menu.offset:+:<[show_max_menu_items]>
                - else:
                    - narrate "<&nl.pad_right[7750].with[<&sp><&nl>]>"
                    - narrate <proc[qmp_lang].context[<player||null>|unknown_menu_item|menu]>
                
                - run qm_menu.render
            - else:
                - determine false

    clear:
        - flag player menu.items:!
        - narrate "<&nl.pad_right[7750].with[<&sp><&nl>]>"

    close:
        - flag player menu:!
    
    data:
        - flag player menu.data:<[1]||null>
    
    render:
        - define show_max_menu_items:<script[qm_menu].data_key[max_menu_items]||6>
        - define menu:<player.flag[menu.items]||null>
        - define menu_offset:<player.flag[menu.offset]||0>

        - define header:<player.flag[menu.header]||null>
        - if <[header]> != null:
            - narrate '<&6>-- <[header]> (<[menu_offset].div[<[show_max_menu_items]>].round_up.add_int[1]>/<[menu].size.div[<[show_max_menu_items]>].round_up>) --<&nl>'

        - if <[menu_offset]> > 1 || <player.flag[menu.path].size> > 1:
            - define footer_items:->:<element[<&6><&lb>B<&rb>ack].on_click[b]>

        - if <[menu]> != null:
            # - narrate <[menu_offset]>
            - foreach <[menu].as_list.get[<[menu_offset].add_int[1]>].to[<[menu_offset].add_int[<[show_max_menu_items]>]>]>:
                - define id:<[value].as_map.get[id]||null>
                - define key:<[value].as_map.get[key]||null>
                - if <[key]> != '-' && <[key]> != '*' && <[id]> != null:
                    - if <[value].as_map.get[title].contains[*]>:
                        - define footer_items:->:<element[<&6><[value].as_map.get[title].after[*]>].on_click[<[key]>]>
                    - else:
                        - narrate "<element[<&l><[key]><&l.end_format> - <&e><[value].as_map.get[title]>].on_click[<[key]>]>"
                - else:
                    - if <[value].as_map.get[title]> == '-':
                        - narrate ''
                    - else:
                        - narrate "<&e><[value].as_map.get[title]>"

        - if <[menu_offset].add_int[<[show_max_menu_items]>]> < <[menu].size||0>:
            - define footer_items:->:<element[<&6><&lb>N<&rb>ext].on_click[b]>
        
        - if <[footer_items]||null> != null:
            - narrate " "
            # - foreach <[footer_items]>:
            #     - narrate <[value]>
            - narrate '<[footer_items].separated_by[   ]>'

    run:
        - define handler:<[1]>
        - define allow_skip:<[2]||false>
        - define show_max_menu_items:<script[qm_menu].data_key[max_menu_items]||6>
        - define menu:<player.flag[menu.items]||null>
        - flag player menu.items:!
        - flag player menu.offset:!
        - define row:0
        - define index:0

        - if <[menu]> != null:
            - if <player.flag[menu.path].last.before[@]||null> != <[handler]||null>:
                - flag player menu.path:->:<[handler]>

            - if <[menu].as_list.size> == 1 && <[allow_skip]>:
                - flag player menu.path:<-:<[handler]>
                - define value:<[menu].as_list.get[1]>
                - run <[value].get[handler]> def:<[value].get[id]>|<player.flag[menu.data]||null>
                - run qm_menu.run def:<[value].get[handler]>
                - stop
            - else:
                - foreach <[menu].as_list>:
                    - define key:<[value].as_map.get[key]||<[index]>>
                    - define id:<[value].as_map.get[id]||null>
                    - if <[id]> == null:
                        - define key:<element[-]>
                                        
                    - define row:++
                    - if <[row]> > <[show_max_menu_items]>:
                        - define index:1
                        - define row:1

                    - if <[key]> == <[index]>:
                        - define index:++

                    - flag player menu.items:->:<[value].as_map.default[key].as[<[index]>]>
            
            - run qm_menu.render
        - else:
            - if <player.has_flag[menu.back_count]>:
                - while <player.flag[menu.back_count]> > 0:
                    - flag player menu.path:<-:<player.flag[menu.path].last>
                    - flag player menu.back_count:--
                - flag player menu.back_count:!
                - run <player.flag[menu.path].last.before[$]> def:<player.flag[menu.path].last.after_last[$]>|<player.flag[menu.data]||null>
                - run qm_menu.run def:<player.flag[menu.path].last>
            - else:
                - run qm_menu.close

    state_handler:
        - if <[1]||null> != null:
            - flag player menu.state_handler:<[1]>


qmp_menu:
    type: procedure
    script:
        - determine null
    
    exists:
        - determine <player.has_flag[menu.items]||false>
