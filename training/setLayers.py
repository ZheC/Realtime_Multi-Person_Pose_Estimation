import sys
import os
import math
import argparse
import json
from ConfigParser import SafeConfigParser
# parser = SafeConfigParser()
# parser.read('caffe_path.cfg')
# caffe_path = parser.get('caffe', 'path')
# sys.path.append('%s/python' % caffe_path)

caffe_path = '/home/zhecao/caffe_train/'
import sys, os
sys.path.insert(0, os.path.join(caffe_path, 'python'))
import caffe
from caffe import layers as L  # pseudo module using __getattr__ magic to generate protobuf messages
from caffe import params as P  # pseudo module using __getattr__ magic to generate protobuf messages

def setLayers_twoBranches(data_source, batch_size, layername, kernel, stride, outCH, label_name, transform_param_in, deploy=False, batchnorm=0, lr_mult_distro=[1,1,1]):
    # it is tricky to produce the deploy prototxt file, as the data input is not from a layer, so we have to creat a workaround
    # producing training and testing prototxt files is pretty straight forward
    n = caffe.NetSpec()
    assert len(layername) == len(kernel)
    assert len(layername) == len(stride)
    assert len(layername) == len(outCH)
    num_parts = transform_param['num_parts']

    if deploy == False and "lmdb" not in data_source:
        if(len(label_name)==1):
            n.data, n.tops[label_name[0]] = L.HDF5Data(hdf5_data_param=dict(batch_size=batch_size, source=data_source), ntop=2)
        elif(len(label_name)==2):
            n.data, n.tops[label_name[0]], n.tops[label_name[1]] = L.HDF5Data(hdf5_data_param=dict(batch_size=batch_size, source=data_source), ntop=3)
    # produce data definition for deploy net
    elif deploy == False:
        n.data, n.tops['label'] = L.CPMData(data_param=dict(backend=1, source=data_source, batch_size=batch_size), 
                                                    cpm_transform_param=transform_param_in, ntop=2)
        n.tops[label_name[2]], n.tops[label_name[3]], n.tops[label_name[4]], n.tops[label_name[5]] = L.Slice(n.label, slice_param=dict(axis=1, slice_point=[38, num_parts+1, num_parts+39]), ntop=4)
        n.tops[label_name[0]] = L.Eltwise(n.tops[label_name[2]], n.tops[label_name[4]], operation=P.Eltwise.PROD)
        n.tops[label_name[1]] = L.Eltwise(n.tops[label_name[3]], n.tops[label_name[5]], operation=P.Eltwise.PROD)

    else:
        input = "data"
        dim1 = 1
        dim2 = 4
        dim3 = 368
        dim4 = 368
        # make an empty "data" layer so the next layer accepting input will be able to take the correct blob name "data",
        # we will later have to remove this layer from the serialization string, since this is just a placeholder
        n.data = L.Layer()

    # something special before everything
    n.image, n.center_map = L.Slice(n.data, slice_param=dict(axis=1, slice_point=3), ntop=2)
    n.silence2 = L.Silence(n.center_map, ntop=0)
    #n.pool_center_lower = L.Pooling(n.center_map, kernel_size=9, stride=8, pool=P.Pooling.AVE)

    # just follow arrays..CPCPCPCPCCCC....
    last_layer = ['image', 'image']
    stage = 1
    conv_counter = 1
    pool_counter = 1
    drop_counter = 1
    local_counter = 1
    state = 'image' # can be image or fuse
    share_point = 0

    for l in range(0, len(layername)):
        if layername[l] == 'V': #pretrained VGG layers
            conv_name = 'conv%d_%d' % (pool_counter, local_counter)
            lr_m = lr_mult_distro[0]
            n.tops[conv_name] = L.Convolution(n.tops[last_layer[0]], kernel_size=kernel[l],
                                                  num_output=outCH[l], pad=int(math.floor(kernel[l]/2)),
                                                  param=[dict(lr_mult=lr_m, decay_mult=1), dict(lr_mult=lr_m*2, decay_mult=0)],
                                                  weight_filler=dict(type='gaussian', std=0.01),
                                                  bias_filler=dict(type='constant'))
            last_layer[0] = conv_name
            last_layer[1] = conv_name
            print '%s\tch=%d\t%.1f' % (last_layer[0], outCH[l], lr_m)
            ReLUname = 'relu%d_%d' % (pool_counter, local_counter)
            n.tops[ReLUname] = L.ReLU(n.tops[last_layer[0]], in_place=True)
            local_counter += 1
            print ReLUname
        if layername[l] == 'B':
            pool_counter += 1
            local_counter = 1
        if layername[l] == 'C':
            if state == 'image':
                #conv_name = 'conv%d_stage%d' % (conv_counter, stage)
                conv_name = 'conv%d_%d_CPM' % (pool_counter, local_counter) # no image state in subsequent stages
                if stage == 1:
                    lr_m = lr_mult_distro[1]
                else:
                    lr_m = lr_mult_distro[1]
            else: # fuse
                conv_name = 'Mconv%d_stage%d' % (conv_counter, stage)
                lr_m = lr_mult_distro[2]
                conv_counter += 1
            #if stage == 1:
            #    lr_m = 1
            #else:
            #    lr_m = lr_sub
            n.tops[conv_name] = L.Convolution(n.tops[last_layer[0]], kernel_size=kernel[l],
                                                  num_output=outCH[l], pad=int(math.floor(kernel[l]/2)),
                                                  param=[dict(lr_mult=lr_m, decay_mult=1), dict(lr_mult=lr_m*2, decay_mult=0)],
                                                  weight_filler=dict(type='gaussian', std=0.01),
                                                  bias_filler=dict(type='constant'))
            last_layer[0] = conv_name
            last_layer[1] = conv_name
            print '%s\tch=%d\t%.1f' % (last_layer[0], outCH[l], lr_m)

            if layername[l+1] != 'L':
                if(state == 'image'):
                    if(batchnorm == 1):
                        batchnorm_name = 'bn%d_stage%d' % (conv_counter, stage)
                        n.tops[batchnorm_name] = L.BatchNorm(n.tops[last_layer[0]], 
                                                             param=[dict(lr_mult=0), dict(lr_mult=0), dict(lr_mult=0)])
                                                             #scale_filler=dict(type='constant', value=1), shift_filler=dict(type='constant', value=0.001))
                        last_layer[0] = batchnorm_name
                    #ReLUname = 'relu%d_stage%d' % (conv_counter, stage)
                    ReLUname = 'relu%d_%d_CPM' % (pool_counter, local_counter)
                    n.tops[ReLUname] = L.ReLU(n.tops[last_layer[0]], in_place=True)
                else:
                    if(batchnorm == 1):
                        batchnorm_name = 'Mbn%d_stage%d' % (conv_counter, stage)
                        n.tops[batchnorm_name] = L.BatchNorm(n.tops[last_layer[0]], 
                                                             param=[dict(lr_mult=0), dict(lr_mult=0), dict(lr_mult=0)])
                                                             #scale_filler=dict(type='constant', value=1), shift_filler=dict(type='constant', value=0.001))
                        last_layer[0] = batchnorm_name
                    ReLUname = 'Mrelu%d_stage%d' % (conv_counter, stage)
                    n.tops[ReLUname] = L.ReLU(n.tops[last_layer[0]], in_place=True)
                #last_layer = ReLUname
                print ReLUname

            #conv_counter += 1
            local_counter += 1

        elif layername[l] == 'C2':
            for level in range(0,2):
                if state == 'image':
                    #conv_name = 'conv%d_stage%d' % (conv_counter, stage)
                    conv_name = 'conv%d_%d_CPM_L%d' % (pool_counter, local_counter, level+1) # no image state in subsequent stages
                    if stage == 1:
                        lr_m = lr_mult_distro[1]
                    else:
                        lr_m = lr_mult_distro[1]
                else: # fuse
                    conv_name = 'Mconv%d_stage%d_L%d' % (conv_counter, stage, level+1)
                    lr_m = lr_mult_distro[2]
                    #conv_counter += 1
                #if stage == 1:
                #    lr_m = 1
                #else:
                #    lr_m = lr_sub
                if layername[l+1] == 'L2' or layername[l+1] == 'L3':
                    if level == 0:
                        outCH[l] = 38
                    else:
                        outCH[l] = 19

                n.tops[conv_name] = L.Convolution(n.tops[last_layer[level]], kernel_size=kernel[l],
                                                      num_output=outCH[l], pad=int(math.floor(kernel[l]/2)),
                                                      param=[dict(lr_mult=lr_m, decay_mult=1), dict(lr_mult=lr_m*2, decay_mult=0)],
                                                      weight_filler=dict(type='gaussian', std=0.01),
                                                      bias_filler=dict(type='constant'))
                last_layer[level] = conv_name
                print '%s\tch=%d\t%.1f' % (last_layer[level], outCH[l], lr_m)

                if layername[l+1] != 'L2' and layername[l+1] != 'L3':
                    if(state == 'image'):
                        if(batchnorm == 1):
                            batchnorm_name = 'bn%d_stage%d_L%d' % (conv_counter, stage, level+1)
                            n.tops[batchnorm_name] = L.BatchNorm(n.tops[last_layer[level]], 
                                                                 param=[dict(lr_mult=0), dict(lr_mult=0), dict(lr_mult=0)])
                                                                 #scale_filler=dict(type='constant', value=1), shift_filler=dict(type='constant', value=0.001))
                            last_layer[level] = batchnorm_name
                        #ReLUname = 'relu%d_stage%d' % (conv_counter, stage)
                        ReLUname = 'relu%d_%d_CPM_L%d' % (pool_counter, local_counter, level+1)
                        n.tops[ReLUname] = L.ReLU(n.tops[last_layer[level]], in_place=True)
                    else:
                        if(batchnorm == 1):
                            batchnorm_name = 'Mbn%d_stage%d_L%d' % (conv_counter, stage, level+1)
                            n.tops[batchnorm_name] = L.BatchNorm(n.tops[last_layer[level]], 
                                                                 param=[dict(lr_mult=0), dict(lr_mult=0), dict(lr_mult=0)])
                                                                 #scale_filler=dict(type='constant', value=1), shift_filler=dict(type='constant', value=0.001))
                            last_layer[level] = batchnorm_name
                        ReLUname = 'Mrelu%d_stage%d_L%d' % (conv_counter, stage, level+1)
                        n.tops[ReLUname] = L.ReLU(n.tops[last_layer[level]], in_place=True)
                    print ReLUname

            conv_counter += 1
            local_counter += 1
            

        elif layername[l] == 'P': # Pooling
            n.tops['pool%d_stage%d' % (pool_counter, stage)] = L.Pooling(n.tops[last_layer[0]], kernel_size=kernel[l], stride=stride[l], pool=P.Pooling.MAX)
            last_layer[0] = 'pool%d_stage%d' % (pool_counter, stage)
            pool_counter += 1
            local_counter = 1
            conv_counter += 1
            print last_layer[0]

        elif layername[l] == 'L':
            # Loss: n.loss layer is only in training and testing nets, but not in deploy net.
            if deploy == False and "lmdb" not in data_source:
                n.tops['map_vec_stage%d' % stage] = L.Flatten(n.tops[last_layer[0]])
                n.tops['loss_stage%d' % stage] = L.EuclideanLoss(n.tops['map_vec_stage%d' % stage], n.tops[label_name[1]])
            elif deploy == False:
                level = 1
                name = 'weight_stage%d' % stage
                n.tops[name] = L.Eltwise(n.tops[last_layer[level]], n.tops[label_name[(level+2)]], operation=P.Eltwise.PROD)
                n.tops['loss_stage%d' % stage] = L.EuclideanLoss(n.tops[name], n.tops[label_name[level]])
                
            print 'loss %d' % stage
            stage += 1
            conv_counter = 1
            pool_counter = 1
            drop_counter = 1
            local_counter = 1
            state = 'image'

        elif layername[l] == 'L2':
            # Loss: n.loss layer is only in training and testing nets, but not in deploy net.
            weight = [lr_mult_distro[3],1];
            # print lr_mult_distro[3]
            for level in range(0,2):
                if deploy == False and "lmdb" not in data_source:
                    n.tops['map_vec_stage%d_L%d' % (stage, level+1)] = L.Flatten(n.tops[last_layer[level]])
                    n.tops['loss_stage%d_L%d' % (stage, level+1)] = L.EuclideanLoss(n.tops['map_vec_stage%d' % stage], n.tops[label_name[level]], loss_weight=weight[level])
                elif deploy == False:
                    name = 'weight_stage%d_L%d' % (stage, level+1)
                    n.tops[name] = L.Eltwise(n.tops[last_layer[level]], n.tops[label_name[(level+2)]], operation=P.Eltwise.PROD)
                    n.tops['loss_stage%d_L%d' % (stage, level+1)] = L.EuclideanLoss(n.tops[name], n.tops[label_name[level]], loss_weight=weight[level])

                print 'loss %d level %d' % (stage, level+1)
            
            stage += 1
            #last_connect = last_layer
            #last_layer = 'image'
            conv_counter = 1
            pool_counter = 1
            drop_counter = 1
            local_counter = 1
            state = 'image'

        elif layername[l] == 'L3':
            # Loss: n.loss layer is only in training and testing nets, but not in deploy net.
            weight = [lr_mult_distro[3],1];
            # print lr_mult_distro[3]
            if deploy == False:
                level = 0
                n.tops['loss_stage%d_L%d' % (stage, level+1)] = L.Euclidean2Loss(n.tops[last_layer[level]], n.tops[label_name[level]], n.tops[label_name[2]], loss_weight=weight[level])
                print 'loss %d level %d' % (stage, level+1)
                level = 1
                n.tops['loss_stage%d_L%d' % (stage, level+1)] = L.EuclideanLoss(n.tops[last_layer[level]], n.tops[label_name[level]], loss_weight=weight[level])
                print 'loss %d level %d' % (stage, level+1)
            
            stage += 1
            #last_connect = last_layer
            #last_layer = 'image'
            conv_counter = 1
            pool_counter = 1
            drop_counter = 1
            local_counter = 1
            state = 'image'

        elif layername[l] == 'D':
            if deploy == False:
                n.tops['drop%d_stage%d' % (drop_counter, stage)] = L.Dropout(n.tops[last_layer[0]], in_place=True, dropout_param=dict(dropout_ratio=0.5))
                drop_counter += 1
        elif layername[l] == '@':
            #if not share_point:
            #    share_point = last_layer
            n.tops['concat_stage%d' % stage] = L.Concat(n.tops[last_layer[0]], n.tops[last_layer[1]], n.tops[share_point], concat_param=dict(axis=1))
            
            local_counter = 1
            state = 'fuse'
            last_layer[0] = 'concat_stage%d' % stage
            last_layer[1] = 'concat_stage%d' % stage
            print last_layer
        elif layername[l] == '$':
            share_point = last_layer[0]
            pool_counter += 1
            local_counter = 1
            print 'share'

    # final process
    stage -= 1
    #if stage == 1:
    #    n.silence = L.Silence(n.pool_center_lower, ntop=0)

    if deploy == False:
        return str(n.to_proto())
        # for generating the deploy net
    else:
        # generate the input information header string
        deploy_str = 'input: {}\ninput_dim: {}\ninput_dim: {}\ninput_dim: {}\ninput_dim: {}'.format('"' + input + '"',
                                                                                                    dim1, dim2, dim3, dim4)
        # assemble the input header with the net layers string.  remove the first placeholder layer from the net string.
        return deploy_str + '\n' + 'layer {' + 'layer {'.join(str(n.to_proto()).split('layer {')[2:])


