function [heatMaps, prediction] = applyModel(test_image, param, net, rectangle, click, evaluation, distMap, twoLevel)

if nargin < 7
    distMap = 0;
end

if nargin < 8
    twoLevel = 0;
end

%% check to use click mode or not
%click = param.click;

%% select model and other parameters from variable param
model = param.model;
model = model(param.modelID);
boxsize = model.boxsize;
%np = model.np;
if click == 0
    np = 1;
else
    np = 15;
end    
%% search thourgh a range of scales, and choose the scale according to sum of peak value of all parts

%matcaffe_init(1, model.deployFile, model.caffemodel, 0);
oriImg = test_image; %imread(test_image);
makeFigure = 0; % switch to 1 for debugging

octave = param.octave;
starting_range = param.starting_range;
ending_range = param.ending_range;
assert(starting_range <= ending_range, 'starting ratio should <= ending ratio');
assert(octave>=1, 'octave should >= 1');

starting_scale = boxsize/(size(oriImg,1)*ending_range);
ending_scale = boxsize/(size(oriImg,1)*starting_range);
multiplier = 2.^(log2(starting_scale):(1/octave):log2(ending_scale));

% set the center and roughly scale range (overwrite the config!) according to the rectangle
if(click)
    if evaluation == 0
        % use whole image
        starting_range = 0.85; %0.25 0.7
        ending_range = 1.5; %1.2 1.8
        octave = 6;
        starting_scale = boxsize/(size(oriImg,1)*ending_range);
        ending_scale = boxsize/(size(oriImg,1)*starting_range);
        multiplier = 2.^(log2(starting_scale):(1/octave):log2(ending_scale));
    else
        % use given scale
        scale0 = rectangle;
        multiplier = param.scale_search *scale0; %(0.7:0.3:1.3)*scale0; %(0.5:0.3:1.4)*scale0; 
    end
end

% data container for each scale
% score = cell(1,length(multiplier));
% peakValue = zeros(length(multiplier), np+1);
pad = cell(1, length(multiplier));
ori_size = cell(1, length(multiplier));
suc_flag = 0;

for m = 1:length(multiplier)
    scale = multiplier(m);
%     target_height = 8 * ceil( (size(oriImg,1) * scale /8));
%     target_width = 8 * ceil( (size(oriImg,2) * scale /8));
%     imageToTest = imresize(oriImg, [target_height, target_width]);
    imageToTest = imresize(oriImg, scale);
    ori_size{m} = size(imageToTest);
    
    %[imageToTest, pad{m}] = padRightDownCorner(imageToTest, model.padValue, 0);
    bbox = [boxsize, max(ori_size{m}(2),boxsize)];
    %display(size(imageToTest))
    
    %figure(3); imshow(imageToTest);
    [imageToTest, pad{m}] = padHeight(imageToTest, model.padValue, bbox);
    %display(size(imageToTest));
    %figure(4); imshow(imageToTest);
    %pause;
    
    imageToTest = preprocess(imageToTest, 0.5, param, click);
    if numel(imageToTest) > 3728000*3
        disp('Image Size Too Large!');
        continue;
    end
    suc_flag = 1;
    %{
    if(~click)
        caffe.reset_all();
        system(sprintf('sed -i "3s/.*/input_dim: %d/" %s', 4, model.deployFile_1st));
        system(sprintf('sed -i "4s/.*/input_dim: %d/" %s', size(imageToTest,2), model.deployFile_1st));
        system(sprintf('sed -i "5s/.*/input_dim: %d/" %s', size(imageToTest,1), model.deployFile_1st));
        %net = caffe.Net(model.deployFile_1st, model.caffemodel, 'test');
        net = caffe.Net(model.deployFile_1st, model.caffemodel_1st, 'test');
    else
        caffe.reset_all();
        system(sprintf('sed -i "3s/.*/input_dim: %d/" %s', 4, model.deployFile));
        system(sprintf('sed -i "4s/.*/input_dim: %d/" %s', size(imageToTest,2), model.deployFile));
        system(sprintf('sed -i "5s/.*/input_dim: %d/" %s', size(imageToTest,1), model.deployFile));
        net = caffe.Net(model.deployFile, model.caffemodel, 'test');
    end
    %}
    
    %net = caffe.Net(model.deployFile, model.caffemodel, 'test');
    net.blob_vec(1).reshape([size(imageToTest) 1])
    net.reshape()
    %score{m} = applyDNN(imageToTest, net, distMap);
    score{m} = applyDNN(imageToTest, net, twoLevel);

    pool_time = size(imageToTest,1) / size(score{m},1);
    % changed here. use GPU resize function
    score{m} = imresize(score{m}, pool_time);
    size_multi = size(oriImg,1)/368;
    %size(score{m})
    score{m} = resizeIntoScaledImg(score{m}, pad{m});
    score{m} = imresize(score{m}, [size(oriImg,2) size(oriImg,1)]);
    
    if distMap ==1
        for i=21:3:75
            score{m}(:,:,i) = score{m}(:,:,i)*46*size_multi;
        end
    end
