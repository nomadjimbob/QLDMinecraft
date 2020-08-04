startstation:
  type: task
  debug: true
  script:
    - mount <player>|minecart <location[-18,64,215,island]>
    - adjust <player> velocity:<player.location.direction.vector.mul[3]>

#MineCartManagerEvents: 
  #type: world 
  #debug: true 
  #events: 
    #on player right clicks with MyCartItem: 
    #- determine passively cancelled 
    #- run s@MineCartManager def:<context.location>|<context.item> 

    #on player exits minecart: 
    #- remove minecart 
    #- give <player> 'i@MyCartItem'
    #- give 'MyCartItem'

    #on minecart collides with minecart: 
    #- determine cancelled   # blocks minecraft bumpinh

    #on player enters minecart:
    #- define Vehicle <context.vehicle>
    #- adjust <[Vehicle]> speed:3

#MineCartManager:
  #type: task 
  #debug: true 
  #script: 
    #- define rails 'm@rails|m@powered_rail' 
    #- if !<def[rails].contains[<def[1].material>]>:
    #  - stop 
    #- mount <player>|minecart <def[1].add[0,1,0]> 
    #- take 'MyCartItem'

#MyCartItem: 
  #type: item 
  #material: minecart 
  #display name: <&3>My Cart 
  #lore: 
  #- Your personal Minecart 
  #- Keep it with you always 
  #bound: true 