def writePrototxts(dataFolder, sub_dir, batch_size, layername, kernel, stride, outCH, transform_param_in, base_lr, folder_name, label_name='label_1st', batchnorm=0, lr_mult_distro=[1,1,1], new=0):
    # write the net prototxt files out
    if new == 6:
        print 'weight'
        with open('%s/pose_train_test.prototxt' % sub_dir, 'w') as f:
            print 'writing train_test prototxt'
            str_to_write = setLayers_twoBranches(source, batch_size, layername, kernel, stride, outCH, label_name, transform_param_in, deploy=False, batchnorm=batchnorm, lr_mult_distro=lr_mult_distro)
            f.write(str_to_write)

        with open('%s/pose_deploy.prototxt' % sub_dir, 'w') as f:
            print 'writing deploy prototxt'
            str_to_write = str(setLayers_twoBranches('', 0, layername, kernel, stride, outCH, label_name, transform_param_in, deploy=True, batchnorm=batchnorm, lr_mult_distro=lr_mult_distro))
            f.write(str_to_write)

    solver_string = getSolverPrototxt(base_lr, folder_name)
    with open('%s/pose_solver.prototxt' % sub_dir, "w") as f:
        f.write('%s' % solver_string)

    bash_string = getBash()
    with open('%s/train_pose.sh' % sub_dir, "w") as f:
        f.write('%s' % bash_string)

    # train files
    command = 'find %s -name "batch*" | sort > %s/filelist_train.txt' % (dataFolder, sub_dir)
    print command
    os.system(command)


