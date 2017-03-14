function [candidates, subset] = connect56LineVec(image, heatMaps, param, vis)

if nargin < 4
    vis = 1;
end

thre = 0.05; %0.1;
model = param.model(param.modelID);
%np = model.np;
%part_str = model.part_str;
count = 0;
candidates = [];

% non-maximum suppression for finding joint candidates
for j = 1:18
    %[Y,X,score] = findPeaks(heatMaps(:,:,j), thre);
    [Y,X,score] = findPeaks(heatMaps(:,:,j), param.thre1);   
    temp = (1:numel(Y)) + count;
    maximum{j} = [X, Y, score, reshape(temp,[numel(Y),1])]; 
    candidates = [candidates; X Y score ones([numel(Y),1])*j];
    count = count + numel(Y);
end
height = size(heatMaps,1)/2;
width = size(heatMaps,2);
kpt_num = 18 + 2;

% find connection in the specified sequence, center 29 is in the position 15
limbSeq = [2 3; 2 6; 3 4; 4 5; 6 7; 7 8; 2 9; 9 10; 10 11; 2 12; 12 13; 13 14; 2 1; 1 15; 15 17; 1 16; 16 18; 3 17; 6 18];
% the middle joints heatmap correpondence
mapIdx = [31 32; 39 40; 33 34; 35 36; 41 42; 43 44; 19 20; 21 22; 23 24; 25 26; 27 28; 29 30; 47 48; 49 50; 53 54; 51 52; 55 56; 37 38; 45 46];
% last number in each row is the total parts number of that person
% the second last number in each row is the score of the overall configuration
subset = [];
% find the parts connection and cluster them into different subset
for k = 1:size(mapIdx,1)
    score_mid = heatMaps(:,:,mapIdx(k,:));
    %maxVal = max(score_mid(:));
    candA = maximum{limbSeq(k,1)};
    candB = maximum{limbSeq(k,2)};

    connection{k} = [];
    nA = size(candA,1);
    nB = size(candB,1);
    indexA = limbSeq(k,1);
    indexB = limbSeq(k,2);
    
    % add parts into the subset in special case
    if(nA ==0 && nB ==0)
        continue;
    elseif nA ==0
        for i = 1:nB
            num = 0;
            for j = 1:size(subset,1)
                if subset(j, indexB) == candB(i,4)
                    num = num+1;
                    continue;
                end
            end
            % if find no partB in the subset, create a new subset
            if num==0
                subset = [subset; zeros(1,kpt_num)];
                subset(end, indexB) = candB(i,4);
                subset(end, end) = 1;
                subset(end, end-1) = candB(i,3);
            end
        end
        continue;
    elseif nB ==0       
        for i = 1:nA
            num = 0;
            for j = 1:size(subset,1)
                if subset(j, indexA) == candA(i,4)
                    num = num+1;
                    continue;
                end
            end
            % if find no partA in the subset, create a new subset
            if num==0
                subset = [subset; zeros(1,kpt_num)];
                subset(end, indexA) = candA(i,4);
                subset(end, end) = 1;
                subset(end, end-1) = candA(i,3);
            end
        end
        continue;
    end
    
    temp =[];
    for i = 1:nA
        for j = 1:nB
            midPoint(1,:) = round(candA(i,1:2)*0.5 + candB(j,1:2)*0.5);
            %midPoint(2,:) = round(candA(i,1:2)*0.5 + candB(j,1:2)*0.5);
            midPoint(2,:) = midPoint(1,:);
            
            vec = candB(j,1:2) - candA(i,1:2);
            %mid_num = max(min(min(abs(vec(1)),abs(vec(2))),15),1);
            norm_vec = sqrt(vec(1)^2+vec(2)^2);
            vec = vec/norm_vec;
            
            score = vec(1)*score_mid(midPoint(1,2), midPoint(1,1),1) + vec(2)*score_mid(midPoint(2,2), midPoint(2,1),2);

%             plot(candA(i,1), candA(i,2), 'rx', 'Linewidth', 2);
%             plot(candB(j,1), candB(j,2), 'rx', 'Linewidth', 2);
%             plot(midPoint(1,1), midPoint(1,2), 'yx', 'Linewidth', 2);
%             plot(midPoint(2,1), midPoint(2,2), 'yx', 'Linewidth', 2);
            
            
            height_n = height;