%     score_to_plot = imresize(score{m}, pool_time);
%     score_to_plot = permute(score_to_plot, [2 1 3]);
    % collect maximum peak value for each part
%     for part = 1:np+1
%         peakValue(m, part) = max(max(score_to_plot(:,:,part)));
%         if(makeFigure)
%             max_value = max(max(score_to_plot(:,:,part)));
%             score_to_plot_im = mat2im(score_to_plot(:,:,part), jet(100), [0 max_value]);
%             im_to_disp = ((permute(imageToTest(:,:,1:3),[2 1 3])+0.5) + score_to_plot_im)/2;
%             %im_to_disp = insertText(im_to_disp, [0 0], sprintf('%f', peakValue(m, part)));
%             subplot(3,5,part);
%             imshow(im_to_disp);
%         end
%     end
    
    if(makeFigure)
        title(sprintf('Current Scale: %f, TOTAL: %f', multiplier(m), sum(peakValue(m,1:np))));
    end
end


%% make heatmaps into the size of scaled image according to pad
if(click)
    if suc_flag == 0
        heatMaps = [];
        prediction = [];
        return;
    end
    final_score = zeros(size(score{1,1}));
    for m = 1:size(score,2)
        final_score = final_score + score{m}/numel(score); %length(multiplier);
    end
    heatMaps = permute(final_score, [2 1 3]); 

    % generate prediction
    prediction = zeros(np,3);
