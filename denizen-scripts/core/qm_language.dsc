# todo placeholder set is not saved

qmw_language:
    type: world
    debug: true
    events:
        on pre load:
            - ~run qmw_language.load
        
        on load:
            - run qm_command.add.command def:qm_language_cmd|placeholder|developer
        
    load:
        - if <yaml.list.contains[lang]>:
            - ~yaml unload id:lang
        - ~yaml create id:lang

        - foreach <server.list_files[/serverdata/lang/]||<list[]>>:
            - if <[value].after_last[.]> == yml:
                - ~run qm_server.yaml.merge def:lang|/serverdata/lang/<[value]>


qmp_language:
    type: procedure
    debug: false
    script:
        - define message:<[1]||<empty>>
        - define category:<[2]||<empty>>
        - define mappings:<[3].unescaped.as_map||<map[]>>
        - define language:<player.flag[language]||en>

        - if <[message]> != <empty>:
            - if <[category]> != <empty>:
                - define 'text:<&c>Langage data is missing from server'

                - if <yaml[lang].read[<[category]>.<[language]>.<[message]>]||<empty>> != <empty>:
                    - define message:<yaml[lang].read[<[category]>.<[language]>.<[message]>]>
                - else if <yaml[lang].read[<[category]>.<[message]>]||<empty>> != <empty>:
                    - define message:<yaml[lang].read[<[category]>.<[message]>]>

                - foreach <[mappings].keys||<list[]>>:
                    - define message:<[message].replace_text[$<[value]>$].with[<[mappings].get[<[value]>]>]>

                
            # - else:
            #     - narrate '<&c>Langage data is missing from server'
                    
            - foreach <yaml[lang].list_keys[placeholder.<[language]>]||<list[]>>:
                - define message:<[message].replace_text[$<[value]>$].with[<yaml[lang].read[placeholder.<[language]>.<[value]>]>]>

            - foreach <yaml[lang].list_keys[placeholder]||<list[]>>:
                - define message:<[message].replace_text[$<[value]>$].with[<yaml[lang].read[placeholder.<[value]>]>]>

            - foreach <yaml[lang].list_keys[color]||<list[]>>:
                - define message:<[message].replace_text[$COLOR-<[value]>$].with[&<yaml[lang].read[color.<[value]>]>]>

            - define message:<[message].parse_color>

            - determine <[message]>
        - else:
            - narrate '<&c>Langage data is missing from server'

        - define 'text:Language data is missing'
        
    exists:
        - define message:<[1]||<empty>>
        - define category:<[2]||<empty>>
        - define language:<player.flag[language]||en>

        - if <[message]> != <empty>:
            - if <[category]> != <empty>:

                - if <yaml[lang].read[<[category]>.<[language]>.<[message]>]||<empty>> != <empty>:
                    - determine true
                - else if <yaml[lang].read[<[category]>.<[message]>]||<empty>> != <empty>:
                    - determine true
        
        - determine false


    
    list:
        placeholder:
            - determine <yaml[lang].list_keys[placeholder]||<list[]>>


    get:
        placeholder:
            - define placeholder:<[1]>
            - determine <yaml[lang].read[placeholder.<[placeholder]>]||<empty>>

        player:
            language:
                - if <[1].is_player||false>:
                    - determine <[1].flag[language]||en>
                - else:
                    - determine <empty>

qm_language:
    type: task
    script:
        - determine <empty>
        
    set:
        placeholder:
            - define placeholder:<[1]||<empty>>
            - define value:<[2]||<empty>>
            - define language_code:<[3]||<element[]>>

            - if <[placeholder]> != <empty>:
                - if <[value]> != <empty>:
                    - if <[language_code]> == *:
                        - foreach <yaml[lang].list_keys[placeholder]>:
                            - yaml id:lang placeholder.<[value]>.<[placeholder]>:!

                        - define language_code:<element[]>
                    
                    - if <[language_code]> != <element[]>:
                        - define placeholder:<[language_code]>.<[placeholder]>

                    - yaml id:lang set placeholder.<[placeholder]>:<[value]>


        player:
            language:
                - define target_player:<[1]||<empty>>
                - define target_langugage:<[2]||<empty>>

                - if <[target_player].is_player||false>:
                    - flag <[target_player]> language:<[target_langugage]>
    