%             if k > 13 && k < 18
%                 height_n = height/2;
%             elseif k== 18 || k == 19
%                 height_n = height/1.25;
%             else
%                 height_n = height;
%             end

            suc_ratio = 0;
            mid_score = zeros(1, 1);
            %suc_flag = 1;
            mid_num = 10; 
            
            if score > -100 %&& norm_vec < height_n %0.01
                %imshow(image), hold on;
                p_sum = 0;
                p_count = 0;
                
                x = linspace(candA(i,1),candB(j,1), mid_num);
                y = linspace(candA(i,2),candB(j,2), mid_num);
                for lm = 1:mid_num
                    mx = round(x(lm));
                    my = round(y(lm));
                    pred = squeeze(score_mid(my, mx, 1:2));
                    score = vec(2)*pred(2) + vec(1)*pred(1);
                    if score> param.thre2 %norm(pred) > 0.01
                        p_sum = p_sum + score;
                        p_count = p_count +1;
%                     else
%                         suc_flag = 0;
%                         continue;
                    end
                end
                
                suc_ratio = p_count/mid_num;
%                 if suc_flag == 0
%                     continue;
%                 end
                
                mid_score(1) = p_sum/p_count + min(height_n/norm_vec-1,0);
            end

            if mid_score(1) > 0 && suc_ratio > 0.8 %0.7 %second threshold
                score = sum(mid_score);
                % parts score + connection score
                score_all = score + candA(i, 3) + candB(j, 3);
                temp =  [temp; i j score score_all];
            end
        end
    end
    
    %% select the top num connection, assuming that each part occur only once
    % sort rows in descending order 
    if size(temp,1) >0
        temp = sortrows(temp,-3); %based on connection score
        %temp = sortrows(temp,-4); %based on parts + connection score
    end
    % set the connection number as the samller parts set number
    num = min(nA, nB);
    cnt = 0;
    occurA = zeros(1, nA);
    occurB = zeros(1, nB);
    
    for row =1:size(temp,1) 
        if cnt==num
            break;
        else
            i = temp(row,1);
            j = temp(row,2);
            score = temp(row,3);
            if occurA(i) == 0 && occurB(j) == 0 %&& score> (1+thre)
                connection{k} = [connection{k}; candA(i,4) candB(j,4) score];
                cnt = cnt+1;
                occurA(i) = 1;
                occurB(j) = 1;
            end
        end
    end
    
    %% cluster all the joints candidates into subset based on the part connection
    temp = connection{k};
    if(size(temp,1)==0)
        continue;
    end
    % initialize first body part connection 15&16 
    if k==1
        subset = zeros(size(temp,1),kpt_num); %last number in each row is the parts number of that person
        for i = 1:size(temp,1)
            subset(i, limbSeq(1, 1:2)) = temp(i,1:2);
            subset(i, end) = 2;
            % add the score of parts and the connection
            subset(i, end-1) = sum(candidates(temp(i,1:2),3)) + temp(i,3);
        end
    elseif k==18 || k==19
        %add 15 16 connection
        partA = temp(:,1);
        partB = temp(:,2);
        indexA = limbSeq(k,1);
        indexB = limbSeq(k,2);

        for i = 1:size(temp,1)
            for j = 1:size(subset,1)
                if subset(j, indexA) == partA(i) && subset(j, indexB) == 0
                    subset(j, indexB) = partB(i);
                elseif subset(j, indexB) == partB(i) && subset(j, indexA) == 0
                    subset(j, indexA) = partA(i);
                end
            end
        end
        continue;
    else
        % partA is already in the subset, find its connection partB
        partA = temp(:,1);
        partB = temp(:,2);
        indexA = limbSeq(k,1);
        indexB = limbSeq(k,2);

        for i = 1:size(temp,1)
            num = 0;
            for j = 1:size(subset,1)
                if subset(j, indexA) == partA(i)
                    subset(j, indexB) = partB(i);
                    num = num+1;
                    subset(j, end) = subset(j,end)+1;
                    subset(j, end-1) = subset(j, end-1)+ candidates(partB(i),3) + temp(i,3);
                end
            end
            % if find no partA in the subset, create a new subset
            if num==0
                subset = [subset; zeros(1,kpt_num)];
                subset(end, indexA) = partA(i);
                subset(end, indexB) = partB(i);
                subset(end, end) = 2;
                subset(end, end-1) = sum(candidates(temp(i,1:2),3)) + temp(i,3);
            end
        end
    end
end

%% delete some rows of subset which has few parts occur
%%{
deleIdx = [];
for i=1:size(subset,1)
    %if(subset(i,end)<5)
    if (subset(i,end)<3) || (subset(i,end-1)/subset(i,end)<0.2)
        deleIdx = [deleIdx;i];
    end
end
subset(deleIdx,:) = [];
%}

