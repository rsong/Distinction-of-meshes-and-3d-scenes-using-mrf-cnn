function imsvsa=saliencytrain(out,viewpoints,ims,mesh)
% Inputs:
% out: the output of the network;
% viewpoints: the collection of the 42 viewpoints;
% ims: the stacked image set where each image corresponds to a view of the 3D mesh;
% mesh: the 3D mesh;
% Outputs:
% imsvsa is the collection of view-based 3D saliency maps.
% The function first computes view-based 2D saliency maps via BP and then estimate the view-based 3D saliency maps based on the 2D saliency maps.



% outputSize should be consistent with the network setting.
outputSize = 224;

% Count the number of viewpoints;
num_vertices=length(viewpoints);

% Read in the 3D mesh
vv=mesh.V';
ff=mesh.F';

% Computes view-based 2D saliency maps via BP
vsa=reshape(out.prob,50,num_vertices);
[~,ind_vclass]=max(sum(vsa,2),[],1);
net=out.net;
dzdy=zeros(1,1,50,num_vertices);
dzdy(1,1,ind_vclass,:)=1;
im_=out.im;
im_=imgaussfilt(im_,1.5);
res1=vl_simplenn(net,im_,dzdy);
aaa=res1(1).dzdx;

% Convert 2D saliency maps into 3D saliency maps
imsc=cell(1, num_vertices);
imsp=imsc;

% Use a simplified 3D mesh. The view-based saliency value of a vertex in the original
% mesh is estimated via that of its closest vertex in the simplifed mesh.
if length(ff)>3000
    evalc('[p,t] = perform_mesh_simplification(vv,ff,2000)');
    knng=knnsearch(p,vv);
else
    p=vv;
    t=ff;
    knng=1:length(vv);
end

% Initialise the 3D saliency mpas for the simpliefied and the original
% meshes respectively.
imsvsas=zeros(length(p),num_vertices);
imsvsa=zeros(length(vv),num_vertices);

% Do the 2D-3D transfer through a projection scheme.
for i=1:num_vertices
    
    plotMesh(mesh,viewpoints(i,:));
    
    [az,el] = view;
    cam_angle=camva;
    
    [crop,r1,r2,c1,c2]=autocrop(ims{i});
    imsc{i}=crop;
    aa=size(crop,1);
    bb=size(crop,2);
    longside=max(aa,bb);
    shortside=min(aa,bb);
    
    % Extract 2D saliency information
    bbb=aaa(:,:,:,i);
    ccc=max(abs(bbb),[],3);
    ddd=(ccc-min(ccc(:)))./(max(ccc(:))-min(ccc(:)));
    
    % Calculate the 2D-3D transformation
    T=viewmtx(az,el,cam_angle);
    x4d=[p';ones(1,length(p))];
    x2d = T*x4d;
    %figure,plot(x2d(1,:),x2d(2,:),'r.');axis equal tight;
    
    xxa=max(x2d(1,:));
    xxi=min(x2d(1,:));
    yya=max(x2d(2,:));
    yyi=min(x2d(2,:));
    
    xx=xxa-xxi;
    yy=yya-yyi;
    
    longx=max(xx,yy);
    shortx=min(xx,yy);
    
    scale1=longside/longx;
    scale2=shortside/shortx;
    
    sscale=0.5*(scale1+scale2);
    x1=x2d(1,:)*sscale;
    y1=x2d(2,:)*sscale;
    
    x2=x1+0.5*outputSize;
    y2=y1-0.5*outputSize;
    
    cropsa=ddd(r1:r2,c1:c2);
    
    % Introduce a smoothing so that the 3D saliency of a vertex actually
    % relies on multiple 2D pixels in a neighbourhood.
    cropsa= imgaussfilt(cropsa,1.5);
    %    figure,imshow(cropsa);axis equal tight;
    
    imsp{i}=[x2;y2];
    y2=-y2;
    x2=x2-min(x2);
    y2=y2-min(y2);% y2 is row;
    
    % Consider the visibility of each vertex wrt the viewpoint
    visibility_v = mark_visible_vertices(p,t,viewpoints(i,:));
    visibility_v=perform_mesh_smoothing(t,p,visibility_v);
    
    [impointsx,impointsy]=meshgrid(1:bb,1:aa);
    impoints=[impointsx(:) impointsy(:)];
    
    % The 2D-3D saliency transfer is only valid for the visible vertices
    visible=find(visibility_v~=0);
    vx2=x2(visible);
    vy2=y2(visible);
    x2ddd=[vx2(:) vy2(:)];
    ind_cor = knnsearch(impoints,x2ddd);
    
    for jj=1:length(visible)
        row=impoints(ind_cor(jj),2);
        col=impoints(ind_cor(jj),1);
        imsvsas(visible(jj),i)=cropsa(row,col);     
    end
    
    imsvsas(:,i)= perform_mesh_smoothing(t,p,imsvsas(:,i));
    
    % Map the saliency from the simplified mesh back to the original mesh
    imsvsa(:,i)=imsvsas(knng,i);
    
    % Smooth the salinecy map a bit (optional)
    imsvsa(:,i)= perform_mesh_smoothing(ff,vv,imsvsa(:,i));
    imsvsa(:,i)= perform_mesh_smoothing(ff,vv,imsvsa(:,i));
    
end