def getSolverPrototxt(base_lr, folder_name):
    string = 'net: "pose_train_test.prototxt"\n\
# test_iter specifies how many forward passes the test should carry out.\n\
# In the case of MNIST, we have test batch size 100 and 100 test iterations,\n\
# covering the full 10,000 testing images.\n\
#test_iter: 100\n\
# Carry out testing every 500 training iterations.\n\
#test_interval: 500\n\
# The base learning rate, momentum and the weight decay of the network.\n\
base_lr: %f\n\
momentum: 0.9\n\
weight_decay: 0.0005\n\
# The learning rate policy\n\
lr_policy: "step"\n\
gamma: 0.333\n\
#stepsize: 29166\n\
stepsize: 136106 #68053\n\
# Display every 100 iterations\n\
display: 5\n\
# The maximum number of iterations\n\
max_iter: 600000\n\
# snapshot intermediate results\n\
snapshot: 2000\n\
snapshot_prefix: "%s/pose"\n\
# solver mode: CPU or GPU\n\
solver_mode: GPU\n' % (base_lr, folder_name)
    return string


def calcAndWriteStat(sub_dir, layername, kernel, stride, outCH, args):
    nStage = layername.count('L')
    current_x = args.inputsize_x
    current_y = args.inputsize_y
    current_ch = 3
    mem = current_x * current_y * (4+4) * 4
    flop = 0
    last_flop = 0
    nparam = 0

    for l in range(len(layername)):
        if layername[l] == 'C':
            nparam += kernel[l]*kernel[l]*current_ch*outCH[l]
            flop += kernel[l]*kernel[l]*current_ch*outCH[l]*current_x*current_y
            mem += kernel[l]*kernel[l]*current_ch*outCH[l]*4 #parameter
            current_ch = outCH[l]
        elif layername[l] == 'P':
            current_x = current_x / stride[l]
            current_y = current_y / stride[l]
        elif layername[l] == 'L':
            last_CH = current_ch
            current_x = args.inputsize_x
            current_y = args.inputsize_y
            current_ch = 3
        elif layername[l] == '@':
            current_ch += last_CH

        # for all non-in-place feature map, cpu_data and cpu_diff
        if layername[l] != 'D' and layername[l] != 'L' and layername[l] != '@':
            mem += current_x * current_y * outCH[l] * 4 * 2 
        print 'LAYER %s | mem: %d, flop: %d, nparam: %d, current_ch: %d' % (layername[l], mem, flop-last_flop, nparam, current_ch)
        last_flop = flop

    mem += current_x * current_y * outCH[-1] * 4 #label
    mem *= args.batch_size

    # backward for RF
    loc_of_loss = layername.index('L')
    print loc_of_loss
    rf_img1 = 1
    for l in range(loc_of_loss, -1, -1):
        if layername[l] == 'C' or layername[l] == 'P':
            rf_img1 = (rf_img1-1)*stride[l] + kernel[l]

    if nStage >= 2:
        rf_heat = 1
        for l in range(len(layername)-1, -1, -1):
            if layername[l] == 'C' or layername[l] == 'P':
                rf_heat = (rf_heat-1)*stride[l] + kernel[l]
            if layername[l] == '@':
                break
        rf_img2 = 1
        for l in range(len(layername)-1, -1, -1):
            if layername[l] == 'C' or layername[l] == 'P':
                rf_img2 = (rf_img2-1)*stride[l] + kernel[l]
            if layername[l] == 'L' and l < len(layername)-1:
                break

    # print "rf: %d %d %d" % (rf_img1,rf_heat,rf_img2)

    dictionary = dict()
    dictionary['mem'] = mem
    dictionary['flop'] = flop
    dictionary['nparam'] = nparam
    if nStage >= 2:
        dictionary['rf'] = [rf_img1, rf_heat, rf_img2]
    else:
        dictionary['rf'] = rf_img1
    with open('%s/net_spec.json'%sub_dir, 'w') as outfile:
        json.dump(dictionary, outfile)

