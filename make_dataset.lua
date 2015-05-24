------------------------------------------------------------------------------
-- This script loads the KITTI dataset
-- Aysegul Dundar 
-- e-mail : adundar@purdue.edu  
------------------------------------------------------------------------------

-- Requires ------------------------------------------------------------------
require 'image'  
require 'sys'
require 'xml'
require 'kitti2Dbox'


-- Exporting functions to the global namespace -------------------------------
local max = math.max
local min = math.min
local floor = math.floor


-- Title ---------------------------------------------------------------------
print [[
********************************************************************************
>>>>>>>>>>>>>> Torch interface to KITTI dataset <<<<<<<<<<<<<<<<<<<<<
********************************************************************************
]]

-- Parsing the command line --------------------------------------------------
if not opt then
   print '==> processing options'
   cmd = torch.CmdLine()
   cmd:text('Opions')
   cmd:option('-datadir',  'data',     'directory to save data')
   cmd:option('-width',       128,     'width of extracted patch')
   cmd:option('-height',      128,     'height of extracted patch')
   cmd:option('-objects',    false,     'save data for objects, otherwise backgrounds')
   cmd:text()
   opt = cmd:parse(arg or {})
end



-- Global functions ----------------------------------------------------------
-- Parse XML
function parseXML(tracklet_labels)
   local parse = xml.parse(tracklet_labels)
   local tracklet = parse.boost_serialization.tracklets

   return tracklet
end


-- Extract object patches
function extractObjects(dspath, tracklet, vfile)
   local list = paths.dir(dspath)

   -- exclude hidden files and exceptions [char(46) = '.']
   for i = #list, 1, -1 do
      if string.byte(list[i], 1) == 46 then
         table.remove(list, i)
      end
   end
   -- print(list)

   videoframes = #list
   print('videoframes',videoframes)
   for imgi = 1,videoframes do
      rawFrame = image.loadPNG(tostring(dspath..string.format("%010u", imgi-1)..'.png'))
      local detections = {}
      for k=1, tracklet.count do
         first = tonumber(tracklet.item[k].first_frame)
         count = tonumber(tracklet.item[k].poses.count)+first
         if  first<imgi and imgi<=count then
            iwidth = rawFrame:size(3)
            iheight = rawFrame:size(2)

            if tracklet.item[k].poses.item[imgi-first] then 
               box = kitti2Dbox(tracklet.item[k].poses.item[imgi-first], tracklet.item[k])
               box.x1 = max(1, min(iwidth, box.x1))
               box.y1 = max(1, min(iheight, box.y1))
               box.x2 = max(1, min(iwidth, box.x2))
               box.y2 = max(1, min(iheight, box.y2))
               if opt.objects then
                  box.objectType = tracklet.item[k].objectType
               else -- if we want bg, we get a sample around (above of) the detection:

                  -- box.x1 = math.random(1, iwidth-opt.width)
                  -- box.y1 = math.random(1, iheight-opt.height)
                  -- box.x2 = box.x1 + opt.width
                  -- box.y2 = box.y1 + opt.height
                  box.x1 = box.x1
                  box.x1 = box.y1 + opt.height
                  box.x2 = box.x1 + opt.width
                  box.y2 = box.y1 + opt.height
                  box.objectType = 'bg'
               end

               local ldir = opt.datadir ..'/'.. box.objectType
               os.execute("mkdir -p " .. ldir)
               local number = #paths.dir(ldir)

               local centerx = floor(box.x1 + (box.x2-box.x1)/2)
               local centery = floor(box.y1 + (box.y2-box.y1)/2)

               local x = centerx - floor(opt.width/2)
               local y = centery - floor(opt.height/2)  
             
               local w = x + opt.width - 1
               local h = y + opt.height - 1  
    
               if x >= 1 and y >= 1 and w <= iwidth and h <= iheight then
                   local sample = rawFrame[{ {}, {y, h}, {x, w} }]:clone()
                   image.saveJPG(ldir ..'/'..vfile..'-'..box.objectType..'-'..  tostring(number)..'.jpg', sample)
               end
            end
         end
      end
   end
end


-- Main program -------------------------------------------------------------
datafiles = {1,2,5,9,11,13,14,17,18,19,20,22,23,35,36,39,46,51,56,57,59,60,61,64,79,84,86,87,91,93}
-- save objects: cars, pedestrians... etc
if opt.objects then
   local dspath = '/Users/eugenioculurciello/Code/datasets/KITTI/'

   for i = 1, #datafiles do
      local vfile = '2011_09_26_drive_'.. string.format("%04d", datafiles[i]) ..'_sync'

      print('==> loading KITTI tracklets and parsing the XML file: ' .. vfile)

      local img_path = dspath .. vfile ..  '/image_02/data/'
      local tracklet_labels = xml.load(dspath .. vfile .. '/tracklet_labels.xml')
      local tracklet = parseXML(tracklet_labels)

      extractObjects(img_path, tracklet, vfile)
   end

else 
   -- save backgrounds (not objects)
   local dspath = '/Users/eugenioculurciello/Code/datasets/KITTI/'

   for i = 1, #datafiles do
      local vfile = '2011_09_26_drive_'.. string.format("%04d", datafiles[i]) ..'_sync'

      print('==> loading KITTI tracklets and parsing the XML file: ' .. vfile)

      local img_path = dspath .. vfile ..  '/image_02/data/'
      local tracklet_labels = xml.load(dspath .. vfile .. '/tracklet_labels.xml')
      local tracklet = parseXML(tracklet_labels)

      extractObjects(img_path, tracklet, vfile)
   end

end
