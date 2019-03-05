function ssa=deploysaliency(filename)
%setup the paths of all dependencies
setup;

% load the 1-ring neighbourhood info for the MRF graph containing 42 nodes.
load vring;

% The number of viewpoints
numsa=42;

% Read in the mesh
% filename='.\meshes\1.off';
[vertex,face] = readoff(filename);

% Estimate the net outputs
out = cnn_view_output(vertex,face);
vsa=reshape(out.prob,50,numsa);
[~,ind_vclass]=max(sum(vsa,2),[],1);
viewclass=out.prob(1,1,ind_vclass,:);

% Create the stack of view-based saliency
saliency=out.imsvsa;

% Estimate the weights for each view-based saliency using MRF.
% We use the built-in solver which performs slightly better than SA.
weights=ones(numsa,1);
opts = optimset('MaxIter',3000,'Display','off');
xx= fminsearch(@(x) mrf4(x,viewclass,numsa,vring),weights,opts);

% Aggregate the view-based saliency
ss=zeros(size(saliency,1),numsa);
for i=1:numsa
    ss(:,i)=xx(i).*saliency(:,i);
end

%saliency for a single mesh;
sa=sum(ss,2); 
options.symmetrize=1;
options.normalize=0;
ssa = perform_mesh_smoothing(face,vertex,sa,options);
ssa = perform_mesh_smoothing(face,vertex,ssa,options);
ssa=(ssa-min(ssa))./(max(ssa)-min(ssa));

%figure,trisurf(face,vertex(:,1),vertex(:,2),vertex(:,3),ssa);axis equal tight;axis off;shading interp;view(0,90);lightangle(0,90);lighting gouraud;colormap jet;material dull;
figure,trisurf(face,vertex(:,1),vertex(:,2),vertex(:,3),ssa);axis equal tight;axis off;shading interp;view(0,90);camlight('HEADLIGHT');colormap jet;material dull;


