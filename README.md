# MC-Ratio-Petri-dish
ImageJ macro for analyzing fluorescence ratios from a Petri dish with bacterial colonies

## Requirements
Runs on 2019 FIJI and ImageJ 
The macros were tested on MacOS Mojave (10.14.5) running:
ImageJ v1.52p with Java 1.8.0_101 (64-bit) and on Fiji Version 2.0.0-rc-69/1.52p.

The macros were tested also on Windows 10 (version 1803 for x64-based systems) running:
ImageJ v1.52p with Java 1.8.0_112 (64-bit) and on Fiji version 1.52p running with Java 1.8.0 172 (64-bit)

BioFormats v.6.1.1 or v 6.1.0 (https://www.openmicroscopy.org/bio-formats/) must be installed in ImageJ. In Fiji this is installed automatically.

For usage see main manuscript Secondary screen - Cellular brightness in mammalian cells.

## Usage
ImageJ & FIJI macro's can be dragged and droppped on the toolbar, which opens the editor from which the macros can be started.
Macros can also be loaded via Plugins->Macros menu, either use Edit or Run.

## Test data
Test can be downloaded from following zenodo repository : https://doi.org/10.5281/zenodo.3338150

[download test data](https://zenodo.org/record/3338150/files/Testdata_SupSoftw_2-3_Ratio_petridish.zip?download=1)

## Screenshot of input dialog for Macro_ratio_single10.ijm
<img src="https://github.com/molcyto/MC-Ratio-Petri-dish/blob/master/Screenshot%20Macro_ratio_single10.png" width="600">

## Explanation input dialog for Macro_ratio_single10.ijm
- Work on current image or load from directory: Here you can choose to either use the current image already displayed in ImageJ, you load a stored image, or you process an entire directort of ratio images from a petridish. In the macro it assumes an ".ics" image file extension to consider for input. This can be changed in the macro by changing the line that sets the definition of  the file extension (i.e. 'suffix=".ics";'). It assumes ratiometric files: stacks with two (RFP and CFP) or three channels (RFP, CFP and GFP).
- Do you want to subtract a recorded background image: if checked the macro will ask to load a recorded ratiometric background image (i.e. an image of a petridish without colonies). In case you analyze an entire directory, place this background image outside this directory.
- Image to threshold: You can choose the RFP or the CFP image to threshold the image for selecting colonies. 
- Threshold for analysis of colonies: this is the lower intensity threshold for selecting colonies in the analysis.
- Smooth input image (Gaussian radisu pixels): Here you can reduce noise (and blur) the input image prior to analysis.
- Smallest object area to analyze (pixels ^2): this determines the smallest area to be still considered as a colony in number of pixels to be analyzed. 
- Largest object area to analyze (pixels ^2): this determines the largest area to be still considered as a colony in number of pixels to be analyzed. 
- Enhance colony separation with find maxima: if selected it will use an image J segmentation tool to find local maxima to separate adjacent colonies.
- Do image registration: If selected the channels in the ratio image will be registered to each other with bUnwarpJ to correct for pixel shifts and differential image distortions with the filter cubes and lens used.
- Reference for image registration: Selects the reference channel (that will not be altered) for performing the image registration of the other channels. It is a dummy input in case the image registration (previous input) was not selected.
- Course or fine image registration: Selects the course or fine adjustments in the bUnwarpJ image registration routine. It is a dummy input in case the image registration was not selected. 
- Create colonies ROI image: if selected an output image is generated with all analyzed and numbered colony ROIs.
- Create output colored Ratio images(s): if selected a colored ratio image is generated.
- Maximum Red/Cyan, Red/Green, Cyan/Green ratop (3x): sets the minimal/maximal ratio for display in the colored ratio image(s). This contrast can be individually set for the three ratio images.

## Screenshot of input dialog for Macro_process_flatfield_v3.ijm
<img src="https://github.com/molcyto/MC-Ratio-96-wells/blob/master/Screenshot%20macro_process_flatfield3.png" width="600">

## Explanation input dialog for Macro_process_flatfield_v3.ijm
- Work on current image or load from directory: Here you can choose to either use the current image already displayed in ImageJ as flatfield image, or you load a stored image as flatfield image. This should be a ratiometric image from a spatially uniform object (such as a white piece of paper put on top of the poster tube).
- Background: Here you can choose the background correction for the flatfield image. You can select a stored background ratiometric image (i.e. a dark ratio image with the same uniform object imaged without excitation light), a fixed background value (e.g. the camera bias), or no background correction of the flatfield image.
- Threshold ratio for selecting boundary of flatfield image: This selects a threshold for flatfield correction if the detected fluorescence in the image of a homogeneous object is this factor lower than the maximal value detected in the respective channel. This will reject ratiometric analysis of colonies in areas of the image that suffer from strong vignetting artefacts.

The flatfield macro will produce a ratiometric floating point image with a correction value per pixel by which the ratiometric images of petridish will be multiplied to correct for vignetting and filter cube dependent intensity deviations.


## links
[Visualizing heterogeneity](http://thenode.biologists.com/visualizing-heterogeneity-of-imaging-data/research/)
