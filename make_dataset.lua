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
   cmd:option('-width',       128,     'width of extracted patch')
   cmd:option('-height',      128,     'height of extracted patch')
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


-- Extract patches
function extractObjects(dspath, tracklet)
   videoframes = #sys.dirname(dspath)-2
   for imgi = 1,videoframes do
      rawFrame = image.loadPNG(tostring(dspath..string.format("%010u", imgi-1)..'.png'))
      local detections = {}
      for k=1, tracklet.count do
         first = tonumber(tracklet.item[k].first_frame)
         count = tonumber(tracklet.item[k].poses.count)+first
         if  first<imgi and imgi<=count then

            box = kitti2Dbox(tracklet.item[k].poses.item[imgi-first], tracklet.item[k])
            box.objectType = tracklet.item[k].objectType

            iwidth = rawFrame:size(3)
            iheight = rawFrame:size(2)

            box.x1 = max(1, min(iwidth, box.x1))
            box.y1 = max(1, min(iheight, box.y1))
            box.x2 = max(1, min(iwidth, box.x2))
            box.y2 = max(1, min(iheight, box.y2))

            os.execute("mkdir -p " .. box.objectType)
            local number = #paths.dir(box.objectType)

            local centerx = floor(box.x1 + (box.x2-box.x1)/2)
            local centery = floor(box.y1 + (box.y2-box.y1)/2)


            local x = centerx - floor(opt.width/2)
            local y = centery - floor(opt.height/2)  
          
            local w = x + opt.width - 1
            local h = y + opt.height - 1  
 
            if x >= 1 and y >= 1 and w <= iwidth and h <= iheight then

                local sample = rawFrame[{ {}, {y, h}, {x, w} }]:clone()
                image.savePNG(box.objectType..'/'..tostring(number)..'.png', sample)
            end

         end
      end
   
   end

end


-- Main program -------------------------------------------------------------

print '==> loading KITTI tracklets and parsing the XML files'


local dspath = '/Users/ayseguldundar/github/Aysegul/torch-KITTI/2011_09_26_drive_0001_sync'

local img_path = dspath .. '/image_02/data/'
local tracklet_labels = xml.load(dspath .. '/tracklet_labels.xml')

local tracklet = parseXML(tracklet_labels)
extractObjects(img_path, tracklet)