qm_language_cmd:
    type: task
    script:
        - choose <[1].get[command]>:
            - case 'placeholder':
                - choose <[1].get[option]>:
                    - case list:
                        - narrate '<proc[qmp_language.list.placeholder].separated_by[, ]>'
                    - case get:
                        - define placeholder:<[1].get[args].get[1]||<empty>>
                        - if <[placeholder]> != <empty>:
                            - define value:<proc[qmp_language.get.placeholder].context[<[placeholder]>]>
                            - if <[value]> != <empty>:
                                - narrate <proc[qmp_language].context[placeholder_info|language|<map[placeholder/<[placeholder]>|value/<[value]>].escaped>]>
                            - else:
                                - narrate <proc[qmp_language].context[placeholder_not_set|language|<map[placeholder/<[placeholder]>].escaped>]>
                        - else:
                            - narrate <proc[qmp_language].context[placeholder_not_entered|language]>
                    - case set:
                        - define placeholder:<[1].get[args].get[1]||<empty>>
                        - if <[placeholder]> != <empty>:
                            - define value:<[1].get[args].get[2]||<empty>>
                            - if <[value]> != <empty>:
                                - run qm_language.set.placeholder def:<[placeholder]>|<[value]>
                                - narrate <proc[qmp_language].context[placeholder_updated|language|<map[placeholder/<[placeholder]>|value/<[value]>].escaped>]>
                            - else:
                                - narrate <proc[qmp_language].context[placeholder_value_not_entered|language|<map[placeholder/<[placeholder]>].escaped>]>
                        - else:
                            - narrate <proc[qmp_language].context[placeholder_not_entered|language]>
                    - case remove:
                        - define placeholder:<[1].get[args].get[1]||<empty>>
                        - if <[placeholder]> != <empty>:
                            - define value:<proc[qmp_language.get.placeholder].context[<[placeholder]>]>
                            - if <[value]> != <empty>:
                                - narrate <proc[qmp_language].context[placeholder_info|language|<map[placeholder/<[placeholder]>|value/<[value]>].escaped>]>
                            - else:
                                - narrate <proc[qmp_language].context[placeholder_not_set|language|<map[placeholder/<[placeholder]>].escaped>]>
                        - else:
                            - narrate <proc[qmp_language].context[placeholder_not_entered|language]>








#<proc[qmp_text].context[server_reloaded|server]>

            
        





# qm_lang:
#     type: task
#     debug: false
#     script:
#         - narrate 'invalid call to qm_lang'
#     add:
#         - define file:<[1]||null>
#         - if <[file]> != null:
#             - run qm_server.yaml.append_file def:lang|/serverdata/lang/<[file]>.yml


# qmp_lang:
#     type: procedure
#     debug: true
#     script:
#         - define p_target:<[1]>
#         - define option:<[2]>
#         - define category:<[3]||default>
#         - define subs:<[4]||null>

#         - define text:<yaml[lang].read[<[category]>.<[p_target].flag[lang]||en>.<[option]>]||<element[]>>
#         - if <[lang]> == '':
#             - define "text:<yaml[lang].read[<[category]>.en.<[option]>]||<element[Language entry missing: <[3]>:<[2]>]>>"

#         - determine <proc[qmp_lang_raw].context[<[lang]>|<[subs]>]>


# qmp_lang_raw:
#     type: procedure
#     debug: true
#     script:
#         - define raw_text:<[1]>
#         - define subs:<[2].unescaped||null>

#         - define text:<[raw_text]>

#         - if <[subs]> != null:
#             - foreach <[subs].as_map.keys>:
#                 - define text:<[lang].replace_text[$<[value]>$].with[<[subs].as_map.get[<[value]>]>]>

#         - foreach <yaml[lang].list_keys[placeholder.<[p_target].flag[lang]||en>]||<list[]>>:
#             - define placeholder:<yaml[lang].read[placeholder.<[p_target].flag[lang]||en>.<[value]>]||<element[]>>
#             - if <[placeholder]> == '':
#                 - define placeholder:<yaml[lang].read[placeholder.en.<[value]>]||$PLACEHOLDER_<[value]>$>

#             - define text:<[lang].replace_text[$PLACEHOLDER_<[value]>$].with[<[placeholder]>]>

#         - foreach <yaml[lang].list_keys[color]||<list[]>>:
#             - define text:<[lang].replace_text[$COLOR_<[value]>$].with[<&color[<yaml[lang].read[color.<[value]>]>]>]>

#         # - define text:<[lang].replace_text[$BUILD$].with[<proc[qmp_build]>]>

#         - determine <[lang].parse_color>


# qmw_lang:
#     type: world
#     debug: false
#     events:
#         on server start:
#             - ~run qmw_lang.load

#         on pre script reload:
#             - ~run qmw_lang.load
        
#         on script reload:
#             - ~run qmw_lang.load

#         on load:
#             - ~run qm_server.yaml.append_file def:lang|/serverdata/lang.yml
#             - ~run qm_server.yaml.append_file def:lang|/serverdata/lang/default.yml
#             - ~run qm_server.yaml.append_file def:lang|/serverdata/lang/lang.yml
#             - run qm_command.add.command def:qm_lang_cmd|lang
    
#     load:
#         - if <yaml.list.contains[lang]>:
#             - ~yaml unload id:lang
#         - ~yaml create id:lang

# qm_lang_cmd:
#     type: task
#     debug: false
#     script:
#         - define action:<[1]||null>
#         - define option:<[2]||get>
#         - define value:<[3]||null>

#         - choose <[option]>:
#             - case null get list:
#                 - narrate <proc[qmp_lang].context[<player||null>|lang_selected|lang|<map[lang/<player.flag[lang]||en>]>]>
#             - default:
#                 - narrate <proc[qmp_lang].context[<player||null>|command_invalid|command]>
