# Realtime Multi-Person Pose Estimation
By [Zhe Cao](http://www.andrew.cmu.edu/user/zhecao), [Tomas Simon](http://www.cs.cmu.edu/~tsimon/), [Shih-En Wei](https://scholar.google.com/citations?user=sFQD3k4AAAAJ&hl=en), [Yaser Sheikh](http://www.cs.cmu.edu/~yaser/).

## Introduction
Code repo for winning 2016 MSCOCO Keypoints Challenge, ECCV Best Demo Award. 

Watch our [video result] (https://www.youtube.com/watch?v=pW6nZXeWlGM&t=77s) on funny Youtube videos. 

We present a bottom-up approach for multi-person pose estimation, without using any person detector. For more details, refer to our [Arxiv paper](https://arxiv.org/abs/1611.08050) and [presentation slides](http://image-net.org/challenges/talks/2016/Multi-person%20pose%20estimation-CMU.pdf) at ILSVRC and COCO workshop 2016.

<p align="left">
<img src="https://github.com/ZheC/Multi-Person-Pose-Estimation/blob/master/readme/pose.gif", width="720">
</p>

This project is licensed under the terms of the GPL v3 license [![License](https://img.shields.io/aur/license/yaourt.svg)](LICENSE).

Contact: [Zhe Cao](http://www.andrew.cmu.edu/user/zhecao)  Email: zhecao@cmu.edu

## Results

<p align="left">
<img src="https://github.com/ZheC/Multi-Person-Pose-Estimation/blob/master/readme/dance.gif", width="720">
</p>

<p align="left">
<img src="https://github.com/ZheC/Multi-Person-Pose-Estimation/blob/master/readme/shake.gif", width="720">
</p>

## Contents
1. [Testing](#testing)
2. [Training](#training)
3. [Citation](#citation)

## Testing

### C++ (realtime version)
- Use our modified caffe: [caffe_rtpose](https://github.com/CMU-Perceptual-Computing-Lab/caffe_demo/). Follow the instruction on that repo.
- Three input options: images, video, webcam

### Matlab (slower)
- Compatible with general [Caffe](http://caffe.berkeleyvision.org/). Compile matcaffe. 
- Run `cd testing; get_model.sh` to retreive our latest MSCOCO model from our web server.
- Change the caffepath in the `config.m` and run `demo.m` for an example usage.

### Python
- iPython Notebook documentation will be released soon!

## Training

- Network Architecture
![Teaser?](https://github.com/ZheC/Multi-Person-Pose-Estimation/blob/master/readme/arch.png)
- Use our modified caffe: [caffe_train](https://github.com/CMU-Perceptual-Computing-Lab/caffe_train). It will be merged with caffe_rtpose (for testing) soon. 

### Usage
- Run `cd training; python setLayers.py --exp 1` to generate the prototxt and shell file for training.
- Download our generated LMDB for the COCO dataset (189GB file): `get_lmdb.sh`
- Code for generating the LMDB file will be released soon!

## Related repository
CVPR'16, [Convolutional Pose Machines](https://github.com/shihenw/convolutional-pose-machines-release)

## Citation
Please cite the paper in your publications if it helps your research:

    
    
    @article{cao2016realtime,
	  title={Realtime Multi-Person 2D Pose Estimation using Part Affinity Fields},
	  author={Zhe Cao and Tomas Simon and Shih-En Wei and Yaser Sheikh},
	  journal={arXiv preprint arXiv:1611.08050},
	  year={2016}
	  }
	  
    @inproceedings{wei2016cpm,
      author = {Shih-En Wei and Varun Ramakrishna and Takeo Kanade and Yaser Sheikh},
      booktitle = {CVPR},
      title = {Convolutional pose machines},
      year = {2016}
      }