%axes(ha(1));
%imshow(image);
colors = hsv(length(limbSeq));
facealpha = 0.6;
stickwidth = 4;

if vis == 1
    %{
    for j = 19:52
        score_parts = heatMaps(:,:,j);
        %thre = max(0.1 * max(score_parts(:)), thre);
        [Y,X,score] = findPeaks(score_parts, thre);   
        temp = (1:numel(Y)) + count;
        maximum{j} = [X, Y, score, reshape(temp,[numel(Y),1])]; 
        candidates = [candidates; X Y score ones([numel(Y),1])*j];
        count = count + numel(Y);
    end
    %}
    joint_color = [255, 0, 0;  255, 85, 0;  255, 170, 0;  255, 255, 0;  170, 255, 0;   85, 255, 0;  0, 255, 0;  0, 255, 85;  0, 255, 170;  0, 255, 255;  0, 170, 255;  0, 85, 255;  0, 0, 255;   85, 0, 255;  170, 0, 255;  255, 0, 255;  255, 0, 170;  255, 0, 85];
    for num = 1:size(subset,1)
        %imshow(image);
        for i = 1:18
            index = subset(num,i);
            if index == 0 
                continue;
            end
            X = candidates(index,1);
            Y = candidates(index,2);
            image = insertShape(image, 'FilledCircle', [X Y 5], 'Color', joint_color(i,:)); 
        end
    end
    
    imshow(image), hold on;
    %{
    for idx = 1:size(candidates,1)
        if candidates(idx,4)<19
            plot(candidates(idx,1), candidates(idx,2), 'rx', 'Linewidth', 1);
            %text(candidates(idx,1), candidates(idx,2), num2str(candidates(idx,4)), 'Color', 'y', 'Linewidth', 2);
        %else
            %plot(candidates(idx,1), candidates(idx,2), 'gx', 'Linewidth', 2);
            %text(candidates(idx,1), candidates(idx,2), num2str(round(candidates(idx,3),2)), 'Color', 'y', 'Linewidth', 2);
        end
    end
    %}
    %pause;
    %export_fig('video/connect_0.png');
    
    % visualize the final connection result
    for i = 1:17%size(limbSeq,1)
        for num = 1:size(subset,1)
        %imshow(image);
        
            index = subset(num,limbSeq(i,1:2));
            if sum(index==0)>0
                continue;
            end
            X = candidates(index,1);
            Y = candidates(index,2);

            if(~sum(isnan(X)))
                mX = mean(X);
                mY = mean(Y);
                [~,~,V] = svd(cov([X-mX Y-mY]));
                v = V(2,:);

                pts = [X Y];
                pts = [pts; pts + stickwidth*repmat(v,2,1); pts - stickwidth*repmat(v,2,1)];
                A = cov([pts(:,1)-mX pts(:,2)-mY]);
                if any(X),
                    he(i) = filledellipse(A,[mX mY],colors(i,:),facealpha);
                end
            end
        end
        %pause;
        %export_fig(['video/connect_' num2str(i) '.png']);
    end
end

end

function h = filledellipse(A,xc,col,facealpha)
    [V,D] = eig(A);
    % define points on a unit circle
    th = linspace(0, 2*pi, 50);
    pc = [cos(th);sin(th)];

    % warp it into the ellipse
    pe = sqrtm(A)*pc;
    pe = bsxfun(@plus, xc(:), pe);
    h = patch(pe(1,:),pe(2,:),col);
    set(h,'FaceAlpha',facealpha);
    set(h,'EdgeAlpha',0);
end

function [X,Y,score] = findPeaks(map, thre)
    %filter = fspecial('gaussian', [3 3], 2);
    %map_smooth = conv2(map, filter, 'same');
    map_smooth = map;
    map_smooth(map_smooth < thre) = 0;
    
    map_aug = -1*zeros(size(map_smooth,1)+2, size(map_smooth,2)+2);
    map_aug1 = map_aug;
    map_aug2 = map_aug;
    map_aug3 = map_aug;
    map_aug4 = map_aug;
    
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
    
    if isempty(X)
        return;
    end
    
    deleIdx = [];
    flag = ones(1, length(X));
    for i = 1:length(X)
        if(flag(i)>0)
            for j = (i+1):length(X)
                if norm([X(i)-X(j),Y(i)-Y(j)]) <= 6
                    flag(j) = 0;
                    deleIdx = [deleIdx;j];
                end
            end
        end
    end
    X(deleIdx,:) = [];
    Y(deleIdx,:) = [];
    score(deleIdx,:) = [];
end
