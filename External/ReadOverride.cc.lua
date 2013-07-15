--[[
Modified read() with Tab-Completion v2.2 by Espen
Original from shell-file of ComputerCraft v1.46

Changelog:
v2.2 -  Fixed: Entering a folder name completely and then pressing TAB didn't append a slash.
v2.1 -  Added: Directory-Matches now have slashes appended to them.
        Changed: COMPLETION_QUERY_ITEMS was hardcoded to 19, is now height of respective terminal.
        Fixed: Pressing SPACE for listing multiple pages of matches "blanked out" the screen.
        Fixed: TAB completion was engaged even if cursor was not at the end of the line.
        Fixed: Path-resolving for directory-detection wasn't quite right.
v2.0 -  Changed the previously mixed Windows<->Linux TAB completion behaviour completely to Linux-style (except for column-display).
        Added: Display of all possible matches.
        Added: MORE-functionality for displaying possibilities greater than a certain number ( COMPLETION_QUERY_ITEMS )
-----------------------------------------------------------------------------------------------
v1.2 -  Added a separate program to to allow runtime-injection of the custom read() into the running shell of an individual computer.
        Thanks @BigSHinyToys for making me aware of the global table's dropped protection. ^_^
v1.12 - Fixed: Pressing Tab without entering anything threw an error.
v1.11 - Removed previously introduced, but now unnecessary parameter from read()
v1.1 -  Path traversal implemented
v1.0 -  Initial release
--]]

local _, COMPLETION_QUERY_ITEMS = term.getSize()

local promptColour, textColour, bgColour
if term.isColor() then
  promptColour = colors.yellow
  textColour = colors.white
  bgColour = colors.black
else
  promptColour = colors.white
  textColour = colors.white
  bgColour = colors.black
end

-- Returns the index up to which the two passed strings equal.
-- E.g.: "Peanut" and "Peacock" would result in 3
local function getMaxCommonIndex( _sOne, _sTwo )
  local longWord
  local shortWord

  -- Determine longer word
  if #_sOne > #_sTwo then
    longWord = _sOne
    shortWord = _sTwo
  else
    longWord = _sTwo
    shortWord = _sOne
  end

  -- Iterate over all chars from longWord
  for i = 1, #longWord do
    -- Check if the current char of longWord equals the one of shortWord
    if (longWord:sub(i, i) ~= shortWord:sub(i, i)) then
      -- Return the last index at which the chars were still equal
      return (i - 1)
    end
  end
end

-- Returns the string which is common to all strings in the passed table, starting from the first character.
-- E.g.: { "Peanut", "Peacock" } would result in "Pea"
local function getMaxCommonString( _tStrings )
  local nInCommon
  local nSmallestCommonality
  local sResult = _tStrings[1]

  -- Iterate over all strings in the passed table
  for i = 1, #_tStrings do
    -- As long as there is one more string to compare with, then...
    if _tStrings[i + 1] ~= nil then
      nInCommon = getMaxCommonIndex(_tStrings[i], _tStrings[i + 1])

      -- Only retain the smallest index (and string) up to which the last two compared strings were equal.
      if (not nSmallestCommonality) or (nInCommon < nSmallestCommonality) then
        nSmallestCommonality = nInCommon
        sResult = _tStrings[i + 1]:sub(1, nSmallestCommonality)
      end
    end
  end

  return sResult
end


