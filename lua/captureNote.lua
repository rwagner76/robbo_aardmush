local state = 0
local caughtheader = false
local noteData = {}

-- States:
-- 0: waiting for note
-- 1: caught first divider, waiting for header
-- 2: caught second divider, capture note body
--


function captureDivider(name,line,wildcards)
   if state == 0 then
      state = 1
      caughtheader = false
      noteData = {}
      table.insert(noteData,line)
   elseif state == 1 then
      table.insert(noteData,line)
      if caughtheader == false then state = 0 return end
      EnableTrigger("trg_noteBody",true)
      state = 2
   elseif state == 2 then
      EnableTrigger("trg_noteBody",false)
      table.insert(noteData,line)
      state = 0
      Note("Captured note. Type 'copynote' to copy the contents to your clipboard.")
   end
end

function captureHeader(name,line,wildcards)
   caughtheader = true
   table.insert(noteData,line)
end

function captureBody(name,line,wildcards)
   table.insert(noteData,line)
end


function copyNoteClipboard(name,line,wildcards)
   SetClipboard(table.concat(noteData,"\n"))
   Note("Contents of last note copied to clipboard.")
end

