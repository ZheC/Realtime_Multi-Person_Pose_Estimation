addpath('dataset/COCO/coco/MatlabAPI/');
addpath('../testing/util');

mkdir('dataset/COCO/mask2014')
vis = 0;

for mode = 0:1
    
    if mode == 1 
        load('dataset/COCO/mat/coco_kpt.mat');
    else
        load('dataset/COCO/mat/coco_val.mat');
        coco_kpt = coco_val;
    end
    
    L = length(coco_kpt);
    %%
    
    for i = 1:L
        if mode == 1
            img_paths = sprintf('images/train2014/COCO_train2014_%012d.jpg', coco_kpt(i).image_id);
            img_name1 = sprintf('dataset/COCO/mask2014/train2014_mask_all_%012d.png', coco_kpt(i).image_id);
            img_name2 = sprintf('dataset/COCO/mask2014/train2014_mask_miss_%012d.png', coco_kpt(i).image_id);
        else
            img_paths = sprintf('images/val2014/COCO_val2014_%012d.jpg', coco_kpt(i).image_id);
            img_name1 = sprintf('dataset/COCO/mask2014/val2014_mask_all_%012d.png', coco_kpt(i).image_id);
            img_name2 = sprintf('dataset/COCO/mask2014/val2014_mask_miss_%012d.png', coco_kpt(i).image_id);
        end
        
        try
            display([num2str(i) '/ ' num2str(L)]);
            imread(img_name1);
            imread(img_name2);
            continue;
        catch
            display([num2str(i) '/ ' num2str(L)]);
            %joint_all(count).img_paths = RELEASE(i).image_id;
            [h,w,~] = size(imread(['dataset/COCO/', img_paths]));
            mask_all = false(h,w);
            mask_miss = false(h,w);
            flag = 0;
            for p = 1:length(coco_kpt(i).annorect)
                %if this person is annotated
                try
                    seg = coco_kpt(i).annorect(p).segmentation{1};
                catch
                    %display([num2str(i) ' ' num2str(p)]);
                    mask_crowd = logical(MaskApi.decode( coco_kpt(i).annorect(p).segmentation ));
                    temp = and(mask_all, mask_crowd);
                    mask_crowd = mask_crowd - temp;
                    flag = flag + 1;
                    coco_kpt(i).mask_crowd = mask_crowd;
                    continue;
                end
                
                [X,Y] = meshgrid( 1:w, 1:h );
                mask = inpolygon( X, Y, seg(1:2:end), seg(2:2:end));
                mask_all = or(mask, mask_all);
                
                if coco_kpt(i).annorect(p).num_keypoints <= 0
                    mask_miss = or(mask, mask_miss);
                end
            end
            if flag == 1
                mask_miss = not(or(mask_miss,mask_crowd));
                mask_all = or(mask_all, mask_crowd);
            else
                mask_miss = not(mask_miss);
            end
            
            coco_kpt(i).mask_all = mask_all;
            coco_kpt(i).mask_miss = mask_miss;
            
            if mode == 1
                img_name = sprintf('dataset/COCO/mask2014/train2014_mask_all_%012d.png', coco_kpt(i).image_id);
                imwrite(mask_all,img_name);
                img_name = sprintf('dataset/COCO/mask2014/train2014_mask_miss_%012d.png', coco_kpt(i).image_id);
                imwrite(mask_miss,img_name);
            else
                img_name = sprintf('dataset/COCO/mask2014/val2014_mask_all_%012d.png', coco_kpt(i).image_id);
                imwrite(mask_all,img_name);
                img_name = sprintf('dataset/COCO/mask2014/val2014_mask_miss_%012d.png', coco_kpt(i).image_id);
                imwrite(mask_miss,img_name);
            end
            
            if flag == 1 && vis == 1
                im = imread(['dataset/COCO/', img_paths]);
                mapIm = mat2im(mask_all, jet(100), [0 1]);
                mapIm = mapIm*0.5 + (single(im)/255)*0.5;
                figure(1),imshow(mapIm);
                mapIm = mat2im(mask_miss, jet(100), [0 1]);
                mapIm = mapIm*0.5 + (single(im)/255)*0.5;
                figure(2),imshow(mapIm);
                mapIm = mat2im(mask_crowd, jet(100), [0 1]);
                mapIm = mapIm*0.5 + (single(im)/255)*0.5;
                figure(3),imshow(mapIm);
                pause;
                close all;
            elseif flag > 1
                display([num2str(i) ' ' num2str(p)]);
            end
        end
    end
    
    if mode == 1 
        save('coco_kpt_mask.mat', 'coco_kpt', '-v7.3');
    else
        coco_val = coco_kpt;
        save('coco_val_mask.mat', 'coco_val', '-v7.3');
    end
    
end
