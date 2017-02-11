function genJSON(dataset)
    addpath('../testing/util');
    addpath('../testing/util/jsonlab/');

    if(strcmp(dataset, 'COCO'))
        mkdir('dataset/COCO/json')
        count = 1;
        makeFigure = 0;
        validationCount = 0;
        isValidation = 0;
        
        load('dataset/COCO/mat/coco_kpt.mat');
        load('dataset/COCO/mat/coco_val.mat');
        
        for mode = 0:1
            if mode == 0
                RELEASE = coco_kpt;
            else
                RELEASE = coco_val;
            end
            
            trainIdx = 1:1:size(RELEASE,2);

            % In COCO:(1-'nose'	2-'left_eye' 3-'right_eye' 4-'left_ear' 5-'right_ear'
            %          6-'left_shoulder' 7-'right_shoulder'	8-'left_elbow' 9-'right_elbow' 10-'left_wrist'	
            %          11-'right_wrist'	12-'left_hip' 13-'right_hip' 14-'left_knee'	15-'right_knee'	
            %          16-'left_ankle' 17-'right_ankle' )

            for i = trainIdx
                numPeople = length(RELEASE(i).annorect);
                fprintf('prepareJoint: %d/%d (numPeople: %d)\n', i, trainIdx(end), numPeople);
                %allPeopleAnno = RELEASE.annolist(i).annorect;
                prev_center = [];

                if mode == 1
                    if i < 2645
                        validationCount = validationCount + 1;
                        fprintf('My validation! %d, %d\n', i, validationCount);
                        isValidation = 1;
                    else
                        isValidation = 0;
                    end
                else
                    isValidation = 0;
                end

                h = RELEASE(i).annorect.img_height;
                w = RELEASE(i).annorect.img_width;

                for p = 1:numPeople

                    % skip this person if parts number is too low or if
                    % segmentation area is too small
                    if RELEASE(i).annorect(p).num_keypoints < 5 || RELEASE(i).annorect(p).area < 32*32
                        continue;
                    end
                    % skip this person if the distance to exiting person is too small
                    person_center = [RELEASE(i).annorect(p).bbox(1)+RELEASE(i).annorect(p).bbox(3)/2, RELEASE(i).annorect(p).bbox(2)+RELEASE(i).annorect(p).bbox(4)/2];
                    flag = 0;
                    for k = 1:size(prev_center,1)
                        dist = prev_center(k,1:2) - person_center;
                        if norm(dist) < prev_center(k,3)*0.3
                            flag = 1;
                            continue;
                        end
                    end
                    if flag ==1
                        continue;
                    end
                    %fprintf('%d/%d/ image%d:', p,numPeople,i);
                    if mode == 0
                        joint_all(count).dataset = 'COCO';
                    else
                        joint_all(count).dataset = 'COCO_val';
                    end
                    joint_all(count).isValidation = isValidation;
                    anno = RELEASE(i).annorect(p).keypoints;

                    % set image path
                    if mode == 0
                        joint_all(count).img_paths = sprintf('train2014/COCO_train2014_%012d.jpg', RELEASE(i).image_id);
                    else
                        joint_all(count).img_paths = sprintf('val2014/COCO_val2014_%012d.jpg', RELEASE(i).image_id);
                    end
                    %joint_all(count).img_paths = RELEASE(i).image_id;
                    %[h,w,~] = size(imread(['../dataset/COCO/images/', joint_all(count).img_paths]));
                    joint_all(count).img_width = w;
                    joint_all(count).img_height = h;
                    joint_all(count).objpos = person_center;
                    joint_all(count).image_id = RELEASE(i).image_id;
                    joint_all(count).bbox = RELEASE(i).annorect(p).bbox;
                    joint_all(count).segment_area = RELEASE(i).annorect(p).area;
                    joint_all(count).num_keypoints = RELEASE(i).annorect(p).num_keypoints;

                    % set part label: joint_all is (np-3-nTrain)
                    % for this very center person
                    for part = 1:17
                        joint_all(count).joint_self(part, 1) = anno(part*3-2);
                        joint_all(count).joint_self(part, 2) = anno(part*3-1);

                        if(anno(part*3) == 2)
                            joint_all(count).joint_self(part, 3) = 1;
                        elseif(anno(part*3) == 1)
                            joint_all(count).joint_self(part, 3) = 0;
                        else
                            joint_all(count).joint_self(part, 3) = 2;
                        end
                    end

                    % pad it into 17x3
                    dim_1 = size(joint_all(count).joint_self, 1);
                    dim_3 = size(joint_all(count).joint_self, 3);
                    pad_dim = 17 - dim_1;
                    joint_all(count).joint_self = [joint_all(count).joint_self; zeros(pad_dim, 3, dim_3)];
                    % set scale
                    joint_all(count).scale_provided = RELEASE(i).annorect(p).bbox(4)/368;
                    %joint_all(count).scale_provided = RELEASE(i).annorect(p).area;

                    % for other person on the same image
                    count_other = 1;
                    joint_all(count).joint_others = cell(0,0);
                    for op = 1:numPeople
                        if op == p || RELEASE(i).annorect(op).num_keypoints == 0
                            continue; 
                        end
                        anno = RELEASE(i).annorect(op).keypoints;

                        joint_all(count).scale_provided_other(count_other) = RELEASE(i).annorect(op).bbox(4)/368;
                        %joint_all(count).scale_provided_other(count_other) = RELEASE(i).annorect(op).area;
                        joint_all(count).objpos_other{count_other} = [RELEASE(i).annorect(op).bbox(1)+RELEASE(i).annorect(op).bbox(3)/2, RELEASE(i).annorect(op).bbox(2)+RELEASE(i).annorect(op).bbox(4)/2];
                        joint_all(count).bbox_other{count_other} = RELEASE(i).annorect(op).bbox;
                        joint_all(count).segment_area_other(count_other) = RELEASE(i).annorect(op).area;
                        joint_all(count).num_keypoints_other(count_other) = RELEASE(i).annorect(op).num_keypoints;

                        % other people
                        joint_others{count_other} = zeros(17,3);
                        for part = 1:17
                            joint_all(count).joint_others{count_other}(part, 1) = anno(part*3-2);
                            joint_all(count).joint_others{count_other}(part, 2) = anno(part*3-1);

                            if(anno(part*3) == 2)
                                joint_all(count).joint_others{count_other}(part, 3) = 1;
                            elseif(anno(part*3) == 1)
                                joint_all(count).joint_others{count_other}(part, 3) = 0;
                            else
                                joint_all(count).joint_others{count_other}(part, 3) = 2;
                            end

                        end
                        count_other = count_other + 1;
                    end
                    joint_all(count).annolist_index = i;
                    joint_all(count).people_index = p;
                    joint_all(count).numOtherPeople = length(joint_all(count).joint_others);

                    if(makeFigure) % visualizing to debug
                        imshow(['dataset/COCO/images/', joint_all(count).img_paths]);
                        xlim([-joint_all(count).img_width*0.6 joint_all(count).img_width*1.6]) 
                        ylim([-joint_all(count).img_height*0.6 joint_all(count).img_height*1.6])
                        hold on;
                        visiblePart = joint_all(count).joint_self(:,3) == 1;
                        invisiblePart = joint_all(count).joint_self(:,3) == 0;
                        plot(joint_all(count).joint_self(visiblePart, 1), joint_all(count).joint_self(visiblePart,2), 'gx');
                        plot(joint_all(count).joint_self(invisiblePart,1), joint_all(count).joint_self(invisiblePart,2), 'rx');
                        plot(joint_all(count).objpos(1), joint_all(count).objpos(2), 'cs');
                        if(~isempty(joint_all(count).joint_others))
                            for op = 1:size(joint_all(count).joint_others,2)
                                visiblePart = joint_all(count).joint_others{op}(:,3) == 1;
                                invisiblePart = joint_all(count).joint_others{op}(:,3) == 0;
                                plot(joint_all(count).joint_others{op}(visiblePart,1), joint_all(count).joint_others{op}(visiblePart,2), 'mx');
                                plot(joint_all(count).joint_others{op}(invisiblePart,1), joint_all(count).joint_others{op}(invisiblePart,2), 'cx');
                                plot(joint_all(count).objpos_other{op}(1), joint_all(count).objpos_other{op}(2), 'cs');
                            end
                        end
                        %rect_size = 368*joint_all(count).scale_provided/ 1.2;
                        rect_size = 2.1*sqrt(joint_all(count).scale_provided)/ 1.2;
                        max(RELEASE(i).annorect(p).bbox(3), RELEASE(i).annorect(p).bbox(4))
                        sqrt(joint_all(count).scale_provided)
                        rectangle('Position',[joint_all(count).objpos(1)-rect_size, joint_all(count).objpos(2)-rect_size, rect_size*2, rect_size*2], 'EdgeColor','b')
                        pause;
                        close all;
                    end
                    %prev_center = [prev_center; joint_all(count).objpos joint_all(count).scale_provided*368];
                    prev_center = [prev_center; joint_all(count).objpos max(RELEASE(i).annorect(p).bbox(3), RELEASE(i).annorect(p).bbox(4))];
                    count = count + 1;
                    %if(count==10), break; end %scale_provided
                end
                %if(count==10), break; end
            end
        end
        
        opt.FileName = 'dataset/COCO/json/COCO.json';
        opt.FloatFormat = '%.3f';
        savejson('root', joint_all, opt);
    end 