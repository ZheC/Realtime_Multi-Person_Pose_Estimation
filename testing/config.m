function param = config(id)
%% set this part

% GPU device number (doesn't matter for CPU mode)
GPUdeviceNumber = 0;

% Select model (default: 5)
param.modelID = id;

% Use click mode or not. If yes (1), you will be asked to click on the center
% of person to be pose-estimated (for multiple people image). If not (0),
% the model will simply be applies on the whole image.
param.click = 1;

% Scaling paramter: starting and ending ratio of person height to image
% height, and number of scales per octave
% warning: setting too small starting value on non-click mode will take
% large memory

% CPU mode or GPU mode
param.use_gpu = 1;

param.test_mode = 3;
param.vis = 1;

param.octave = 6;
param.starting_range = 0.8;
param.ending_range = 2;

param.min_num = 4;
param.mid_num = 10;

% the larger the crop_ratio, the smaller the windowsize
param.crop_ratio = 2.5; %2
param.bbox_ratio = 0.25; %0.5

% applyModel_max
param.max = 0;
% use average heatmap
param.merge = 'avg';


% path of your caffe
caffepath = '/home/zhecao/caffe/matlab';

%COCO parameter
if id == 1
    param.scale_search = [0.5 1 1.5 2];
    param.thre1 = 0.1;
    param.thre2 = 0.05; 
    param.thre3 = 0.5; 

    param.model(id).caffemodel = '../model/_trained_COCO/pose_iter_440000.caffemodel';
    param.model(id).deployFile = '../model/_trained_COCO/pose_deploy.prototxt';
    param.model(id).description = 'COCO Pose56 Two-level Linevec';
    param.model(id).boxsize = 368;
    param.model(id).padValue = 128;
    param.model(id).np = 18; 
    param.model(id).part_str = {'nose', 'neck', 'Rsho', 'Relb', 'Rwri', ... 
                             'Lsho', 'Lelb', 'Lwri', ...
                             'Rhip', 'Rkne', 'Rank', ...
                             'Lhip', 'Lkne', 'Lank', ...
                             'Leye', 'Reye', 'Lear', 'Rear', 'pt19'};
end

%MPI parameter
if id == 2
    param.scale_search = [0.7 1 1.3];
    param.thre1 = 0.05;
    param.thre2 = 0.01;
    param.thre3 = 3;
    param.thre4 = 0.1;
    
    param.model(id).caffemodel = '../model/_trained_MPI/pose_iter_146000.caffemodel';
    param.model(id).deployFile = '../model/_trained_MPI/pose_deploy.prototxt';
    
    param.model(id).description = 'MPI Pose43 Two-level LineVec';
    param.model(id).boxsize = 368;
    param.model(id).padValue = 128;
    param.model(id).np = 15; 
    param.model(id).part_str = {'Nose', 'Neck', 'Rsho', 'Relb', 'Rwri', ... 
                             'Lsho', 'Lelb', 'Lwri', ...
                             'Rhip', 'Rkne', 'Rank', ...
                             'Lhip', 'Lkne', 'Lank', 'center'};
end


disp(caffepath);
addpath(caffepath);
caffe.set_mode_gpu();
caffe.set_device(GPUdeviceNumber);
caffe.reset_all();