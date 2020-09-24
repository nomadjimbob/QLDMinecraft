qmw_events:
    type: world
    debug: false
    events:
        on pre load:
            - yaml create id:events
            - ~run qm_events.yaml.load
            - flag server events_active:!

            - foreach <yaml[events].list_keys[replace_blocks]||<list[]>>:
               - define event_id:<[value]>
               - foreach <yaml[events].list_keys[replace_blocks.<[event_id]>]>:
                   - modifyblock <[value]> <yaml[events].read[replace_blocks.<[event_id]>.<[value]>]>
                
               - yaml id:events set replace_blocks.<[event_id]>:!
               - run qm_events.yaml.save
            - run qm_command.add.command def:qm_events_cmd|event
            - run qm_command.add.aliases def:event|events
            - run qm_command.add.tabcomplete def:event|add
            - run qm_command.add.tabcomplete def:event|del|_*events
            - run qm_command.add.tabcomplete def:event|enable|_*events
            - run qm_command.add.tabcomplete def:event|disable|_*events
            - run qm_command.add.tabcomplete def:event|regions|_*events
            - run qm_command.add.tabcomplete def:event|priority|_*events
            - run qm_command.add.tabcomplete def:event|starttime|_*events
            - run qm_command.add.tabcomplete def:event|cut|_*events
            - run qm_command.add.tabcomplete def:event|paste|_*events
            - run qm_command.add.tabcomplete def:event|running
            
        on save:
            - run qm_events.yaml.save
        
        on system time minutely:
            - run qm_events.update
    


qm_events:
    type: task
    debug: true
    script:
        - narrate 'invalid call to qm_events'
    
    yaml:
        load:
            - if <server.has_file[/serverdata/events.yml]>:
                - yaml load:/serverdata/events.yml id:events
            - else:
                - yaml create id:events

            #- run qm_events.yaml.save

        save:
            - yaml savefile:/serverdata/events.yml id:events
    
    update:
        - define events_active:<server.flag[events_active]||<map[]>>
        - foreach <yaml[events].list_keys[events]>:
            - define event_id:<[value]>
            - define start_date:<yaml[events].read[events.<[event_id]>.start_date]||null>
            - define end_date:<yaml[events].read[events.<[event_id]>.end_date]||null>
            - define name:<yaml[events].read[events.<[event_id]>.name]||null>

            - if <yaml[events].read[events.<[event_id]>.enabled]||false>:
                - if <[start_date]> == null || <[start_date]> <= <util.time_now.epoch_millis>:
                    # time is beyond start time of event

                    - if <[end_date]> == null || <[end_date]> > <util.time_now.epoch_millis>:
                        # end date is still in future

                        - define duration:<yaml[events].read[events.<[event_id]>.duration]||null>
                        - define every_year:<yaml[events].read[events.<[event_id]>.every_year]||null>
                        - define every_month:<yaml[events].read[events.<[event_id]>.every_month]||null>
                        - define every_day:<yaml[events].read[events.<[event_id]>.every_day]||null>
                        - define every_weekday:<yaml[events].read[events.<[event_id]>.every_weekday]||null>
                        - define every_hour:<yaml[events].read[events.<[event_id]>.every_hour]||null>
                        - define every_minute:<yaml[events].read[events.<[event_id]>.every_minute]||null>

                        - if <[events_active].keys.contains[<[event_id]>]||false>:
                            # event is running
                            - define past_millis:<util.time_now.epoch_millis.sub[<[events_active].get[<[event_id]>]>]>
                            - define past_mins:<[past_millis].div[60000]>
                            - if <[duration].sub[<[past_mins]>]> <= 0:
                                - run qm_events.end def:<[event_id]>
                        - else:
                            - define start:true

                            - if <[every_year]> != null && <[every_year]> != <util.time_now.year>:
                                - define start:false
                            - if <[every_month]> != null && <[every_month]> != <util.time_now.month>:
                                - define start:false
                            - if <[every_day]> != null && <[every_day]> != <util.time_now.day>:
                                - define start:false
                            - if <[every_weekday]> != null && <[every_weekday]> != <util.time_now.day_of_week>:
                                - define start:false
                            - if <[every_hour]> != null && <[every_hour]> != <util.time_now.hour>:
                                - define start:false
                            - if <[every_minute]> != null && <[every_minute]> != <util.time_now.minute>:
                                - define start:false

                            - if <[start]>:
                                - run qm_events.start def:<[event_id]>
                                
                    - else:
                        # end date has past
                        - if <[events_active].keys.contains[<[event_id]>]>:
                            - run qm_events.end def:<[event_id]>

    start:
        - define event_id:<[1]||null>
        - if <[event_id]> != null:
            - define name:<yaml[events].read[events.<[event_id]>.name]||null>
            - flag server events_active:<server.flag[events_active].with[<[event_id]>].as[<util.time_now.epoch_millis>]||<map[<[event_id]>/<util.time_now.epoch_millis>]>>
            - if <yaml[events].read[events.<[event_id]>.announce]||false>:
                - if <[name]> != null:
                    - narrate '<&e>The <[name]> event has begun' target:<server.online_players>
            
            - foreach <yaml[events].list_keys[events.<[event_id]>.paste_blocks]||<list[]>>:
                - define paste_block_id:<[value]>
                - foreach <yaml[events].list_keys[events.<[event_id]>.paste_blocks.<[paste_block_id]>]||<list[]>>:
                   - yaml id:events set replace_blocks.<[event_id]>.<[value]>:<[value].material>
                   - modifyblock <[value]> <yaml[events].read[events.<[event_id]>.paste_blocks.<[paste_block_id]>.<[value]>]>
                
                - run qm_events.yaml.save

            - event "event started" context:event|<[event_id]>
    
    end:
        - define event_id:<[1]||null>
        - if <[event_id]> != null:
            - define name:<yaml[events].read[events.<[event_id]>.name]||null>
            - flag server events_active:<server.flag[events_active].exclude[<[event_id]>]>
            - if <yaml[events].read[events.<[event_id]>.announce]||false>:
                - if <[name]> != null:
                    - narrate '<&e>The <[name]> event has ended' target:<server.online_players>
            
            - foreach <yaml[events].list_keys[replace_blocks.<[event_id]>]||list[]>:
                - modifyblock <[value]> <yaml[events].read[replace_blocks.<[event_id]>.<[value]>]>
            
            - yaml id:events set replace_blocks.<[event_id]>:!
            - run qm_events.yaml.save

            - event "event finished" context:event|<[event_id]>

