# NaviGPT: A Real-Time AI-Driven Mobile Navigation System

[<img src="Logo-NaviGPT.png" height="160px" width="140px" />](https://github.com/PSU-IST-CIL/NaviGPT/tree/main)

<img src="https://img.shields.io/badge/Xcode-007ACC?style=for-the-badge&logo=Xcode&logoColor=white" height="20px" width="70px" />  ![](https://img.shields.io/badge/platform-iPhone_12_Pro_or_advanced_version_with_ios_17.0+-lightgrey.svg) ![](https://img.shields.io/badge/language-swift-orange.svg) [![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/PSU-IST-CIL/NaviGPT/LICENSE)

If this project helps or inspires you, please <img src="https://img.shields.io/gitea/stars/PSU-IST-CIL/NaviGPT" height="20px" width="155px" /> the repository and cite the relevant paper! The open source version will be released on date of Conference (GROUP '25).

#### Principal developers and maintainers of the repository: @[PSU-IST-CIL/NaviGPT](https://github.com/orgs/PSU-IST-CIL/teams/navigpt)
----
## Enhancing the Travel Experience for People with Visual Impairments through Multimodal Interaction: NaviGPT, A Real-Time AI-Driven Mobile Navigation System [![arXiv](https://img.shields.io/badge/arXiv-410.04005-b31b1b.svg)](https://arxiv.org/abs/2410.04005) [![HTML](https://img.shields.io/badge/HTML-b31b1b.svg)](https://arxiv.org/html/2410.04005v1)
### He Zhang<sup>α</sup>, Nicholas J. Falletta<sup>α</sup>, Jingyi Xie<sup>α</sup>, Rui Yu<sup>β</sup>, Sooyeon Lee<sup>γ</sup>, Syed Masum Billah<sup>α</sup>, John M. Carroll<sup>α</sup>
 <sup>α</sup> College of Information Sciences and Technology, Penn State University, University Park, Pennsylvania, USA
 
 <sup>β</sup> Department of Computer Science and Engineering, University of Louisville, Louisville, KY, USA
 
 <sup>γ</sup> Ying Wu College of Computing, New Jersey Institute of Technology, Newark, NJ, USA
 
![image](workflow-group.png)
<p align="center">Figure 1. Workflow of NaviGPT. The image illustrates the workflow of the NaviGPT system designed to assist people with visual impairments (PVI) in navigating their surroundings through a combination of LiDAR, vibration feedback, and AI-generated guidance. At the top, two mobile screens show the interface where users can input a destination using either text or speech. This activates the navigation system, which displays a walking route on a map. The central part of the image focuses on LiDAR detection, depicted as a yellow detection zone scanning the path in front of the user. The LiDAR detection identifies obstacles, shown as a post in the user’s path, marked with a yellow square on the phone screen. Below, a PVI user holds the phone and receives real-time feedback through vibration. The vibration frequency increases as the distance between the user and the obstacle decreases. This is represented on a spectrum, with blue indicating a far distance (slow vibration) and green indicating proximity (fast vibration). On the right, a pre-designed prompt engineering pipeline connects to an API (GPT-4), which processes the obstacle data and provides descriptive guidance through voiceover. This guidance informs the user of the obstacle and offers navigational suggestions, ensuring safe passage. The image emphasizes how NaviGPT integrates LiDAR, tactile feedback, and AI-generated responses to provide a real-time, user-friendly navigation experience for PVI.</p>

----
## Abstract/Introduction:
Assistive technologies for people with visual impairments (PVI) have made significant advancements, particularly with the integration of artificial intelligence (AI) and real-time sensor technologies. However, current solutions often require PVI to switch between multiple apps and tools for tasks like image recognition, navigation, and obstacle detection, which can hinder a seamless and efficient user experience. In this paper, we present NaviGPT, a high-fidelity prototype that integrates LiDAR-based obstacle detection, vibration feedback, and large language model (LLM) responses to provide a comprehensive and real-time navigation aid for PVI. Unlike existing applications such as Be My AI and Seeing AI, NaviGPT combines image recognition and contextual navigation guidance into a single system, offering continuous feedback on the user's surroundings without the need for app-switching. Meanwhile, NaviGPT compensates for the response delays of LLM by using location and sensor data, aiming to provide practical and efficient navigation support for PVI in dynamic environments.

### Citation
Please cite these papers in your publications if NaviGPT helps your research.
```
 @misc{zhang2024enhancingtravelexperiencepeople,
      title={Enhancing the Travel Experience for People with Visual Impairments through Multimodal Interaction: NaviGPT, A Real-Time AI-Driven Mobile Navigation System}, 
      author={He Zhang and Nicholas J. Falletta and Jingyi Xie and Rui Yu and Sooyeon Lee and Syed Masum Billah and John M. Carroll},
      year={2024},
      eprint={2410.04005},
      archivePrefix={arXiv},
      primaryClass={cs.HC},
      url={https://arxiv.org/abs/2410.04005}, 
}
```
