player_cooldown:
    type: world
    debug: false
    events:
        on player joins:
            - flag player damage_cooldown:<util.time_now.epoch_millis>
        
        on player respawns:
            - flag player damage_cooldown:<util.time_now.epoch_millis>
        
        on entity teleports:
            - if <context.entity.is_player>:
                - flag player damage_cooldown:<util.time_now.epoch_millis>

        on entity damaged:
            - if <context.entity.is_spawned> && <context.entity.is_player>:
                - if <util.time_now.epoch_millis.sub[<player.flag[damage_cooldown]||0>]> < <yaml[server].read[player.cooldown_duration]||5000>:
                    - determine cancelled
                - else:
                    - flag player damage_cooldown:!