qmp_events:
    type: procedure
    debug: false
    script:
        - determine null
    
    get:
        current:
            - define event_priority_map:<map[]>

            - foreach <server.flag[events_active].as_map.keys||<list[]>>:
                - define event_priority_map:<[event_priority_map].with[<[value]>].as[<yaml[events].read[events.<[value]>.priority]||0>]>
            
            - determine <[event_priority_map].sort_by_value.keys.reverse>
        
        yaml:
            - define id:<[1]||null>
            - define path:<[2]||null>
            - define event_list:<proc[qmp_events.get.current]||<list[]>>
            - define event_list:|:default

            # - determine <[event_list]>

            - if <[id]> != null && <[path]> != null:
                - foreach <[event_list]>:
                    - define event_path:<[path].replace_text[$EVENT$].with[<[value]>]>
                    - define value:<yaml[<[id]>].read[<[event_path]>]||null>
                    - if <[value]> != null:
                        - determine <[value]>
            - else:
                - determine 'Get YAML from event error: <[id]> <[path]>'
    


qm_events_cmd:
    type: task
    debug: false
    script:
        - define action:<[1]||null>
        - define option:<[2]||null>
        - define event_id:<[3]||null>
        - define value:<[4]||null>

        - choose <[action]>:
            - case event:
                - choose <[option]>:
                    - case add create:
                        - if <[event_id]> != null:
                            - if !<yaml[events].list_keys[events].contains[<[event_id]>]>:
                                - yaml id:events set events.<[event_id]>.enabled:false
                                - run qm_events.yaml.save
                                - narrate 'xxevent saved'
                            - else:
                                - narrate 'xxthat event id already exists'
                        - else:
                            - narrate 'xxno event id entered'
                    - case del delete rem remove:
                        - if <[event_id]> != null:
                            - if <yaml[events].list_keys[events].contains[<[event_id]>]>:
                                - yaml id:events set events.<[event_id]>:!
                                - run qm_events.yaml.save
                                - narrate 'xxevent deleted'
                            - else:
                                - narrate 'xxthat event id doesnt exists'
                        - else:
                            - narrate 'xxno event id entered'
                    - case enable enabled:
                        - if <[event_id]> != null:
                            - if <yaml[events].list_keys[events].contains[<[event_id]>]>:
                                - yaml id:events set events.<[event_id]>.enabled:true
                                - run qm_events.yaml.save
                                - narrate 'xxevent enabled'
                            - else:
                                - narrate 'xxthat event id doesnt exists'
                        - else:
                            - narrate 'xxno event id entered'
                    - case disable disabled:
                        - if <[event_id]> != null:
                            - if <yaml[events].list_keys[events].contains[<[event_id]>]>:
                                - yaml id:events set events.<[event_id]>.enabled:false
                                - run qm_events.yaml.save
                                - narrate 'xxevent disabled'
                            - else:
                                - narrate 'xxthat event id doesnt exists'
                        - else:
                            - narrate 'xxno event id entered'
                    - case regions:
                        - if <[event_id]> != null:
                            - if <yaml[events].list_keys[events].contains[<[event_id]>]>:
                                - define regions:<yaml[events].read[events.<[event_id]>.regions]||<list[]>>
                                - if <[regions].size> > 0:
                                    - foreach <[regions]>:
                                        - narrate '<[loop_index]> - <[value]>'
                                - else:
                                    - narrate 'xxevent does not have any regions'
                            - else:
                                - narrate 'xxthat event id doesnt exists'
                        - else:
                            - narrate 'xxno event id entered'
                    - case priority:
                        - if <[event_id]> != null:
                            - if <yaml[events].list_keys[events].contains[<[event_id]>]>:
                                - if <[value].is_integer>:
                                    - yaml id:events set events.<[event_id]>.priority:<[value]>
                                    - run qm_events.yaml.save
                                    - narrate 'xxevent priority updfated'
                                - else:
                                    - narrate 'xxevent priority is not a number'
                            - else:
                                - narrate 'xxthat event id doesnt exists'
                        - else:
                            - narrate 'xxno event id entered'
                    - case starttime:
                        - if <[event_id]> != null:
                            - if <yaml[events].list_keys[events].contains[<[event_id]>]>:
                                - define time:<time[<[value]>]||null>
                                - if <[time]> != null:
                                    - yaml id:events set events.<[event_id]>.start_time:<[time].epoch_millis>
                                    - narrate 'xxevent start time updated'
                                - else:
                                    - narrate 'xxevent start time is invalid'
                            - else:
                                - narrate 'xxthat event id doesnt exists'
                        - else:
                            - narrate 'xxno event id entered'
                    - case cut copy:
                        - if <[event_id]> != null:
                            - if <yaml[events].list_keys[events].contains[<[event_id]>]>:
                                - define new_block_list_id:<yaml[events].list_keys[events.<[event_id]>.paste_blocks].highest.add[1]||1>
                                - narrate <[new_block_list_id]>
                                - foreach <player.we_selection.blocks>:
                                    - yaml id:events set events.<[event_id]>.paste_blocks.<[new_block_list_id]>.<[value]>:<[value].material>
                                
                                - if <[option]> == cut:
                                    - modifyblock <player.we_selection> air

                                - run qm_events.yaml.save

                                - narrate 'xxevent blocks added (<[new_block_list_id]>)'
                            - else:
                                - narrate 'xxthat event id doesnt exists'
                        - else:
                            - narrate 'xxno event id entered'
                    

                    - case running:
                        - define events_active:<server.flag[events_active]||<map[]>>
                        - if <[events_active].keys.size> > 0:
                            - foreach <[events_active].keys>:
                                - narrate '  - <[value]>'
                        - else:
                            - narrate 'xxNo active events'

                    - default:
                        - narrate notavail


qmp_command_tabcomplete_events:
    type: procedure
    debug: false
    script:
        - determine <yaml[events].list_keys[events]||<list[]>>
