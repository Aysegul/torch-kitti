torch-KITTI
===========

lua-torch code to load KITTI dataset, run demo or extract patches of objects for training.

dependency lua--xml

```bash
git clone  http://github.com/clementfarabet/lua---xml
cd lua---xml
luarocks make
```
 You need to download images from: http://www.cvlibs.net/datasets/kitti/raw_data.php 
 > - synced+rectified data
 > - tracklet
 
##For the demo:

The images folder ending with 'sync' has folders with images put tracklet_labels.xml in the same folder.
Modify dspath, absolute path to sequence base directory (ends with _sync), in demo_kitti.lua.

```bash
qlua demo_kitti.lua
```

![](kitti_city.png)

##For extracting patches of objects

Modify dspath, absolute path to sequence base directory (ends with _sync), in make_dataset.lua. 

```bash
th make_dataset.lua -width 128 -height 128
```
will go through video and extract patches of the objects that are centered in a bounding box of 128x128 dimension and create folder in that name. For example, will create folder name car and save patches of cars with an increasing index. car1.png, car2.png....





