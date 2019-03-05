The souce codes are based on matconvnet

Creat a new directory \data\models
Download the pretrained net from 

https://www.dropbox.com/s/15glsp57wp7qgj3/net-deployed.mat?dl=0

Save the downloaded net file 'net-deployed.mat' in \data\models

For a demo, implement 
s1=deploysaliency('.\meshes\human.off');
s2=deploysaliency('.\meshes\conferenceroom.off');

To calculate the distinction of your own 3D mesh/scene, if you can find a mesh of the same object class in the 'meshes' directory, make sure that the orientation of your mesh is roughly the same as that of the corresponding one in the 'meshes' directory. Otherwise just make it up oriented.

Please cite our paper: 
Ran Song, Yonghuai Liu, Paul L. Rosin. Distinction of 3D Objects and Scenes via Classification Network and Markov Random Field. IEEE Transactions on Visualization and Computer Graphics, 15 pages, 2018
