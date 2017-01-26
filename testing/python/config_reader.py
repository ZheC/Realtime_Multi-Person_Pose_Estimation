from configobj import ConfigObj
import numpy as np


def config_reader():
    config = ConfigObj('config')

    param = config['param']
    model_id = param['modelID']
    model = config['models'][model_id]
    model['boxsize'] = int(model['boxsize'])
    model['stride'] = int(model['stride'])
    model['padValue'] = int(model['padValue'])
    #param['starting_range'] = float(param['starting_range'])
    #param['ending_range'] = float(param['ending_range'])
    param['octave'] = int(param['octave'])
    param['use_gpu'] = int(param['use_gpu'])
    param['starting_range'] = float(param['starting_range'])
    param['ending_range'] = float(param['ending_range'])
    param['scale_search'] = map(float, param['scale_search'])
    param['thre1'] = float(param['thre1'])
    param['thre2'] = float(param['thre2'])
    param['thre3'] = float(param['thre3'])
    param['mid_num'] = int(param['mid_num'])
    param['min_num'] = int(param['min_num'])
    param['crop_ratio'] = float(param['crop_ratio'])
    param['bbox_ratio'] = float(param['bbox_ratio'])
    param['GPUdeviceNumber'] = int(param['GPUdeviceNumber'])

    return param, model

if __name__ == "__main__":
    config_reader()
