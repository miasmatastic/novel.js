
### GAME AREA ###

gameArea = new Vue(
  el: '#game-area'
  data: data
  methods:
    # Return whether the requirements of a choice have been filled
    requirementsFilled: (choice) ->
      return sceneManager.requirementsFilled(choice)

    # Return whether the text can be skipped
    textSkipEnabled: (choice) ->
      return data.game.currentScene.skipEnabled && data.game.settings.skipButtonShown

    # Check if specific item's count is over 0; if it isn't, it's not shown.
    itemsOverZero: (item) ->
      for i in @game.inventory
        if i.name == item.name
          if i.count > 0
            return true
      return false

    # Select a choice
    selectChoice: (choice) ->
      sceneManager.selectChoice(choice)
)