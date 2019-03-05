function out = cnn_view_output( vertex,face, varargin )
%Output the prob layer result and the feature layer (e.g., relu7) result

% default options
opts.feature = 'relu7';
opts.prob = 'prob';
opts.gpus = [];
[opts, varargin] = vl_argparse(opts,varargin);
opts.cnnModel = 'net-deployed';
opts = vl_argparse(opts,varargin);

% Load the trained net.
netFilePath = fullfile('data','models',[opts.cnnModel '.mat']);
cnn = load(netFilePath);

fig = figure('Visible','off');

mesh.F=face';
mesh.V=vertex';
if isempty(mesh.F)
    error('Could not load mesh from file');
else
    fprintf(' Load mesh successfully!\n');
end
fprintf('Rendering mesh ... \n');

[num_views,ims,viewpoints] = render_views(mesh,'figHandle', fig);
fprintf('Done! \n');
fprintf('MRFCNN model is based on %d views. Will process %d views per mesh.\n', num_views, num_views);

% Gather the outputs of the net at different layers
outs1 = cnn_shape_view(ims, cnn, {opts.feature}, 'gpus', opts.gpus);
out1 = outs1.(opts.feature);
out.feature = double(out1);

outs2 = cnn_shape_view(ims, cnn, {opts.prob}, 'gpus', opts.gpus);
out2 = outs2.(opts.prob);
out.prob = double(out2);

out.net=outs2.net;
out.im=outs2.im;

% Estimate 2D saliency and convert it to 3D saliency
imsvsa=saliencytrain(out,viewpoints,ims,mesh);
out.imsvsa=imsvsa;

close(fig);
