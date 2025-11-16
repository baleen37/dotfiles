return function(args, completion)
 local aerospace_output = ""
 local aerospace_error = ""

 -- Dynamic aerospace path resolution
 local aerospace_path = "/run/current-system/sw/bin/aerospace"

 -- Fallback: try to find aerospace in common locations
 if not hs.fs.attributes(aerospace_path) then
   local possible_paths = {
     "/usr/local/bin/aerospace",
     "/opt/homebrew/bin/aerospace"
   }

   -- Also check nix store
   local find_cmd = hs.execute("find /nix/store -name 'aerospace' -type f -executable 2>/dev/null | head -1")
   if find_cmd and find_cmd ~= "" then
     table.insert(possible_paths, find_cmd:match("^%s*(.-)%s*$") or "")
   end

   for _, path in ipairs(possible_paths) do
     if hs.fs.attributes(path) then
       aerospace_path = path
       break
     end
   end
 end

local aerospace_task = hs.task.new(aerospace_path, function(err, stdout, stderr)
 print()
end, function(task, stdout, stderr)
 if stdout ~= nil then
  aerospace_output = aerospace_output .. stdout
 end
 if stderr ~= nil then
  aerospace_error = aerospace_error .. stderr
 end
 return true
end, args)
if type(completion) == "function" then
 aerospace_task:setCallback(function()
  completion(aerospace_output, aerospace_error)
 end)
end
aerospace_task:start()
end
