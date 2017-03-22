addpath('src'); 
addpath('util');
addpath('util/ojwoodford-export_fig-5735e6d/');

%MPI test set
load('annolist_test_multi.mat')
%MPI parameter
param = config2(2); 

model = param.model(param.modelID);
net = caffe.Net(model.deployFile, model.caffemodel, 'test');

orderMPI = [9 8 12 11 10 13 14 15 2 1 0 3 4 5];
targetDist = 41/35;
boxsize = param.model(param.modelID).boxsize;
vis = param.vis;

for i = 1:length(annolist_test_multi) 
    
    fprintf('%d/%d:', i, length(annolist_test_multi));
    imagePath = ['../../training/dataset/MPI/images/' annolist_test_multi(i).image.name];
    oriImg = imread(imagePath);

    rect = annolist_test_multi(i).annorect;
    pos = zeros(length(rect),2);
    scale = zeros(length(rect),1);
    %imshow(oriImg), hold on;
    for ridx = 1:length(rect)
        pos(ridx,:) = [rect(ridx).objpos.x rect(ridx).objpos.y];
        scale(ridx) = rect(ridx).scale;
        %plot(pos(ridx,1), pos(ridx,2), 'yx', 'Linewidth', 5);
    end
    minX = min(pos(:,1));
    minY = min(pos(:,2));
    maxX = max(pos(:,1));
    maxY = max(pos(:,2));
    
    scale0 = targetDist/mean(scale);
    deltaX = boxsize/(scale0*param.crop_ratio); 
    deltaY = boxsize/(scale0*2); 
    
    bbox = zeros(1,4);
    dX = deltaX* param.bbox_ratio;
    dY = deltaY* param.bbox_ratio;
    bbox(1) = max(minX-dX,1);
    bbox(2) = max(minY-dY,1);
    bbox(3) = min(maxX+dX,size(oriImg,2));
    bbox(4) = min(maxY+dY,size(oriImg,1));
    
    distMap = 0;
    twoLevel = 1;
    [final_score, ~] = applyModel(oriImg, param, net, scale0, 2, 1, distMap, twoLevel);
    [candidates, subset] = connect43LineVec(oriImg, final_score, param, vis);
    
    point_cnt = 0;
    for ridxPred = 1:size(subset,1)
        point = struct([]);
        sum_x = 0;
        sum_y = 0;
        part_cnt = 0;
        for part = 1:14
            %pointsPred = pred(imgidx).annorect(ridxPred).annopoints.point;
            index = subset(ridxPred,part);
            if(index >0)
                part_cnt = part_cnt +1;
                point(part_cnt).x = candidates(index,1);
                point(part_cnt).y = candidates(index,2);
                sum_x = sum_x + point(part_cnt).x;
                sum_y = sum_y + point(part_cnt).y;
                point(part_cnt).score = candidates(index,3);
                point(part_cnt).id = orderMPI(part);
            end
        end
        mean_x = sum_x/part_cnt;
        mean_y = sum_y/part_cnt;
        index = subset(ridxPred,15);
        if(mean_x>bbox(1) && mean_x<bbox(3) && mean_y>bbox(2) && mean_y<bbox(4))
            point_cnt = point_cnt +1;
            pred(i).annorect(point_cnt).annopoints.point = point;
        elseif(index>0 && candidates(index,1)>bbox(1) && candidates(index,1)<bbox(3) && candidates(index,2)>bbox(2) && candidates(index,2)<bbox(4))
            point_cnt = point_cnt +1;
            pred(i).annorect(point_cnt).annopoints.point = point;
        end
    end
    
    if vis == 1
        export_fig(['result/vis_' num2str(i) '.png']);
        close all;
    end
end

% save the result in MPII format
save(sprintf('prediction_mode%d.mat', mode), 'pred');