local function read( _sReplaceChar, _tHistory )
  term.setCursorBlink( true )

  local sLine = ""
  local tMatches = {}
  local TABPressedBefore = false
  local nHistoryPos = nil
  local nPos = 0
  if _sReplaceChar then
    _sReplaceChar = string.sub( _sReplaceChar, 1, 1 )
  end

  local w, h = term.getSize()
  local sx, sy = term.getCursorPos()

  local function redraw( _sCustomReplaceChar )
    local nScroll = 0
    if sx + nPos >= w then
      nScroll = (sx + nPos) - w
    end

    term.setCursorPos( sx, sy )
    local sReplace = _sCustomReplaceChar or _sReplaceChar
    if sReplace then
      term.write( string.rep(sReplace, string.len(sLine) - nScroll) )
    else
      term.write( string.sub( sLine, nScroll + 1 ) )
    end
    term.setCursorPos( sx + nPos - nScroll, sy )
  end

  while true do
    local sEvent, param = os.pullEvent()

    if sEvent == "char" then
      TABPressedBefore = false  -- Reset tab-hit.
      tMatches = {}  -- Reset completion match-table.
      sLine = string.sub( sLine, 1, nPos ) .. param .. string.sub( sLine, nPos + 1 )
      nPos = nPos + 1
      redraw()

    elseif sEvent == "key" then
      if not (param == keys.tab) then
        TABPressedBefore = false   -- Reset tab-hit.
        tMatches = {}   -- Reset completion match-table.
      end

      -- Enter
      if param == keys.enter then
        break

      -- Tab (allowed only if the cursor is at the end of the line)
      elseif (param == keys.tab) and (nPos == #sLine) then
        -- [[ TAB was hit the second time in a row. ]]
        if TABPressedBefore then
          if #tMatches >= COMPLETION_QUERY_ITEMS then

            local function askForContinuation( _count )
              write("\nDisplay all " .. _count .. " possibilities? (y or n)")
              while true do
                local _, char = os.pullEvent("char")

                if char:lower() == "y" then
                  return true
                elseif char:lower() == "n" then
                  return false
                end
              end
            end

            -- Arguments: _tLines (expected: String table)
            local function more( _tLines )
              -- Asking for continuation if too many lines
              if #_tLines >= COMPLETION_QUERY_ITEMS and ( not askForContinuation(#_tLines) ) then
                print()
                return
              end

              -- Initializing
              local pressedENTER
              local _, h = term.getSize()
              print()

              -- Iterate through lines and display them
              local nLinesPrinted = 0
              for i = 1, #_tLines do
                print(_tLines[i])
                nLinesPrinted = nLinesPrinted + 1
                local _, y = term.getCursorPos()

                -- If we reach the end of the screen and there is more to come => wait for user input.
                if ( pressedENTER or ( nLinesPrinted % (h - 1) == 0 ) ) and ( i < #_tLines ) then
                  pressedENTER = false
                  write("--More--")
                  while true do
                    local event, param = os.pullEvent()

                    if event == "key" then
                      -- ENTER (Scroll a line)
                      if param == keys.enter then
                        pressedENTER = true
                        term.scroll(1)
                        term.setCursorPos(1, y - 1)
                        term.clearLine()
                        break

                      -- BACKSPACE (Cancel)
                      elseif param == keys.backspace then
                        term.setCursorPos(1, y)
                        term.clearLine()
                        return
                      end

                    -- SPACE (Scroll a page)
                    elseif event == "char" and param == " " then
                      term.setCursorPos(1, 1)
                      term.clear()
                      nLinesPrinted = 0   -- Reset, because we will begin with a new screen.
                      break
                    end
                  end
                end
              end
            end

            more(tMatches)
            local _, y = term.getCursorPos()
            term.setBackgroundColor( bgColour )
            term.setTextColor( promptColour )
            write( shell.dir() .. "> " .. sLine )
            term.setTextColor( textColour )
            sy = y
            redraw()

          elseif #tMatches > 1 then
            local x, y = term.getCursorPos()

            print()
            for k, v in ipairs(tMatches) do
              y = y + 1
              print(v)
            end

            term.setBackgroundColor( bgColour )
            term.setTextColor( promptColour )
            write( shell.dir() .. "> " .. sLine )
            term.setTextColor( textColour )

            -- Increment y coordinate only if not on the last line.
            if y < h then
              sy = y + 1
            else
              sy = h
            end

            redraw()
          end

        -- [[ TAB was hit once => no matches yet, look for some now. ]]
        else
          tMatches = {}   -- Reset completion match-table.
          TABPressedBefore = true

          local sLastPar = string.match( sLine, "[^%s]+$" ) or ""     -- Get last entered parameter.
          -- local sToMatch = string.match( sLastPar, "[^%s/\.]+$" ) or ""   -- Get filename-part of sLastPar.
          local sToMatch = string.match( sLastPar, "[^/%.]+$" ) or ""   -- Get filename-part of sLastPar.

          local sAbsPath = shell.resolve( sLastPar )  -- Get absolute path of the entered location.
          -- Append a slash to that (e.g. "/rom/progr" -> "rom" -> "rom/")
          if sAbsPath:sub(#sAbsPath) ~= "/" then
            sAbsPath = sAbsPath .. "/"
          end

          -- Is NOT a directory
          if not fs.isDir( sAbsPath ) then
            sAbsPath = string.match( sAbsPath, "^([^%s]+[/\])[^%s/\]+[/\]?$" )  -- Cut off filename, e.g. /some/test/path -> /some/test/

          -- IS a directory
          else
            -- If it is a directory but has no / at the end, append one.
            if (sLine:sub(#sLine) ~= "/") and (#sLastPar > 0) then
              sLine = sLine .. "/"
              nPos = nPos + 1
              TABPressedBefore = false
            end
          end
          -- The root folder is the path, so resolve that one.
          if not sAbsPath then sAbsPath = shell.resolve( "/" ) end

          -- Search for matches in the resolved folder.
          local ok, tFileList = pcall( fs.list, sAbsPath )
          if ok then
            local match = nil
            -- Populate table with all matches.
            for k, v in ipairs(tFileList) do
              match = string.match( v, "^"..sToMatch..".*$" )
              if match then
                local combinedPath = "/" .. fs.combine(sAbsPath, match)
                if fs.isDir(shell.resolve(combinedPath)) then match = match .. "/" end
                table.insert( tMatches, match )
              end
            end
          end

          -- Show the smallest match
          local partialMatch = string.gsub( getMaxCommonString( tMatches ) or "", "^"..sToMatch, "" ) -- Cut off partial input from match.
          sLine = sLine .. partialMatch -- Complete partial input with prior cut off match.
          nPos = nPos + string.len( partialMatch )
          redraw()
          -- if partialMatch:sub(#partialMatch) == "/" then TABPressedBefore = false end
          if partialMatch:sub(#partialMatch) == "/" then
            -- Reset matches and TABPressedBefore status.
            tMatches = {}
            TABPressedBefore = false
          end
        end

      -- Left
      elseif param == keys.left then
        if nPos > 0 then
          nPos = nPos - 1
          redraw()
        end

      -- Right
      elseif param == keys.right then
        if nPos < string.len(sLine) then
          nPos = nPos + 1
          redraw()
        end

      -- Up or down
      elseif param == keys.up or param == keys.down then
        if _tHistory then
          redraw(" ")

          -- Up
          if param == keys.up then
            if nHistoryPos == nil then
              if #_tHistory > 0 then
                nHistoryPos = #_tHistory
              end
            elseif nHistoryPos > 1 then
              nHistoryPos = nHistoryPos - 1
            end

          -- Down
          else
            if nHistoryPos == #_tHistory then
              nHistoryPos = nil
            elseif nHistoryPos ~= nil then
              nHistoryPos = nHistoryPos + 1
            end
          end

          if nHistoryPos then
            sLine = _tHistory[nHistoryPos]
            nPos = string.len( sLine )
          else
            sLine = ""
            nPos = 0
          end
          redraw()
        end

      -- Backspace
      elseif param == keys.backspace then
        if nPos > 0 then
          redraw(" ")
          sLine = string.sub( sLine, 1, nPos - 1 ) .. string.sub( sLine, nPos + 1 )
          nPos = nPos - 1
          redraw()
        end

      -- Home
      elseif param == keys.home then
        nPos = 0
        redraw()

      -- Delete
      elseif param == keys.delete then
        if nPos < string.len(sLine) then
          redraw(" ")
          sLine = string.sub( sLine, 1, nPos ) .. string.sub( sLine, nPos + 2 )
          redraw()
        end

      -- End
      elseif param == keys["end"] then
        nPos = string.len(sLine)
        redraw()
      end
    end
  end

  term.setCursorBlink( false )
  term.setCursorPos( w + 1, sy )
  print()

  return sLine
end

_G.read = read