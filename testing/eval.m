addpath('util/jsonlab/');
addpath('src'); 
addpath('util');
addpath('util/ojwoodford-export_fig-5735e6d/');

% For MPI, mode = 2. For COCO, mode = 1.
orderCOCO = [1,0 7,9,11, 6,8,10, 13,15,17, 12,14,16, 3,2,5,4];
mode = 1;
param = config(mode);
model = param.model(param.modelID);
net = caffe.Net(model.deployFile, model.caffemodel, 'test');

pred(length(coco_val)) = struct('annorect', [], 'candidates', []);
% iterate all val images
for i = 1:length(coco_val)

    oriImg = imread('....', coco_val(i));
    scale0 = 368/size(oriImg, 1);
    twoLevel = 1;
    [final_score, ~] = applyModel(oriImg, param, net, scale0, 1, 1, 0, twoLevel);
    vis = 0;
    [candidates, subset] = connect56LineVec(oriImg, final_score, param, vis);

    point_cnt = 0;
    for ridxPred = 1:size(subset,1)
        point = struct([]);
        part_cnt = 0;
        for part = 1:18
            if part == 2
               continue;
            end
            index = subset(ridxPred,part);
            if(index >0)
                part_cnt = part_cnt +1;
                point(part_cnt).x = candidates(index,1);
                point(part_cnt).y = candidates(index,2);
                point(part_cnt).score = candidates(index,3);
                point(part_cnt).id = orderCOCO(part);
            end
        end
        
        point_cnt = point_cnt +1;
        pred(i).annorect(point_cnt).annopoints.point = point;
        %pred(i).annorect(point_cnt).annopoints.score = subset(ridxPred,end-1)/subset(ridxPred,end);
        pred(i).annorect(point_cnt).annopoints.score = subset(ridxPred,end-1);
    end
    pred(i).candidates = candidates;
end

%% convert the format
json_for_coco_eval = struct('image_id', [], 'category_id', [], 'keypoints', [], 'score', []);
count = 1;
for j = 1:length(pred)
    for d = 1:length(pred(j).annorect)
        json_for_coco_eval(count).image_id = coco_val(j).image_id;
        json_for_coco_eval(count).category_id = 1;
        json_for_coco_eval(count).keypoints = zeros(3, 17);
        %length(pred(j).annorect(d).annopoints.point)
        for p = 1:length(pred(j).annorect(d).annopoints.point)
            point = pred(j).annorect(d).annopoints.point(p);
            json_for_coco_eval(count).keypoints(1, point.id) = point.x - 0.5;
            json_for_coco_eval(count).keypoints(2, point.id) = point.y - 0.5;
            json_for_coco_eval(count).keypoints(3, point.id) = 1;
        end
        
        json_for_coco_eval(count).keypoints = reshape(json_for_coco_eval(count).keypoints, [1 51]);
        json_for_coco_eval(count).score = pred(j).annorect(d).annopoints.score *length(pred(j).annorect(d).annopoints.point);
        
        count = count + 1;
    end
end

opt.FileName = 'result.json';      
opt.FloatFormat = '%.3f';
savejson('', json_for_coco_eval, opt);
evalDemo(opt.FileName);
