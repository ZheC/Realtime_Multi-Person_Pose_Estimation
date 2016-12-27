# Multi-Person-Pose-Estimation

Code for winning 2016 MSCOCO Keypoints Challenge, ECCV Best Demo Award. Watch our [video result](https://www.youtube.com/watch?v=pW6nZXeWlGM&t=77s). 

Zhe Cao, Tomas Simon, Shih-En Wei, Yaser Sheikh, "[Realtime Multi-Person 2D Pose Estimation using Part Affinity Fields](https://arxiv.org/abs/1611.08050)".

This project is licensed under the terms of the GPL v3 license. By using the software, you are agreeing to the terms of the [license agreement](https://github.com/ZheC/Multi-Person-Pose-Estimation/blob/master/LICENSE).

Contact: Zhe Cao (zhecao@cmu.edu)

![Teaser?](https://github.com/ZheC/Multi-Person-Pose-Estimation/blob/master/readme/pose.gif)

## Set Up
- Install [Caffe](http://caffe.berkeleyvision.org/). Compile matcaffe, pycaffe.
- For single person pose estimation: please refer to [Convolutional Pose Machines](https://github.com/shihenw/convolutional-pose-machines-release)

## Testing

### C++ (real-time version)
- Refer to our [caffe_demo submodule](https://github.com/CMU-Perceptual-Computing-Lab/caffe_demo/).
- Three input options: images, video, webcam

### Matlab (slower)
- Run `cd testing; get_model.sh` to retreive our latest MSCOCO model from our web server.
- Change the caffepath in the `config.m` and run `demo.m` for an example usage.

### Python
- iPython Notebook documentation will be released soon!

## Training

- Network Architecture
![Teaser?](https://github.com/ZheC/Multi-Person-Pose-Estimation/blob/master/readme/arch.png)

- Code will be released soon!

## Citation
Please cite the paper in your publications if it helps your research:

    
    
    @article{cao2016realtime,
	  title={Realtime Multi-Person 2D Pose Estimation using Part Affinity Fields},
	  author={Cao, Zhe and Simon, Tomas and Wei, Shih-En and Sheikh, Yaser},
	  journal={arXiv preprint arXiv:1611.08050},
	  year={2016}
	  }
	  
    @inproceedings{wei2016cpm,
     author = {Shih-En Wei and Varun Ramakrishna and Takeo Kanade and Yaser Sheikh},
     booktitle = {CVPR},
     title = {Convolutional pose machines},
     year = {2016}
     }
