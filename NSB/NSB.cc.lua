-- NSB / New System Bootstrap v0.00
-- oneirosFade 2013
-- GPLv3 Licensed

-- Namespace
local nsb = {}

-- HTTP API Check
if (not http) then
  print("!! Enable HTTP before running this tool.")
  return false
else
  print("NSB New Systems Bootstrap")
end

-- GitHub Functionality
function nsb.gitGet (gUser, gProject, gFile)
  local gURL = "https://raw.github.com/" .. gUser .. "/" ..
                gProject .. "/" .. gFile
  local gResponse = http.get(gURL)
  if (not gResponse) then
    return nil
  end
  return gResponse.readAll()
end

-- Retrieve Tab Completion
print("Cloning ReadOverride for Tab Completion...")
local nsb.fileRaw = nsb.gitGet ("oneirosFade", "CC", "External/ReadOverride.cc.lua")
print("Installing ReadOverride...")
fs.makeDir("/sys")
local nsb.file = fs.open("/sys/ReadOverride.cc.lua", "w")
nsb.file.write(nsb.fileRaw)
nsb.file.close()
print("You must add a line to your startup which reads:")
print("  shell.run(\"/sys/ReadOverride.cc.lua\")")
print("and reboot for this to take effect.")


