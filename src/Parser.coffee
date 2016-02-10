
### PARSERS ###

Parser = {

  # Parse a string of items and output an array
  parseItemOrStats: (items) ->
    separate = items.split("|")
    parsed = []
    for i in separate
      i = i.substring(0, i.length - 1)
      i = i.split("[")
      parsed.push(i)
    return parsed

  # Parse a text for Novel.js tags, and replace them with the correct HTML tags.
  parseText: (text) ->
    if text != undefined
      for i in [0 .. 99]
        text = text.split("[s" + i + "]").join("<span class=\"highlight-" + i + "\">")
      text = text.split("[/s]").join("</span>")
      splitText = text.split(/\[|\]/)
      spansToBeClosed = 0
      asToBeClosed = 0
      for index in [0 .. splitText.length-1]
        s = splitText[index]
        if s.substring(0,2) == "if"
          parsed = s.split("if ")
          if !@parseStatement(parsed[1])
            splitText[index] = "<span style=\"display:none;\">"
            spansToBeClosed++
          else
            splitText[index] = ""
        else if s.substring(0,5) == "stat."
          value = s.substring(5,s.length)
          for i in data.game.stats
            if i.name == value
              splitText[index] = i.value
        else if s.substring(0,4) == "inv."
          value = s.substring(4,s.length)
          for i in data.game.inventory
            if i.name == value
              splitText[index] = i.count
        else if s.substring(0,5) == "print"
          parsed = s.split("print ")
          splitText[index] = @parseStatement(parsed[1])
        else if s.substring(0,5) == "input"
          parsed = s.split("input ")
          nameText = ""
          for i in data.game.stats
            if i.name == parsed[1]
              nameText = i.value
          splitText[index] = "<input type=\"text\" value=\"" + nameText + "\" name=\"input\" class=\"input-" + parsed[1] +  "\">"
        else if s.substring(0,6) == "choice"
          parsed = s.split("choice ")
          splitText[index] = "<a href=\"#\" onclick=\"Scene.selectChoiceByName('"+parsed[1]+"')\">"
          asToBeClosed++
        else if s.substring(0,7) == "/choice"
          if asToBeClosed > 0
            splitText[index] = "</a>"
            asToBeClosed--
          else
            splitText[index] = ""
        else if s.substring(0,3) == "/if"
          if spansToBeClosed > 0
            splitText[index] = "</span>"
            spansToBeClosed--
          else
            splitText[index] = ""
        index++
      text = splitText.join("")
      return text

  # Parse a statement that returns true or false or calculate a value
  parseStatement: (s) ->
    if !Util.validateParentheses(s)
      console.error "ERROR: Invalid parentheses in statement"
    s = s.replace(/\s+/g, '');
    parsedString = s.split(/\(|\)|\+|\*|\-|\/|<=|>=|<|>|==|!=|\|\||&&/)
    parsedValues = []
    for val in parsedString
      type = null
      if val.substring(0,5) == "stat."
        type = "stats"
      else if val.substring(0,4) == "inv."
        type = "item"
      else if val.substring(0,4) == "var."
        type = "var"
      else if !isNaN(parseFloat(val)) && val.toString().indexOf(".") == -1
        type = "int"
      else if !isNaN(parseFloat(val)) && val.toString().indexOf(".") != -1
        type = "float"
      else
        type = "string"
      switch type
        when "item"
          for i in data.game.inventory
            if i.name == val.substring(4,val.length)
              parsedValues.push i.count
        when "stats"
          for i in data.game.stats
            if i.name == val.substring(5,val.length)
              parsedValues.push i.value
        when "var"
          val = @findValue(val.substring(4,val.length),true)
          if !isNaN(parseFloat(val))
            parsedValues.push val
          else
            parsedValues.push "'" + val + "'"
        when "float"
          parsedValues.push parseFloat(val)
        when "int"
          parsedValues.push parseInt(val)
        when "string"
          if val != ""
            parsedValues.push "'" + val + "'"
          else
            parsedValues.push ""
    for i in [0 .. parsedString.length-1]
      if parsedString[i] != "" && parsedValues[i] != ""
        s = s.replace(new RegExp(parsedString[i],'g'),parsedValues[i])
    return eval(s)

  # Find a value from the game data json
  # toPrint == true returns the value, toPrint == false returns the object
  findValue: (parsed, toPrint) ->
    splitted = parsed.split(",")
    if !toPrint
      if splitted.length > 1
        variable = @findValueByName(data.game,splitted[0])[0]
      else
        variable = @findValueByName(data.game,splitted[0])[1]
    else
      variable = @findValueByName(data.game,splitted[0])[0]
    for i in [0 .. splitted.length - 1]
      if Util.isOdd(i)
        variable = variable[parseInt(splitted[i])]
      else if i != 0
        if !toPrint
          variable = @findValueByName(variable,splitted[i])[1]
        else
          if splitted[i] == "parsedText" || splitted[i] == "text"
            splitted[i] = "parsedText"
            variable.parsedText = Parser.parseText(variable.text)
          variable = @findValueByName(variable,splitted[i])[0]
    return variable

  # Find an object from the object hierarchy by string name
  findValueByName: (obj, string) ->
    parts = string.split('.')
    newObj = obj[parts[0]]
    if parts[1]
      parts.splice 0, 1
      newString = parts.join('.')
      return @findValueByName(newObj, newString)
    r = []
    r[0] = newObj
    r[1] = obj
    return r

}