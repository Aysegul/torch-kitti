----------------------------------------------------------------------
-- KITTI dataset interface
-- 
--
-- Author : Aysegul Dundar 
-- email : adundar@purdue.edu
-- Date 04/17/2013
----------------------------------------------------------------------
 

function wrapToPi(alpha)

  local alpha = alpha%(2*math.pi)
  if (alpha>math.pi) then
     alpha = alpha-2*math.pi
  end

 return alpha;

end


function projectToImage(pts_3D, K)

 local pts_2D = K*pts_3D[{{1,3},{}}]   --pts_3D(1:3,:)
 pts_2D[1] =  pts_2D[1]:cdiv(pts_2D[3])
 pts_2D[2] =  pts_2D[2]:cdiv(pts_2D[3])
 -- the last row is meaningless should be cropped 

 return(pts_2D)
end


function kitti2Dbox(tracklet)

   local corners={}
   corners.x = torch.Tensor{l/2, l/2, -l/2, -l/2, l/2, l/2, -l/2, -l/2}; 
   corners.y = torch.Tensor{w/2, -w/2, -w/2, w/2, w/2, -w/2, -w/2, w/2}; 
   corners.z = torch.Tensor{0,0,0,0,h,h,h,h};

   local rz = tracklet.rz
   local t = {tracklet.tx; tracklet.ty; tracklet.tz};
   rz = wrapToPi(rz);
   occlusion =0;

   local R = torch.Tensor{{math.cos(rz), -math.sin(rz), 0},
         {math.sin(rz),  math.cos(rz), 0},
          {0, 0, 1}}


   local a = torch.Tensor(3,8)
   a[1] = corners.x
   a[2] = corners.y
   a[3] = corners.z 
   local corners_3D = R*a

   corners_3D[1] = corners_3D[1]+t[1]
   corners_3D[2] = corners_3D[2]+t[2]
   corners_3D[3] = corners_3D[3]+t[3]

   a = torch.Tensor(4,8):fill(1)
   a[1]:copy(corners_3D[1])
   a[2]:copy(corners_3D[2])
   a[3]:copy(corners_3D[3])


   local velToCam = torch.Tensor{
    {0.0002,   -0.9999,  -0.0106,   0.0594},
    {0.0104,   0.0106,   -0.9999,  -0.0751},
    {0.9999,    0.0001,   0.0105,  -0.2721},
    {     0,         0,        0,   1.0000}}


   corners_3D = velToCam*a

   local K = torch.Tensor{
         {721.5377,  0,  609.5593},
         {0,  721.5377,  172.8540},
         {0,         0,    1.0000}}


  local corners_2D = projectToImage(corners_3D, K);

  -- compute and draw the 2D bounding box from the 3D box projection 
  box={}
  box.x1 = torch.min(corners_2D[1]);
  box.x2 = torch.max(corners_2D[1]);
  box.y1 = torch.min(corners_2D[2]);
  box.y2 = torch.max(corners_2D[2]);

  return box

end