def getBash():
    return ('#!/usr/bin/env sh\n\
%s/build/tools/caffe train --solver=pose_solver.prototxt --gpu=$1 \
--weights=../../../model/vgg/VGG_ILSVRC_19_layers.caffemodel \
2>&1 | tee ./output.txt' % caffe_path)

if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument('--exp', type=int, default=1, help='exp number[1-4]')
    parser.add_argument('--inputsize', type=str, default='304,304', help='exp number[1-4]')
    args = parser.parse_args()
    args.inputsize_x, args.inputsize_y = map(int, args.inputsize.split(','))
    exp = args.exp
    batch_size = 8
    args.batch_size = batch_size

    # Two branch: weight = 1, scale 0.5~1.1, fix the mode, base_lr = 4e-5, batch_size = 10
    if(exp == 1):
        directory = 'COCO_exp_caffe/pose56/exp22/'
        serverFolder = '/home/zhecao/COCO_kpt/pose56/exp22'
        base_folder = '/media/posenas4b/User/zhe/arch/'+directory+'model'
        dataFolder = '/home/zhecao/COCO_kpt/lmdb_trainVal'
        source = '/home/zhecao/COCO_kpt/lmdb_trainVal'
        base_lr = 4e-5   # 2e-5
        batch_size = 10
        np = 56    # num_parts
        lr_mult_distro = [1.0, 1.0, 4.0, 1]
        transform_param = dict(stride=8, crop_size_x=368, crop_size_y=368,
                                 target_dist=0.6, scale_prob=1, scale_min=0.5, scale_max=1.1,
                                 max_rotate_degree=40, center_perterb_max=40, do_clahe=False,
                                 visualize=False, np_in_lmdb=17, num_parts=np)
        nCP = 3
        if not os.path.exists(directory):
            os.makedirs(directory)
        stage = 6

        for nc in range(0,1):
            layername = ['V','V','P'] * 2  +  ['V'] * 4 + ['P']  +  ['V'] * 2 + ['C'] * 2     + ['$'] + ['C2'] * 3 + ['C2'] * 2    + ['L2'] # first-stage
            kernel =    [ 3,  3,  2 ] * 2  +  [ 3 ] * 4 + [ 2 ]  +  [ 3 ] * 2 + [ 3 ] * 2     + [ 0 ] + [ 3 ] * 3  + [ 1 ] * 2     + [ 0 ] # first-stage
            outCH =     [64]*3 + [128]* 3  +  [256] * 4 + [256]  +  [512] * 2 + [256] + [128] + [ 0 ] + [128] * 3  + [512] +[np*2] + [ 0 ] # first-stage
            stride =    [ 1 , 1,  2 ] * 2  +  [ 1 ] * 4 + [ 2 ]  +  [ 1 ] * 2 + [ 1 ] * 2     + [ 0 ] + [ 1 ] * 3  + [ 1 ] * 2     + [ 0 ] # first-stage

            #if stage >= 2:
            for s in range(2, stage+1):
                layername += ['@'] + ['C2'] * 7         +  ['L2']
                kernel +=    [ 0 ] + [ 7 ] * 5 + [1,1]  +  [ 0 ]
                outCH +=     [ 0 ] + [128] * 6 + [np*2] +  [ 0 ]
                stride +=    [ 0 ] + [ 1 ] * 7          +  [ 0 ]
                   
            sub_dir = directory
            d_caffemodel = base_folder
            if not os.path.exists(sub_dir):
                os.makedirs(sub_dir)
            if not os.path.exists(d_caffemodel): # for storing caffe models
                os.makedirs(d_caffemodel)

            label_name = ['label_vec', 'label_heat', 'vec_weight', 'heat_weight', 'vec_temp', 'heat_temp']
            writePrototxts(dataFolder, sub_dir, batch_size, layername, kernel, stride, outCH, transform_param, base_lr, d_caffemodel, label_name, 0, lr_mult_distro, 6)

            sub_dir = serverFolder
            if not os.path.exists(sub_dir):
                os.makedirs(sub_dir)
            writePrototxts(dataFolder, sub_dir, batch_size, layername, kernel, stride, outCH, transform_param, base_lr, d_caffemodel, label_name, 0, lr_mult_distro, 6)