%     for j = 1:np
%         [prediction(j,1), prediction(j,2), prediction(j,3)] = findMaximum(final_score(:,:,j));
%     end
else
    final_score = zeros(size(score{1,1}));
    for m = 1:size(score,2)
        %wrong model, predict the backgroud, use 3rd label instead
        if np == 1
            score{m}(:,:,1) = 1- score{m}(:,:,1);
        end
        score_parts = score{m}(:,:,1);
        thre = max(score_parts(:))*0.4;
        [X,Y,s] = findPeaks(score{m}(:,:,1), thre);
        plot(Y, X, 'wx', 'MarkerSize', 10);
        peaks{m} = [X, Y, s, boxsize/(size(oriImg,1)*multiplier(m)) * ones(length(X), 1)];
        
        if(np==1)
            display_score = permute(score{m}(:,:,1), [2 1 3]);
        else
            display_score = permute(score{m}(:,:,5), [2 1 3]);
        end
        imshow(single(oriImg)/256 * 0.5 + mat2im(display_score, jet(100), [0 1])/2);
        final_score = final_score + score{m};
    end
    heatMaps = permute(final_score, [2 1 3]); 
    score_vis = single(oriImg)/256 * 0.5 + mat2im(final_score', jet(100),  [0 max(final_score(:))])/2;

%     [X,Y,s] = findPeaks(final_score, 3);
%     num_peak = size(X,1);
%     if num_peak == 0
%         prediction = [];
%         disp('No person found in the image!')
%         return;
%     end
%     loc = [X Y zeros(num_peak,2)];
%     loc = fitGaussian(final_score', loc);
%     pause;
%     % loc = nonmaxGaussian(final_score', 1.75);
%     close all;
%     if np == 1
%         for p = 1:size(loc,1)
%             best_range = loc(p,3)*7;
%             figure(1);
%             imshow(score_vis);
%             hold on;
%             xlim([-size(score_vis,2)*0.4 size(score_vis,2)*1.4]); 
%             ylim([-size(score_vis,1)*0.4 size(score_vis,1)*1.4]);
%             center = loc(p,1:2);
%             plot([center(1) center(1)], [center(2)-best_range center(2)+best_range], 'LineWidth',3);
%             plot(center(1), center(2), 'rx');
%             rec = [center(1)-10, center(2)- best_range, 20, center(2) + best_range];
%             
%             [heatMaps, prediction] = applyModel(test_image, param, rec, 1, 0);
%             plot(prediction(prediction(:,3)>0.15,1), prediction(prediction(:,3)>0.15,2), 'wx');
%             figure(2);
%             visualize(test_image, heatMaps, prediction, param);
%             pause;
%             close all;
%         end
%     end
    
    % analysis peaks
    peaks_data = cat(1, peaks{:});
    peaks_data_loc = peaks_data(:,1:2);
    [~,~,cluster2dataCell] = MeanShiftCluster(peaks_data_loc', 20, 0);
    numPeople = length(cluster2dataCell);
    peaks_cluster = cell(1, numPeople);
    for p = 1 %1:numPeople
        peaks_cluster{p} = peaks_data(cluster2dataCell{p}, :);
        [~, I] = max(peaks_cluster{p}(:,3));
        best_range = peaks_cluster{p}(I,4);
        
        figure(1);
        imshow(score_vis);
        hold on;
        if np == 1
            center = peaks_cluster{p}(I, 1:2);
            plot([center(1) center(1)], [center(2)-best_range*size(oriImg,1)*0.3 center(2)+best_range*size(oriImg,1)*0.3]);
            plot(center(1), center(2), 'rx');
            rec = [center(1)-10, center(2)- best_range*size(oriImg,1)*0.3, 20, center(2) + best_range*size(oriImg,1)*0.3];
        else
            head_loc = peaks_cluster{p}(I, 1:2);
            plot([head_loc(1) head_loc(1)], [head_loc(2)-best_range*size(oriImg,1)*0.2 head_loc(2)+best_range*size(oriImg,1)*0.8]);
            center = [head_loc(1), head_loc(2) + best_range*size(oriImg,1) * 0.3];
            plot(center(1), center(2), 'rx');
            rec = [head_loc(1)-10, head_loc(2), 20, best_range*size(oriImg,1)*0.5];
        end
        [heatMaps, prediction] = applyModel(test_image, param, rec, 1, 0);
        plot(prediction(prediction(:,3)>0.15,1), prediction(prediction(:,3)>0.15,2), 'wx');
        figure(2);
        visualize(test_image, heatMaps, prediction, param);
        pause;
        close all;
    end
    
    
    % generate prediction
%     prediction = zeros(np,2);
%     for j = 1:np
%         [prediction(j,1), prediction(j,2)] = findMaximum(score(:,:,j));
%     end
end

% DEBUG: visualize to make sure heat maps are correctly superimposed on image
%figure(5);
%imshow(single(oriImg)/256 * 0.5 + mat2im(permute(heatMaps(:,:,15),[2 1 3]),jet(100),[0.3 1])/2);

function img_out = preprocess(img, mean, param, click)
    img_out = double(img)/256;  
    img_out = double(img_out) - mean;
    img_out = permute(img_out, [2 1 3]);
    
    if size(img_out,3) == 1
        img_out(:,:,3) = img_out(:,:,1);
        img_out(:,:,2) = img_out(:,:,1);
    end
    
    img_out = img_out(:,:,[3 2 1]); % BGR for opencv training in caffe !!!!!

    
function scores = applyDNN(images, net, distMap)
    if nargin < 3
        distMap = 0;
    end
    input_data = {single(images)};
    % do forward pass to get scores
    % scores are now Width x Height x Channels x Num
    s_vec = net.forward(input_data);
    %L1 = net.blobs('Mconv7_stage4_L1').get_data();
    %L2 = net.blobs('Mconv7_stage4_L2').get_data();
%     if distMap == 2
%         scores = cat(3, s_vec{1}, s_vec{2}); % note this score is transposed
%         %scores = cat(3, L1, L2);
    if distMap == 1
        scores = cat(3, s_vec{2}(:,:,1:end-1), s_vec{1});
    elseif distMap == 2
        L1 = net.blobs('conv5_5_CPM_L1').get_data();
        L2 = net.blobs('conv5_5_CPM_L2').get_data();
    elseif distMap >= 3    
        L1 = net.blobs(['Mconv7_stage' num2str(distMap-1) '_L1']).get_data();
        L2 = net.blobs(['Mconv7_stage' num2str(distMap-1) '_L2']).get_data();
    else
        scores = s_vec{1}; % note this score is transposed
    end
    
    if distMap > 1
        scores = cat(3, L2(:,:,1:end-1), L1);
        scores = imresize(scores, 8);
        display('here');
    end
    
function [img_padded, pad] = padAround(img, boxsize, center, padValue)
    center = round(center);
    h = size(img, 1);
    w = size(img, 2);
    pad(1) = boxsize/2 - center(2); % up
    pad(3) = boxsize/2 - (h-center(2)); % down
    pad(2) = boxsize/2 - center(1); % left
    pad(4) = boxsize/2 - (w-center(1)); % right
    
    pad_up = repmat(img(1,:,:), [pad(1) 1 1])*0 + padValue;
    img_padded = [pad_up; img];
    pad_left = repmat(img_padded(:,1,:), [1 pad(2) 1])*0 + padValue;
    img_padded = [pad_left img_padded];
    pad_down = repmat(img_padded(end,:,:), [pad(3) 1 1])*0 + padValue;
    img_padded = [img_padded; pad_down];
    pad_right = repmat(img_padded(:,end,:), [1 pad(4) 1])*0 + padValue;
    img_padded = [img_padded pad_right];
    
    center = center + [max(0,pad(2)) max(0,pad(1))];

    img_padded = img_padded(center(2)-(boxsize/2-1):center(2)+boxsize/2, center(1)-(boxsize/2-1):center(1)+boxsize/2, :); %cropping if needed

    
function [img_padded, pad] = padHeight(img, padValue, bbox)
    h = size(img, 1);
    w = size(img, 2);
    h = min(bbox(1),h);
    bbox(1) = ceil(bbox(1)/8)*8;
    bbox(2) = max(bbox(2), w);
    bbox(2) = ceil(bbox(2)/8)*8;
    pad(1) = floor((bbox(1)-h)/2); % up
    pad(2) = floor((bbox(2)-w)/2); % left
    pad(3) = bbox(1)-h-pad(1); % down
    pad(4) = bbox(2)-w-pad(2); % right
    
    img_padded = img;
    pad_up = repmat(img_padded(1,:,:), [pad(1) 1 1])*0 + padValue;
    img_padded = [pad_up; img_padded];
    pad_left = repmat(img_padded(:,1,:), [1 pad(2) 1])*0 + padValue;
    img_padded = [pad_left img_padded];
    pad_down = repmat(img_padded(end,:,:), [pad(3) 1 1])*0 + padValue;
    img_padded = [img_padded; pad_down];
    pad_right = repmat(img_padded(:,end,:), [1 pad(4) 1])*0 + padValue;
    img_padded = [img_padded pad_right];
    %cropping if needed
    
function [img_padded, pad] = padRightDownCorner(img, padValue, boxsize)
    h = size(img, 1);
    w = size(img, 2);
    
    pad(1) = boxsize/2; % up
    pad(2) = boxsize/2; % left
    pad(3) = boxsize/2 + 8 - mod((boxsize+h), 8); % down
    pad(4) = boxsize/2 + 8 - mod((boxsize+w), 8); % right
    
    img_padded = img;
    pad_up = repmat(img_padded(1,:,:), [pad(1) 1 1])*0 + padValue;
    img_padded = [pad_up; img_padded];
    pad_left = repmat(img_padded(:,1,:), [1 pad(2) 1])*0 + padValue;
    img_padded = [pad_left img_padded];
    pad_down = repmat(img_padded(end,:,:), [pad(3) 1 1])*0 + padValue;
    img_padded = [img_padded; pad_down];
    pad_right = repmat(img_padded(:,end,:), [1 pad(4) 1])*0 + padValue;
    img_padded = [img_padded pad_right];

function [x,y,v] = findMaximum(map)
    [v,i] = max(map(:));
    [x,y] = ind2sub(size(map), i);
    
function score = resizeIntoScaledImg(score, pad)
    np = size(score,3)-1;
    score = permute(score, [2 1 3]);
    if(pad(1) < 0)
        padup = cat(3, zeros(-pad(1), size(score,2), np), ones(-pad(1), size(score,2), 1));
        score = [padup; score]; % pad up
    else
        score(1:pad(1),:,:) = []; % crop up
    end
    
    if(pad(2) < 0)
        padleft = cat(3, zeros(size(score,1), -pad(2), np), ones(size(score,1), -pad(2), 1));
        score = [padleft score]; % pad left
    else
        score(:,1:pad(2),:) = []; % crop left
    end
    
    if(pad(3) < 0)
        paddown = cat(3, zeros(-pad(3), size(score,2), np), ones(-pad(3), size(score,2), 1));
        score = [score; paddown]; % pad down
    else
        score(end-pad(3)+1:end, :, :) = []; % crop down
    end
    
    if(pad(4) < 0)
        padright = cat(3, zeros(size(score,1), -pad(4), np), ones(size(score,1), -pad(4), 1));
        score = [score padright]; % pad right
    else
        score(:,end-pad(4)+1:end, :) = []; % crop right
    end
    score = permute(score, [2 1 3]);
    
function label = produceCenterLabelMap(im_size, x, y) %this function is only for center map in testing
    sigma = 21;
    %label{1} = zeros(im_size(1), im_size(2));
    [X,Y] = meshgrid(1:im_size(1), 1:im_size(2));
    X = X - x;
    Y = Y - y;
    D2 = X.^2 + Y.^2;
    Exponent = D2 ./ 2.0 ./ sigma ./ sigma;
    label{1} = exp(-Exponent);
    
function [X,Y,score] = findPeaks(map, thre)
    %filter = fspecial('gaussian', [3 3], 2);
    %map_smooth = conv2(map, filter, 'same');
    map_smooth = map;
    map_smooth(map_smooth < thre) = 0;
    
    map_aug = -1*zeros(size(map_smooth,1)+2, size(map_smooth,2)+2);
    map_aug1 = -1*zeros(size(map_smooth,1)+2, size(map_smooth,2)+2);
    map_aug2 = -1*zeros(size(map_smooth,1)+2, size(map_smooth,2)+2);
    map_aug3 = -1*zeros(size(map_smooth,1)+2, size(map_smooth,2)+2);
    map_aug4 = -1*zeros(size(map_smooth,1)+2, size(map_smooth,2)+2);
    
    map_aug(2:end-1, 2:end-1) = map_smooth;
    map_aug1(2:end-1, 1:end-2) = map_smooth;
    map_aug2(2:end-1, 3:end) = map_smooth;
    map_aug3(1:end-2, 2:end-1) = map_smooth;
    map_aug4(3:end, 2:end-1) = map_smooth;
    
    peakMap = (map_aug > map_aug1) & (map_aug > map_aug2) & (map_aug > map_aug3) & (map_aug > map_aug4);
    peakMap = peakMap(2:end-1, 2:end-1);
    [X,Y] = find(peakMap);
    score = zeros(length(X),1);
    for i = 1:length(X)
        score(i) = map(X(i),Y(i));
    end