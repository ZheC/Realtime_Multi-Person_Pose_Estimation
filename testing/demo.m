close all;
addpath('src'); 
addpath('util');
addpath('util/ojwoodford-export_fig-5735e6d/');

param = config(29); %26
model = param.model(param.modelID);
net = caffe.Net(model.deployFile, model.caffemodel, 'test');


%%
close all;
oriImg = imread('./sample_image/ski.jpg');
scale0 = 368/size(oriImg, 1);
twoLevel = 1;
[final_score, ~] = applyModel(oriImg, param, net, scale0, 1, 1, 0, twoLevel);
vis = 1;
[candidates, subset] = connect56LineVec(oriImg, final_score, param, vis);
pause;
        
%export_fig(['video/frame_' num2str(i) '.jpg']);  