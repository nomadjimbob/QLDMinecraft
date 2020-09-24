# todo [1] etc should be escaped

qmw_skins:
    type: world
    debug: false
    events:
        on load:
            - run qm_skins.yaml.load
            # - run qm_lang.add def:skins
            - run qm_command.add.command def:qm_skins_cmd|skins|developer
            - run qm_command.add.tabcomplete def:skins|list
            - run qm_command.add.tabcomplete def:skins|save
            - run qm_command.add.tabcomplete def:skins|load|_*skins
            - run qm_command.add.tabcomplete def:skins|add
            # - run qm_command.add.tabcomplete def:prices|set|*_material|*_pricetype

                
        on save:
            - run qm_skins.yaml.save

qm_skins:
    type: task
    debug: false
    script:
        - narrate 'invalid call to qm_price'
    
    yaml:
        load:
            - if <server.has_file[/serverdata/skins.yml]>:
                - yaml load:/serverdata/skins.yml id:skins
            - else:
                - yaml create id:skins

            - run qm_skins.yaml.save

        save:
            - yaml savefile:/serverdata/skins.yml id:skins

qm_skin:
    type: task
    set:
        - define entity:<[1]||<empty>>
        - define skin_id:<[2]||<empty>>
        - if <[skin_id]> != <empty>:
            - if <[entity].is_player> || <[entity].is_npc>:
                - define skin_blob:<yaml[skins].read[skins.<[skin_id]>]||<empty>>
                - if <[skin_blob]> != <empty>:
                    - adjust <[entity]> skin_blob:<[skin_blob]>



qm_skins_cmd:
    type: task
    debug: true
    script:
        - define name:<[1].get[args].get[1]>

        - choose <[1].get[command]>:
            - case skins:
                - choose <[1].get[option]>:
                    - case save:
                        - if <[name]> != null:
                            - yaml id:skins set skins.<[name]>:<player.selected_npc.skin_blob>
                            - run qm_skins.yaml.save
                            - narrate <proc[qmp_language].context[skin_saved|skins|<map[skin/<[name]>].escaped>]>
                        - else:
                            - narrate <proc[qmp_language].context[skin_no_name_entered|skins]>
                    - case load:
                        - if <[name]> != null:
                            - if <yaml[skins].list_keys[skins].contains[<[name]>]>:
                                - adjust <player.selected_npc> skin_blob:<yaml[skins].read[skins.<[name]>]>
                            - else:
                                - narrate <proc[qmp_language].context[skin_not_exist|skins|<map[skin/<[name]>].escaped>]>
                        - else:
                            - narrate <proc[qmp_language].context[skin_no_name_entered|skins]>
                    - case list:
                        - foreach <yaml[skins].list_keys[skins]>:
                            - narrate '  - <[value]>'
                    - case add:
                        - if <[name]> != null:
                            - define url:<[1].get[args].get[2]||null>
                            - if <[url]> != null:
                                - narrate <proc[qmp_language].context[skin_downloading|skins|<map[url/<[url]>].escaped>]>
                                - ~webget https://api.mineskin.org/generate/url post:url=<[url]> timeout:30s save:res
                                - define result:<entry[res].result||null>
                                - if <[result]> != null:
                                    - yaml loadtext:<[result]> id:response
                                    - if <yaml[response].contains[data.texture]>:
                                        - yaml id:skins set skins.<[name]>:<yaml[response].read[data.texture.value]>;<yaml[response].read[data.texture.signature]>
                                        - run qm_skins.yaml.save
                                        - narrate <proc[qmp_language].context[skin_saved|skins|<map[skin/<[name]>].escaped>]>
                                    - else:
                                        - narrate <proc[qmp_language].context[skin_download_error|skins]>
                                - else:
                                    - narrate <proc[qmp_language].context[skin_download_error|skins]>
                            - else:
                                - narrate <proc[qmp_language].context[skin_no_url_entered|skins]>
                        - else:
                            - narrate <proc[qmp_language].context[skin_no_name_entered|skins]>




qmp_command_tabcomplete_skins:
    type: procedure
    debug: false
    script:
        - determine <yaml[skins].list_keys[skins]>

