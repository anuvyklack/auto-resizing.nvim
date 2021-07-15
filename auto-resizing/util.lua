local M = {}


---See documentation for `get_parent_col_frame()` function.
local function get_parent_col_frame_algorithm(layout, winid)
   local result = {}

   if type(layout[1]) == "string" then
      if layout[1] == "row" then
         result = get_parent_col_frame_algorithm(layout[2], winid)

      elseif layout[1] == "col" then
         result = get_parent_col_frame_algorithm(layout[2], winid)

         if result.found and not result.frame then
            result.frame = { "col", layout[2] }
         end

      elseif layout[1] == "leaf" and layout[2] == winid then
         result.found = true
      end
   elseif type(layout[1]) == "table" then
      for _, branch in pairs(layout) do
         result = get_parent_col_frame_algorithm(branch, winid)
         if result.found then break end
      end
   end

   return result
end


-- Return the nearest column type frame that contains desiared window.
---@param layout table table of the form like `vim.fn.winlayout()` function returns
---@param winid number see `:help winid`
function M.get_parent_col_frame(layout, winid)
   local result = get_parent_col_frame_algorithm(layout, winid)
   if result.found and not result.frame then
      result.frame = layout
   end
   return result.frame
end


-- Travers recursively through window layout looking for the longest row.
---@param layout table should be the output of the `vim.fn.winlayout()` function
---@param frame_type? # The type of the parent frame from which this function was called.
---|'"col"'  #return the length of the longest row in column
---|'"row"' #return the length of the row
---@return number #the length of the longest row in current frame
function M.calc_frame_max_row_length(layout, frame_type)
   local length = 0

   if type(layout[1]) == "string" then
      if layout[1] == "row" then
         length = M.calc_frame_max_row_length(layout[2], "row")

      elseif layout[1] == "col" then
         length = M.calc_frame_max_row_length(layout[2], "col")

      elseif layout[1] == "leaf" then
         return 1
      end

   elseif type(layout[1]) == "table" then
      for _, branch in pairs(layout) do
         local new_length = M.calc_frame_max_row_length(branch)

         if frame_type == "row" then
            length = length + new_length
         elseif frame_type == "col" and new_length > length then
            length = new_length
         end
      end
   end

   return length
end


-- Travers recursively through window layout looking for the longest row of
-- windows.
---@param layout table should be the output of the `vim.fn.winlayout()` function
---@param frame_type? # The type of the parent frame from which this function was called.
---|'"col"' #the parent frame is column
---|'"row"' #the parent frame is row
---@return table #the longest row of windows in current frame
function M.get_frame_longest_row(layout, frame_type)
   local output = {}

   if type(layout[1]) == "string" then
      if layout[1] == "row" then
         output = M.get_frame_longest_row(layout[2], "row")

      elseif layout[1] == "col" then
         output = M.get_frame_longest_row(layout[2], "col")

      elseif layout[1] == "leaf" then
         return { layout[2] }
      end

   elseif type(layout[1]) == "table" then
      for _, branch in pairs(layout) do
         local leafs = M.get_frame_longest_row(branch)

         if frame_type == "row" then
            for _, leaf in ipairs(leafs) do
               table.insert(output, type(leaf) == "number" and leaf or unpack(leaf))
            end

         elseif frame_type == "col" and #leafs > #output then
            output = leafs
         end
      end
   end

   return output
end

-- Takes parent column type frame that contains the desired window.
-- Return row of windows that contains the desired window from this frame.
---@param frame table table of the form like `vim.fn.winlayout()` function returns
---@param winid number see `:help winid`
function M.get_frame_row_that_contains_desired_win(frame, winid)
   frame = frame[2]

   local output = {}

   for i, row in ipairs(frame) do
      output[i] = {}
      for _, leaf in ipairs(row[2]) do
         table.insert(output[i], leaf[2])
      end
   end

   -- for i=1, #output do
   --    if M.array_contains(output[i], winid) then
   --       output = output[i]
   --       break
   --    end
   -- end

   for _, row in ipairs(output) do
      if M.array_contains(row, winid) then
         output = row
         break
      end
   end

   return output
end


-- Check if an array-like table contains the desired value.
function M.array_contains(array, value)
   for i=1, #array do
      if array[i] == value then
         return true
      end
   end
   return false
end


return M
