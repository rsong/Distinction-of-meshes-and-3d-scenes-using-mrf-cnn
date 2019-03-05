function [num_vertices,ims,viewpoints] = render_views( mesh, varargin )
%RENDER_VIEWS render a 3d shape from multiple views
%   mesh::
%       a mesh object containing fileds
%           .F 3 x #faces (1-based indexing)
%           .V 3 x #vertices
%       OR a path to .off file
%
%   `colorMode`:: (default)  'rgb'
%       color mode of output images ('rgb' or 'gray')
%   `outputSize`::  (default)  224
%       output image size (both dimensions)
%   `minMargin`:: (default)  0.1
%       minimun margin ratio in output images
%   `maxArea`:: (default)  0.3
%       maximun area ratio in output images
%   `figHandle`:: (default) []
%       handle to existing figure

opts.colorMode = 'rgb';
opts.outputSize = 224;
opts.minMargin = 0.1;
opts.maxArea = 0.3;
opts.figHandle = [];
opts = vl_argparse(opts,varargin);

if isempty(opts.figHandle)
    opts.figHandle = figure;
end

% Create a icosahedron to sample uniformly on a sphere to generate a list
% of viewpoints
opts.view = icosahedron2sphere(1);
viewpoints=opts.view;

num_vertices=length(opts.view);

if ischar(mesh),
    if strcmpi(mesh(end-2:end),'off') || strcmpi(mesh(end-2:end),'obj')
        mesh = loadMesh(mesh);
    else
        error('file type (.%s) not supported.',mesh(end-2:end));
    end
end

ims = cell(1, num_vertices);
im_counter = 0;
for i=1:num_vertices
    %         plotMesh(mesh,'solid',opts.az(i),opts.el(i));
    plotMesh(mesh,opts.view(i,:));
    im_counter = im_counter + 1;
    ims{im_counter} = print('-RGBImage', '-r200'); %in case of an error,you have an old matlab version: comment this line and uncomment the following 2 ones
    %saveas(opts.figHandle, '__temp__.png');
    %ims{im_counter} = imread('__temp__.png');
    if strcmpi(opts.colorMode,'gray'), ims{im_counter} = rgb2gray(ims{im_counter}); end
    ims{im_counter} = resize_im(ims{im_counter}, opts.outputSize, opts.minMargin, opts.maxArea);
end

%delete('__temp__.png');
end

function im = resize_im(im,outputSize,minMargin,maxArea)

max_len = outputSize * (1-minMargin);
max_area = outputSize^2 * maxArea;

nCh = size(im,3);
mask = ~im2bw(im,1-1e-10);
mask = imfill(mask,'holes');
% blank image (all white) is outputed if not object is observed
if isempty(find(mask, 1)),
    im = uint8(255*ones(outputSize,outputSize,nCh));
    return;
end
[ys,xs] = ind2sub(size(mask),find(mask));
y_min = min(ys); y_max = max(ys); h = y_max - y_min + 1;
x_min = min(xs); x_max = max(xs); w = x_max - x_min + 1;
scale = min(max_len/max(h,w), sqrt(max_area/sum(mask(:))));
patch = imresize(im(y_min:y_max,x_min:x_max,:),scale);
[h,w,~] = size(patch);
im = uint8(255*ones(outputSize,outputSize,nCh));
loc_start = floor((outputSize-[h w])/2);
im(loc_start(1)+(0:h-1),loc_start(2)+(0:w-1),:) = patch;

end
