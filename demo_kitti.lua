------------------------------------------------------------------------------
-- This script loads the KITTI dataset
-- Aysegul Dundar 
-- e-mail : adundar@purdue.edu  
-- Date : 04/28/2013 
------------------------------------------------------------------------------

-- Requires ------------------------------------------------------------------
require 'image'   -- to visualize the dataset
require 'sys'
require 'xml'
require 'kitti2Dbox'
require 'qtwidget'
require 'qtuiloader'
require 'qt'


-- Exporting functions to the global namespace -------------------------------
local max = math.max
local min = math.min


-- Title ---------------------------------------------------------------------
print [[
********************************************************************************
>>>>>>>>>>>>>> Torch interface to KITTI (for cars) dataset <<<<<<<<<<<<<<<<<<<<<
********************************************************************************
]]


-- Global functions ----------------------------------------------------------
-- Parse XML
function parseXML(tracklet_labels)
   local parse = xml.parse(tracklet_labels)
   local tracklet = parse.boost_serialization.tracklets

   return tracklet
end


-- Extract patches
function extractObjects(dspath, tracklet)
   videoframes = #sys.dirname(dspath)-2 -- #sys.dir(dspath) == total number of frames in video dump (minum . and ..)
   for imgi = 1,videoframes do
      rawFrame = image.loadPNG(tostring(dspath..string.format("%010u", imgi-1)..'.png'))
      
      if not win then
         win = qtwidget.newwindow(rawFrame:size(3), rawFrame:size(2), 'KITTI city')
      end
      win:gbegin()
      win:showpage()

      sys.sleep(0.1)
      image.display{image=rawFrame, win=win}
      -- get bounding boxes from tracklets:

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

            win:setcolor(1,0,0)
            win:rectangle(box.x1, box.y1, box.x2-box.x1, box.y2-box.y1)
          
            win:setfont(qt.QFont{serif=false,italic=false,size=16})
            win:moveto(box.x1, box.y1-1)


            win:show(box.objectType)


            win:stroke()
            win:gend()

         end
      end
   
   end

end


-- Main program -------------------------------------------------------------

print '==> loading KITTI tracklets and parsing the XML files'


local dspath = '/Users/eugenioculurciello/Code/datasets/KITTI/2011_09_26/2011_09_26_drive_0001_sync'

local img_path = dspath .. '/image_02/data/'
local tracklet_labels = xml.load(dspath .. '/tracklet_labels.xml')

local tracklet = parseXML(tracklet_labels)
extractObjects(img_path, tracklet)



