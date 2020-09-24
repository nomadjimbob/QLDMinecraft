qmc_bugreport:
    type: command
    debug: false
    name: bug
    description: Reports a bug
    usage: /bug [details]
    script:
        - if <context.args.size> > 0:
            - define selected_npc:<player.selected_npc||<empty>>
            - if <[selected_npc].is_npc||false>:
                - define 'selected_npc:<[selected_npc].name> (<[selected_npc].id>)'
            - else:
                - define selected_npc:none
            
            - define player_data:<yaml[<player.uuid>].to_text.base64_encode>

            # - narrate <context.raw_args>

            - narrate '<&3>[BUG REPORT]: Submitting report...'
            - ~webget https://play.qldminecraft.com.au/bridge/ 'data:{"command":"bugreport", "player":"<player.name.url_encode> (<player.uuid.url_encode>)", "location":"<player.location.url_encode>", "selected npc":"<[selected_npc].url_encode>", "message":"<context.raw_args.url_encode>", "player data":"<[player_data]>"}' headers:<map.with[Content-Type].as[application/json]> save:request
            - if <entry[request].result.starts_with[ok]>:
                - define bug_id:<entry[request].result.after[ok:]||<empty>>
                - if <[bug_id]> != <empty>:
                    - yaml id:<player.uuid> set bugreports
                    - define 'bug_id: - Bug ID: #<[bug_id]>'
                - narrate '<&3>[BUG REPORT]: Your bug report has been sent<[bug_id]>'
            - else:
                - narrate '<&3>[BUG REPORT]: An error occured sending the report'
        - else:
            - narrate '<&3>[BUG REPORT]: You need to enter details about the bug'
