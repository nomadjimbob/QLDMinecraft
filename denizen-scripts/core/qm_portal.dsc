qmw_portal:
    type: world
    debug: true
    events:
        on load:
            - run qm_command.add.command def:qm_portal_cmd|portal|developer
            - run qm_command.add.tabcomplete def:portal|create
            - run qm_command.add.tabcomplete def:portal|link|_*portals|_*portals
            - run qm_command.add.tabcomplete def:portal|unlink||_*portals
            # - run qm_command.add.tabcomplete def:tp|_*tpnames
            - run qm_portal.yaml.load
        
        on save:
            - run qm_portal.yaml.save

        on player enters *:
            - define portal_name:<context.area.note_name||<empty>>
            - if <[portal_name]> != <empty> && <[portal_name].starts_with[qm_portal_]>:
                - define portal_name:<[portal_name].after_last[qm_portal_]>
                - define link:<yaml[portals].read[portals.<[portal_name]>.link]||<empty>>
                - if  <[link]> != <empty>:
                    - define location:<yaml[portals].read[portals.<[link]>.cuboid].center>
                    - if <[location].forward[5].material.name||<empty>> == air:
                        - teleport <player> <[location].forward[5]>
                    - else if <[location].left[5].material.name||<empty>> == air:
                        - teleport <player> <[location].left[5]>
                    - else if <[location].right[5].material.name||<empty>> == air:
                        - teleport <player> <[location].right[5]>
                    - else if <[location].backward[5].material.name||<empty>> == air:
                        - teleport <player> <[location].backward[5]>
                    - else:
                        - narrate <proc[qmp_language].context[no_safe_teleport|portals]>


qm_portal:
    type: task
    script:
        - determine <empty>
    
    sync:
        - foreach <server.notables[cuboids]>:
            - if <[value].note_name.starts_with[qm_portal_]>:
                - note remove as:<[value].note_name>
        
        - foreach <yaml[portals].list_keys[portals]||<list[]>>:
            - define region_cuboid:<yaml[portals].read[portals.<[value]>.cuboid]||<empty>>
            - if <[region_cuboid]> != <empty>:
                - note <[region_cuboid]> as:qm_portal_<[value]>

    yaml:
        load:
            - if <server.has_file[/serverdata/portals.yml]>:
                - ~yaml load:/serverdata/portals.yml id:portals
            - else:
                - ~yaml create id:portals
                - yaml savefile:/serverdata/portals.yml id:portals
            
            - run qm_portal.sync

        save:
            - yaml savefile:/serverdata/portals.yml id:portals


qm_portal_cmd:
    type: task
    debug: false
    script:
        - choose <[1].get[command]>:
            - case portal:
                - choose <[1].get[option]>:
                    - case create:
                        - define name:<[1].get[args].get[1]||<empty>>
                        - if <[name]> != <empty> && !<yaml[portals].list_keys[portals].contains[<[name]>]>:
                            - if <[1].get[player].we_selection||<empty>> != <empty>:
                                - yaml id:portals set portals.<[name]>.cuboid:<[1].get[player].we_selection>
                                - run qm_portal.yaml.save
                                - note <[1].get[player].we_selection> as:qm_portal_<[name]>
                                - narrate <proc[qmp_language].context[portal_created|portal|<map[portal/<[name]>].escaped>]>
                            - else:
                                - narrate <proc[qmp_language].context[no_selection|portal]>
                        - else:
                            - narrate <proc[qmp_language].context[portal_exists|portal]>

                    - case link:
                        - define name:<[1].get[args].get[1]||<empty>>
                        - define link:<[1].get[args].get[2]||<empty>>
                        - if <[name]> != <empty> && <yaml[portals].list_keys[portals].contains[<[name]>]>:
                            - if <[name]> != <empty> && <yaml[portals].list_keys[portals].contains[<[name]>]>:
                                - yaml id:portals set portals.<[name]>.link:<[link]>
                                - run qm_portal.yaml.save
                                - narrate <proc[qmp_language].context[portal_linked|portal|<map[portal/<[name]>|link/<[link]>].escaped>]>
                            - else:
                                - narrate <proc[qmp_language].context[portal_dest_not_exists|portal]>
                        - else:
                            - narrate <proc[qmp_language].context[portal_not_exists|portal]>

                    - case unlink:
                        - define name:<[1].get[args].get[1]||<empty>>
                        - if <[name]> != <empty> && <yaml[portals].list_keys[portals].contains[<[name]>]>:
                            - yaml id:portals set portals.<[name]>.link:!
                            - run qm_portal.yaml.save
                            - narrate <proc[qmp_language].context[portal_unlinked|portal|<map[portal/<[name]>].escaped>]>
                        - else:
                            - narrate <proc[qmp_language].context[portal_not_exists|portal]>

                    - default:
                        - narrate <proc[qmp_language].context[cmd_invalid_option|server]>


qmp_command_tabcomplete_portals:
    type: procedure
    script:
        - define portal_names:<yaml[portals].list_keys[portals]||<list[]>>
        - determine <[portal_names]>
        