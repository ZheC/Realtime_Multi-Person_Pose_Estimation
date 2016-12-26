# Multi-Person-Pose-Estimation

Code for winning 2016 MSCOCO Keypoints Challenge, ECCV Best Demo Award.

Zhe Cao, Tomas Simon, Shih-En Wei, Yaser Sheikh, "[Realtime Multi-Person 2D Pose Estimation using Part Affinity Fields](https://arxiv.org/abs/1611.08050)".

This project is licensed under the terms of the GPL v3 license. By using the software, you are agreeing to the terms of the [license agreement](https://github.com/ZheC/Multi-Person-Pose-Estimation/blob/master/LICENSE).

Contact: Zhe Cao (zhecao@cmu.edu)

![Teaser?](https://github.com/ZheC/Multi-Person-Pose-Estimation/blob/master/readme/pose.gif)

## Before Everything
- Watch our [video result](https://www.youtube.com/watch?v=pW6nZXeWlGM&t=77s) obtained from YouTube videos.
- Install [Caffe](http://caffe.berkeleyvision.org/). 
- For single person pose estimation: please refer to [Convolutional Pose Machines](https://github.com/shihenw/convolutional-pose-machines-release)

## Testing

### Matlab
- Run `cd testing; get_model.sh` to retreive our latest MSCOCO model from our web server.
- Change the caffepath in the `config.m` and run `demo.m` for an example usage.

### Python
- Code will be released soon!

### C++ (real-time version)
- Code will be released soon!

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
