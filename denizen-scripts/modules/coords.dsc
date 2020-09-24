qmw_coords:
    type: world
    debug: false
    events:
        on player walks:
            - if <player.has_flag[coords]>:
                - actionbar "<&e>X: <&f><context.new_location.x.round_down>   <&e>Y: <&f><context.new_location.y.round_down>   <&e>Z: <&f><context.new_location.z.round_down>   <&e>Face: <&f><context.new_location.yaw.simple>   <&e>Biome: <&f><context.new_location.biome.name>   <&e>Rgn: <&f><player.flag[region]||none>"

        on load:
            - run qm_command.add.command def:qm_coords_cmd|coord|developer

qm_coords_cmd:
    type: task
    debug: false
    script:
        - choose <[1].get[command]>:
            - case coord coords:
                - define option:<[1].get[option]>
                - if <[option]> == <empty>:
                    - define option:toggle

                - choose <[option]>:
                    - case toggle <empty>:
                        - if <player.flag[coords]||0> == 0:
                            - flag player coords:1
                            - narrate <proc[qmp_language].context[coords_enabled|coords]>
                        - else:
                            - flag player coords:!
                            - narrate <proc[qmp_language].context[coords_disabled|coords]>
                    - case enable enabled true yes:
                        - flag player coords:1
                        - narrate <proc[qmp_language].context[coords_enabled|coords]>
                    - case disable disabled false no:
                        - flag player coords:!
                        - narrate <proc[qmp_language].context[coords_disabled|coords]>
