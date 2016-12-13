# Multi-Person-Pose-Estimation

Zhe Cao, Tomas Simon, Shih-En Wei, Yaser Sheikh, "[Realtime Multi-Person 2D Pose Estimation using Part Affinity Fields](https://arxiv.org/abs/1611.08050)".

This project is licensed under the terms of the GPL v3 license. By using the software, you are agreeing to the terms of the [license agreement](https://github.com/ZheC/Multi-Person-Pose-Estimation/blob/master/LICENSE).

Contact: Zhe Cao (zhecao@cmu.edu)

## Before Everything
- Watch some [videos](https://www.youtube.com/playlist?list=PLNh5A7HtLRcpsMfvyG0DED-Dr4zW5Lpcg).
- Install [Caffe](http://caffe.berkeleyvision.org/). 
- For single person pose estimation: please refer to [Convolutional Pose Machines](https://github.com/shihenw/convolutional-pose-machines-release)

## Testing

### Matlab
- Run `testing/get_model.sh` to retreive our latest MSCOCO model from our web server.
- change the caffepath in the config.m and run demo.m for an example usage.

## Citation
Please cite CPM in your publications if it helps your research:

    @article{cao2016realtime,
	  title={Realtime Multi-Person 2D Pose Estimation using Part Affinity Fields},
	  author={Cao, Zhe and Simon, Tomas and Wei, Shih-En and Sheikh, Yaser},
	  journal={arXiv preprint arXiv:1611.08050},
	  year={2016}
	}