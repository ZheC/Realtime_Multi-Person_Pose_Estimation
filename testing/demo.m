close all;
addpath('src'); 
addpath('util');
addpath('util/ojwoodford-export_fig-5735e6d/');

% For MPI, mode = 2. For COCO, mode = 1.
mode = 1;
param = config(mode);
model = param.model(param.modelID);
net = caffe.Net(model.deployFile, model.caffemodel, 'test');


%%
close all;
oriImg = imread('./sample_image/ski.jpg');
scale0 = 368/size(oriImg, 1);
twoLevel = 1;
[final_score, ~] = applyModel(oriImg, param, net, scale0, 1, 1, 0, twoLevel);
vis = 1;
if mode == 1
	[candidates, subset] = connect56LineVec(oriImg, final_score, param, vis);
elseif mode == 2
    [candidates, subset] = connect43LineVec(oriImg, final_score, param, vis);
end

pause;
        
%export_fig(['video/frame_' num2str(i) '.jpg']);  