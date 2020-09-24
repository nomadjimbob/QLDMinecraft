qmw_prices:
    type: world
    debug: false
    events:
        on load:
            - run qm_prices.yaml.load
            
            - run qm_command.add.command def:qm_prices_cmd|prices
            # line above is erroring
            - run qm_command.add.tabcomplete def:prices|get|*_material|*_pricetype
            - run qm_command.add.tabcomplete def:prices|set|*_material|*_pricetype

                
        on save:
            - run qm_prices.yaml.save

qm_prices:
    type: task
    debug: false
    script:
        - narrate 'invalid call to qm_price'
    
    yaml:
        load:
            - if <server.has_file[/serverdata/prices.yml]>:
                - yaml load:/serverdata/prices.yml id:prices
            - else:
                - yaml create id:prices

            - run qm_prices.yaml.save

        save:
            - yaml savefile:/serverdata/prices.yml id:prices

qmp_prices:
    type: procedure
    debug: false
    script:
        - determine null
    
    get:
        # player selling item
        sell:
            price:
                - define target_material_name:<[1]||null>
                - determine <yaml[prices].read[prices.<[target_material_name]>].div[4].mul[3]||-1>
            price_text:
                - define target_material_name:<[1]||null>
                - define cost:<yaml[prices].read[prices.<[target_material_name]>].div[4].mul[3]||-1>
                - if <[cost]> < 0:
                    - determine <proc[qmp_language].context[not_interested|price]>
                    # - determine <proc[qmp_language].context[not_for_sale|price]>
                - else if <[cost]> == 0:
                    - determine <proc[qmp_language].context[free|price]>
                - else:
                    - determine <proc[qmp_server.format.money].context[<[cost]>]>
        
        # player buying item
        buy:
            price:
                - define target_material_name:<[1]||null>
                - determine <yaml[prices].read[prices.<[target_material_name]>]||-1>
            price_text:
                - define target_material_name:<[1]||null>
                - define cost:<yaml[prices].read[prices.<[target_material_name]>]||-1>
                - if <[cost]> < 0:
                    - determine <proc[qmp_language].context[not_for_sale|price]>
                    # - determine <proc[qmp_language].context[not_interested|price]>
                - else if <[cost]> == 0:
                    - determine <proc[qmp_language].context[not_for_sale|price]>
                    # - determine <proc[qmp_language].context[not_interested|price]>
                - else:
                    - determine <proc[qmp_server.format.money].context[<[cost]>]>
        


qm_prices_cmd:
    type: task
    debug: true
    script:
        - define action:<[1]||null>
        - define option:<[2]||null>
        - define material:<[3]||null>
        - define pricetype:<[4]||null>
        - define price:<[5]||null>

        - choose <[action]>:
            - case prices:
                - choose <[option]>:
                    - case test2:
                        - define i:<server.recipe_result[cooked_salmon_from_smoking]>
                        - narrate <[i].material.name>
                    - case test:
                        - foreach <yaml[prices].list_keys[prices]>:
                            - define new_price:<yaml[prices].read[prices2.<[value]>]||null>
                            - if <[new_price]> != null:
                                - yaml id:prices set prices.<[value]>:<[new_price]>
                                - yaml id:prices set prices2.<[value]>:!
                        - run qm_prices.yaml.save
                    - case get:
                        - if <[material]> != null:
                            - if <[pricetype]> == buy || <[pricetype]> == sell:
                                - narrate <proc[qmp_prices.get.<[pricetype]>.price].context[<[material]>]>
                            - else:
                                - narrate 'xxInvalid price tpye'
                        - else:
                            - narrate 'xxNo valid material was entered'
                    - case set:
                        - if <[material]> != null:
                            - if <[pricetype]> == buy || <[pricetype]> == sell:
                                - if <[price]> != null:
                                    - yaml id:prices set prices.<[material]>.<[pricetype]>:<[price]>
                                    - narrate 'xxprice updated'
                                - else:
                                    - narrate 'xxno price set'
                            - else:
                                - narrate 'xxinvalid price type
                        - else:
                            - narrate 'xxinvalid material'


qmp_command_tabcomplete_pricetype:
    type: procedure
    debug: false
    script:
        - determine <buy|sell>

qm_price_test:
    type: task
    script:
        - foreach <yaml[prices].list_keys[prices2]>:
            - if <yaml[prices].read[prices.<[value]>]||<empty>> == <empty>:
                - if <yaml[prices].read[prices2.<[value]>]||0> != 0:
                    - yaml id:prices set prices.<[value]>:<yaml[prices].read[prices2.<[value]>]||0>
                    - narrate '<[value]> - <yaml[prices].read[prices2.<[value]>]||0>'
                - else:
                    - yaml id:prices set prices.<[value]>:-1
                    - narrate '<[value]> - -1'
                
            - yaml savefile:/serverdata/prices.yml id:prices