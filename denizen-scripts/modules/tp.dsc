qmw_tp:
    type: world
    debug: false
    events:
        on load:
            - run qm_command.add.command def:qm_tp_cmd|tp|developer
            - run qm_command.add.tabcomplete def:tp|_*tpnames
            - run qm_command.add.tabcomplete def:tp|graveyard|_*regions
            - run qm_command.add.tabcomplete def:tp|region|_*regions


qm_tp_cmd:
    type: task
    debug: false
    script:
        - define value:<[1].get[args].get[1]||null>

        - choose <[1].get[command]>:
            - case tp:
                - choose <[1].get[option]>:
                    - case region rg:
                        - define location:<yaml[regions].read[regions.<[value]>.cuboid].center||<empty>>
                        - chunkload <[location].chunk>

                        - if <[location]> != <empty>:
                            - teleport <[location].highest.up[2]>
                        - else:
                            - narrate <proc[qmp_language].context[unknown_region|tp]>
                    - case graveyard:
                        - define location:<yaml[regions].read[regions.<[value]>.graveyard]||<empty>>

                        - if <[location]> != <empty>:
                            - teleport <[location]>
                        - else:
                            - narrate <proc[qmp_language].context[unknown_region|tp]>
                    - default:
                        - narrate <proc[qmp_language].context[cmd_invalid_option|server]>

qmp_command_tabcomplete_tpnames:
    type: procedure
    script:
        - define tpnames:<list[graveyard|region|randomily]>
        - determine <[tpnames]>
        