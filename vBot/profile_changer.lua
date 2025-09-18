ProfileChanger = {}

function ProfileChanger.changeProfile(profileIndex)
  if not modules or not modules.client_options or not modules.client_options.setOption then
  --  print("Error: 'modules.client_options.setOption' is not available. Cannot change profile.")
    return false
  end

  local numProfileIndex = tonumber(profileIndex)

  if not numProfileIndex or numProfileIndex < 1 or numProfileIndex > 10 then
    -- print("Error: Invalid profile index. Please provide a number between 1 and 10 (inclusive). Received: " .. tostring(profileIndex))
    return false
  end

  local profileIndexString = tostring(numProfileIndex)
  -- print("Attempting to change client profile to: " .. profileIndexString)

  -- Call the client's function to set the profile
  -- The client's own 'onProfileChange' and 'collectiveReload' functions should handle the rest.
  local success = modules.client_options.setOption('profile', profileIndexString)
  
  return success
end

-- Example of how to use this from the OTClient console or another script:
-- ProfileChanger.changeProfile(2) -- Changes to profile 2

-- print("vBot ProfileChanger script loaded. Use ProfileChanger.changeProfile(index) to change profiles.")