// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Copyright (C) 2019  Dorus Gadella
// electronic mail address: th #dot# w #dot# j #dot# gadella #at# uva #dot# nl
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
// Version 1 Dorus Gadella 2015-2017
// Version 2 Dorus Gadella 06-06-2018 included image registration with BJUnwarp
// Version 3 Dorus Gadella 20-3-2019 included dialog
// Version 4 Dorus Gadella 14-5-2019 included maximum values and colony ID
// Version 5 Dorus Gadella 15-5-2019 included optional background image, fine or course registration and colony size limit
// Version 6 Dorus Gadella 27-5-2019 minor bug fixes and introduced multiple ratio image output for 3-channel data
// Version 7 Dorus Gadella 28-5-2019 enhanced colony separation anf thresholding
// Version 8 Dorus Gadella 29-5-2019 included ratio scale bars
// Version 8a Dorus Gadella 13-6-2019 registration red-->green and cyan--> green
// Version 8b Dorus Gadella 18-6-2019 thresholding on CFP image
// Version 8c Dorus Gadella 19-6-2019 option to choose threshold image & skip registration
// Version 9 Dorus Gadella 21-6-2019 option to process an entire directory. NB use a backround image with extension ".tif"
//Version 10 Dorus Gadella 2-7-2019 option to (de)select colony separation by adding find maxima 
//============================================

Dialog.create("Input dialog for poster-tube ratio conversion");

Dialog.addChoice("Work on current image or load from directory :",newArray("current image","load from directory", "work on entire directory"),"load from directory");
Dialog.addCheckbox("Do you want to subtract a recorded background image :",true);
Dialog.addChoice("Image to threshold : ",newArray("RFP","CFP","GFP"),"RFP" );
Dialog.addNumber("Threshold for analysis of colonies:",500);
Dialog.addNumber("Smooth input image (Gaussian radius pixels):",2);
Dialog.addNumber("Smallest object area to analyze (in pixels^2 ):",50);
Dialog.addNumber("Largest object area to analyze (in pixels^2 ):"1000);
Dialog.addCheckbox("Enhance colony separation with find maxima :",true);
Dialog.addCheckbox("Do image registration", true);
Dialog.addChoice("Reference image for registration : ",newArray("RFP","CFP","GFP"),"CFP" );
Dialog.addChoice("Coarse or fine image registration",newArray("Coarse","Fine"),"Coarse");
Dialog.addCheckbox("Create colonies ROI image", true);
Dialog.addCheckbox("Create output colored Ratio Image(s)", true);
Dialog.addNumber("Maximum Red/Cyan ratio in colored Ratio Image:",2.5);
Dialog.addNumber("Maximum Red/Green ratio in colored Ratio Image:",7);
Dialog.addNumber("Maximum Cyan/Green ratio in colored Ratio Image:",5);
Dialog.show();
openfromdir=Dialog.getChoice();
open_bg=Dialog.getCheckbox();
thres_nr=Dialog.getChoice();
thres_low=Dialog.getNumber();
smooth_size=Dialog.getNumber();
small_size=Dialog.getNumber();
large_size=Dialog.getNumber();
colony_max=Dialog.getCheckbox();
reg_yes=Dialog.getCheckbox();
reg_ref=Dialog.getChoice();
reg=Dialog.getChoice();
colonies=Dialog.getCheckbox();
color_output=Dialog.getCheckbox();
ihigh_rc=Dialog.getNumber();
ihigh_rg=Dialog.getNumber();
ihigh_cg=Dialog.getNumber();
suffix=".ics";

if (thres_nr=="RFP"){
	thres_no=1;
}else if (thres_nr=="CFP"){
		thres_no=2;
}else if(thres_nr=="GFP"){
		thres_no=3;
}
max_cells=2000;
highnumber=0;
totcells=0;
ch1=newArray(10000);
ch2=newArray(10000);
ch3=newArray(10000);
sch1=newArray(10000);
sch2=newArray(10000);
sch3=newArray(10000);
ar=newArray(10000);
min1=newArray(10000);
min2=newArray(10000);
min3=newArray(10000);
max1=newArray(10000);
max2=newArray(10000);
max3=newArray(10000);
r_rc=newArray(10000);
r_rg=newArray(10000);
r_cg=newArray(10000);


if (openfromdir=="Work on entire directory") {
//	open();
	waitForUser("Please select one image of a petridish with colonies in the desired directory");	");
	run("Bio-Formats (Windowless)");
	filedir = getDirectory("image"); 
	close();
	list2=getFileList(filedir);
	list=list2;
	nfiles=list.length;
	files=0;
	for (ifile=0;ifile<nfiles;ifile++) {
		test2=0;
		string=list[ifile];
		test2=endsWith(string, suffix);
		if (test2==1) {
			list[files]=list2[ifile];
			files=files+1;		
		}
	}
}

if (openfromdir=="load from directory") {
//	open();
	waitForUser("Please select an image of a petridish with colonies");	
	run("Bio-Formats (Windowless)");
	files=1;
	filedir = getDirectory("image"); filein=filedir+getTitle(); 
	fileint=filein;
	fname=getTitle;
	dotIndex = indexOf(filein, "."); 
           	filein = substring(filein, 0, dotIndex); 
	rename("input");
}

if (openfromdir=="current image") {
	files=1;
	filedir = getDirectory("image"); filein=filedir+getTitle(); 
	fileint=filein;
	fname=getTitle;
	dotIndex = indexOf(filein, "."); 
           	filein = substring(filein, 0, dotIndex); 
	rename("input");
}

if (open_bg==true){
	waitForUser("Please select an image of the corresponding background");
	open();
	namebg=getTitle();
	rename("background");
	run("32-bit");
}
open("flatfield.tif");
rename("flatfield");

for (ifile=0;ifile<files;ifile++) {
	if (files>1) {		
		run("Bio-Formats (Windowless)", "open=["+filedir+list[ifile]+"]");
		filein=filedir+getTitle();
		fileint=filein;
		fname=getTitle;
		dotIndex = indexOf(filein, "."); 
           	 	filein = substring(filein, 0, dotIndex); 
		rename("input");
	
	}
	if (open_bg==true){
		imageCalculator("Subtract create 32-bit stack", "input","background");
		rename("temp");
		selectWindow("input");
		close();
		selectWindow("temp");
		rename("input");
	}
	print("Start");
	name=filein;
	selectWindow("input");
	getDimensions(x,y,ch,z,nt);
	z=nSlices;
	platenum=ifile+1;
	run("Subtract Background...", "rolling=100 stack");
	run("Gaussian Blur...", "sigma="+smooth_size+" stack");
	selectWindow("flatfield");
	setSlice(1);
	run("Duplicate...", " ");
	rename("redmul");
	selectWindow("flatfield");
	setSlice(2);
	run("Duplicate...", " ");
	rename("cyanmul");
	if (z==3) {
		selectWindow("flatfield");
		setSlice(3);
		run("Duplicate...", " ");
		rename("greenmul");
	}
		
	selectWindow("input");
	setSlice(1);

	imageCalculator("Multiply create 32-bit", "input","redmul");
	selectWindow("Result of input");
	rename("rfp");
	setMinAndMax(0,65535);
	run("16-bit");
	selectWindow("input");
	setSlice(2);
	
	imageCalculator("Multiply create 32-bit", "input","cyanmul");
	selectWindow("Result of input");
	rename("cfp");
	
	setMinAndMax(0,65535);
	run("16-bit");

	if (z==3){
		selectWindow("input");
		setSlice(3);
		imageCalculator("Multiply create 32-bit", "input","greenmul");
		selectWindow("Result of input");
		rename("gfp");
		setMinAndMax(0,65535);
		run("16-bit");
	}

	selectWindow("input");
	close();
	selectWindow("cyanmul");
	close();
	selectWindow("redmul");
	close();
	if (z==3){
		selectWindow("greenmul");
		close();	
	}
	name2=name+"_corr";
	if(reg_yes==1){
//run("Images to Stack", "name=Stack title=[] use keep");
		if (reg_ref=="CFP"){
			im1="cfp";
			im2="rfp";
			im3="gfp";
		}else if (reg_ref=="RFP"){
			im1="rfp";
			im2="cfp";
			im3="gfp";
		}else if (reg_ref=="GFP"){
			im1="gfp";
			im2="cfp";
			im3="rfp";
		}

		if (reg=="Coarse"){
			run("bUnwarpJ", "source_image="+im1+" target_image="+im2+" registration=Accurate image_subsample_factor=0 initial_deformation=[Very Coarse] final_deformation=[Fine] divergence_weight=0 curl_weight=0 landmark_weight=0 image_weight=1 consistency_weight=10 stop_threshold=0.01");
		}else{
			run("bUnwarpJ", "source_image="+im1+" target_image="+im2+" registration=Accurate image_subsample_factor=0 initial_deformation=[Fine] final_deformation=[Very Fine] divergence_weight=0 curl_weight=0 landmark_weight=0 image_weight=1 consistency_weight=10 stop_threshold=0.01");
		}
		selectWindow("Registered Source Image");

		
		rename(name2);
		selectWindow("Registered Target Image");

		setSlice(1);
		run("Copy");
		selectWindow(name2);
		if (reg_ref=="CFP") sliceno=1;
		if (reg_ref=="RFP") sliceno=2;
		if (reg_ref=="GFP") sliceno=2;	
		setSlice(sliceno);
		run("Paste");

		selectWindow("Registered Target Image");
		close();
		if (z==3){
			if (reg=="Coarse"){
				run("bUnwarpJ", "source_image="+im1+" target_image="+im3+" registration=Accurate image_subsample_factor=0 initial_deformation=[Very Coarse] final_deformation=[Fine] divergence_weight=0 curl_weight=0 landmark_weight=0 image_weight=1 consistency_weight=10 stop_threshold=0.01");
			}else{
				run("bUnwarpJ", "source_image="+im1+" target_image="+im3+" registration=Accurate image_subsample_factor=0 initial_deformation=[Fine] final_deformation=[Very Fine] divergence_weight=0 curl_weight=0 landmark_weight=0 image_weight=1 consistency_weight=10 stop_threshold=0.01");
			}
			selectWindow("Registered Target Image");
			setSlice(1);
			run("Copy");
			selectWindow(name2);
			if (reg_ref=="CFP") sliceno=3;
			if (reg_ref=="RFP") sliceno=3;
			if (reg_ref=="GFP") sliceno=1;	
			setSlice(sliceno);	
			run("Paste");
			selectWindow(im1);
			run("Copy");
			selectWindow(name2);
			if (reg_ref=="CFP") sliceno=2;
			if (reg_ref=="RFP") sliceno=1;
			if (reg_ref=="GFP") sliceno=3;		
			setSlice(sliceno);
			run("Paste");
			selectWindow(im1);
			close();
			selectWindow("Registered Target Image");
			close();
			selectWindow("Registered Source Image");
			close();
		}else{
			selectWindow(name2);
			setSlice(3);
			run("Delete Slice");
		}
		selectWindow(im2);
		close();
		if (z==3){
			selectWindow(im3);
			close();
		}
	}else{
		selectWindow("rfp");
		rename(name2);
		run("Add Slice");
		setSlice(2);
		selectWindow("cfp");
		run("Copy");
		selectWindow(name2);
		run("Paste");	
		selectWindow("cfp");
		close();
		if (z==3){
			selectWindow("gfp");
			run("Copy");
			selectWindow(name2);
			run("Add Slice");
			setSlice(3);		
			run("Paste");	
			selectWindow("gfp");
			close();
		}	
	}
	selectWindow(name2);
	fileout=name2;
	saveAs("Tiff",fileout);
	rename(name2);
	setSlice(thres_no);
	run("Duplicate...", " ");
	rename("Thres_image");
	run("Duplicate...", " ");
	rename("Binary_image");


	setThreshold(thres_low, 3500);
	run("Convert to Mask", "method=Default background=Dark calculate");
	run("Divide...", "value=255");
	run("32-bit");
	rename("Binary");
	selectWindow("Thres_image");
	run("Duplicate...", " ");
	if (colony_max==true) {
		rename("maxima");
	//run("Mean...", "radius=1");	
		run("Find Maxima...", "noise=1 output=[Segmented Particles] exclude");
		rename("temp2");
		close("maxima");
		selectWindow("Thres_image");
		run("Duplicate...", " ");
		rename("temp");
		setThreshold(thres_low,3500);
		setThreshold(thres_low,3500);
		setThreshold(thres_low,3500);
		run("Convert to Mask", "method=Default background=Default");
		imageCalculator("AND create", "temp","temp2");
		rename("Temp3");
		close("temp");
		close("temp2");
	}else{
		rename("temp");
		setThreshold(thres_low,3500);
		setThreshold(thres_low,3500);
		setThreshold(thres_low,3500);
		run("Convert to Mask", "method=Default background=Default");
		rename("Temp3");
		close("temp");
	}
	selectWindow("Temp3");
	roiManager("reset"); 
	setAutoThreshold("Default");

	run("Set Measurements...", "area mean standard min redirect=None decimal=9");
	run("Analyze Particles...", "size="+small_size+"-"+large_size+" add");

	selectWindow(name2);
	roiManager("Show All");
	roiManager("Multi Measure");
	selectWindow("Thres_image");
	roiManager("Show All");
	selectWindow("Temp3");
	close();


	if (nResults >0){
		selectWindow("Results");
//The lines below takes the results out of the result image window. First it analyzes the number of columns (=cells) in the results window
		headings = split(String.getResultsHeadings);
		cellcount=lengthOf(headings)/5;
		if (cellcount>max_cells) cellcount=max_cells;
		max_c=0;
		max_r=0;
		max_g=0;
		max_rc=0;
		max_cg=0;
		max_rg=0;
		if (cellcount>0){
			init_inte=newArray(cellcount);
			totcells=totcells+cellcount;
//Below the initial intensity per well is copied
			x1=0;x2=0;xy=0;y1=0;y2=0;
			z1=0;z2=0;xz=0;yz=0;
			for (colony=0; colony<cellcount; colony++) {
				col=5*colony;
				area=getResult(headings[col],0);
			    	inten1=getResult(headings[col+1],0);
				std1=getResult(headings[col+2],0);
				minc1=getResult(headings[col+3],0);
				maxc1=getResult(headings[col+4],0);	
				inten2=getResult(headings[col+1],1);
				std2=getResult(headings[col+2],1);
				minc2=getResult(headings[col+3],1);
				maxc2=getResult(headings[col+4],1);	
	
			
				ch1[colony]=inten1;
				ch2[colony]=inten2;
				ar[colony]=area;
				sch1[colony]=std1;
				sch2[colony]=std2;
				min1[colony]=minc1;
				min2[colony]=minc2;
				max1[colony]=maxc1;
				max2[colony]=maxc2;
				rc=inten1/inten2;
				r_rc[colony]=rc;
			
	
				if (max_r<inten1) {
					max_r=inten1;
					col_r=colony+1;
				}
				if(max_c<inten2) {
					max_c=inten2;
					col_c=colony+1;
				}
				if(max_rc<rc) {
					max_rc=r_rc[colony];
					col_rc=colony+1;
				}
				if(z>2) {
					inten3=getResult(headings[col+1],2);
					std3=getResult(headings[col+2],2);
					minc3=getResult(headings[col+3],2);
					maxc3=getResult(headings[col+4],2);	

					if(max_g<inten3) {
						max_g=inten3;
						col_g=colony+1;
					}
					ch3[colony]=inten3;
					sch3[colony]=std3;
					min3[colony]=minc3;
					max3[colony]=maxc3;
					rg=inten1/inten3;
					cg=inten2/inten3;
					r_rg[colony]=rg;
					r_cg[colony]=cg;
					if(max_rg<rg) {
						max_rg=rg;
						col_rg=colony+1;
					}
					if(max_cg<cg) {
						max_cg=cg;
						col_cg=colony+1;
					}		

				}
			 }
		}	
		selectWindow("Results");
		run("Close");
	}
	selectWindow("Log");
//print("\\Clear");
	if (z==2){
		string="Colony #\tarea\tRFP\tstdevRFP\tminRFP\tmaxRFP\tCFP\tstdevCFP\tminCFP\tmaxCFP\tratioRFP/CFP\tPlate#";

	}else{
		string="Colony #\tarea\tRFP\tstdevRFP\tminRFP\tmaxRFP\tCFP\tstdevCFP\tminCFP\tmaxCFP\tGFP\tstdevGFP\tminGFP\tmaxGFP\tratioRFP/CFP\tratioRFP/GFP\tratioCFP/GFP\tPlate#";
	}
	print(string);
	for (i=0;i<cellcount;i++) {
		j=i+1;
		string="";
			if (z==2){
			string=string+j+"\t"+ar[i]+"\t"+ch1[i]+"\t"+sch1[i]+"\t"+min1[i]+"\t"+max1[i]+"\t"+ch2[i]+"\t"+sch2[i]+"\t"+min2[i]+"\t"+max2[i]+"\t"+r_rc[i]+"\t"+platenum;
		}else{
			string=string+j+"\t"+ar[i]+"\t"+ch1[i]+"\t"+sch1[i]+"\t"+min1[i]+"\t"+max1[i]+"\t"+ch2[i]+"\t"+sch2[i]+"\t"+min2[i]+"\t"+max2[i]+"\t"+ch3[i]+"\t"+sch3[i]+"\t"+min3[i]+"\t"+max3[i]+"\t"+r_rc[i]+"\t"+r_rg[i]+"\t"+r_cg[i]+"\t"+platenum;
		}
		print(string);
	}
	print("\n");
	string="MaxRFP\t"+max_r+"\tColony#\t"+col_r;
	print(string);
	string="MaxCFP\t"+max_c+"\tColony#\t"+col_c;
	print(string);
	if (z>2){
		string="MaxGFP\t"+max_g+"\tColony#\t"+col_g;
		print(string);
	}
	string="Max Red/Cyan ratio\t"+max_rc+"\tColony#\t"+col_rc;
	print(string);
	if (z>2){
		string="Max Red/Green ratio\t"+max_rg+"\tColony#\t"+col_rg;
		print(string);
		string="Max Cyan/Green ratio\t"+max_cg+"\tColony#\t"+col_cg;
		print(string);
	}
	print("\n");
	getDateAndTime(year,month,dw,dm,hr,mi,sec,msec);
	month=month+1;
	string="Date: "+dm+"-"+month+"-"+year;
	print(string);
	print(filein);
	print("Subtracted a recorded background image : ",open_bg);
	print("Image to threshold : ", thres_nr);
	print("Threshold for analysis of colonies: ",thres_low);
	print("Smooth input image (Gaussian radius): ",smooth_size);
	print("Smallest object area to analyze (in pixels^2 ): ",small_size);
	print("Largest object area to analyze (in pixels^2 ): ",large_size);
	print("Enhance colony separation with find maxima :",colony_max);
	print("Do image registration", reg_yes);
	print("Reference image for registration : ",reg_ref);
	print("Coarse or fine image registration: ",reg);
	print("Create colonies ROI image: ", colonies);
	print("Create output colored Ratio Image(s): ", color_output);
	print("Maximum Red/Cyan ratio in colored Ratio Image:",ihigh_rc);
	print("Maximum Red/Green ratio in colored Ratio Image:",ihigh_rg);
	print("Maximum Cyan/Green ratio in colored Ratio Image:",ihigh_cg);
	selectWindow("Log");
	fileout=filein+".csv";
	saveAs("Text",fileout);
	run("Close");

	if (colonies==true){
		selectWindow("Thres_image");
		fileout=filein+"_ROIs";
		saveAs("Tiff",fileout);
		rename("Thres_image");
	}


	selectWindow("ROI Manager");
	run("Close");

	if (color_output==true){
		selectWindow(name2);
		setSlice(1);
		run("Duplicate...", " ");
		rename("rfp");
		selectWindow(name2);
		setSlice(2);
		run("Duplicate...", " ");
		rename("cfp");
		
		imageCalculator("Divide create 32-bit", "rfp","cfp");
		rename("Ratio_rc");
		imageCalculator("Multiply 32-bit", "Ratio_rc","Binary");


		selectWindow("Ratio_rc");
		setMinAndMax(0, ihigh_rc);
		run("8-bit");	
		run("Fire");
	
		setFont("SansSerif" , 18);	
		newImage("rampje", "8-bit ramp", 150, 20, 1);
		run("Copy");
		close();
		selectWindow("Ratio_rc");	
		setColor(255);
		xx=x-200;
		yy=y-30;
		makeRectangle(xx, yy, 150, 20);
		run("Paste");
		drawRect(xx, yy, 150, 20);
		yy=yy-10;
		xx=x-205;
		drawString("0",xx,yy);
		xx=x-50;
		drawString(ihigh_rc,xx,yy);
		xx=x-160;
		drawString("RFP/CFP",xx,yy);
		run("Select All");




		name3=filein+"_ratio_rc";
		fileout=name3;
		saveAs("Tiff",fileout);
		close();
		if(z>2){
			selectWindow(name2);
			setSlice(3);
			run("Duplicate...", " ");
			rename("gfp");
			imageCalculator("Divide create 32-bit", "rfp","gfp");
			rename("Ratio_rg");
			imageCalculator("Multiply 32-bit", "Ratio_rg","Binary");
			selectWindow("Ratio_rg");
			setMinAndMax(0, ihigh_rg);
			run("8-bit");
			run("Fire");
			setFont("SansSerif" , 18);	
			newImage("rampje", "8-bit ramp", 150, 20, 1);
			run("Copy");
			close();
			selectWindow("Ratio_rg");
			setColor(255);
			xx=x-200;
			yy=y-30;
			makeRectangle(xx, yy, 150, 20);
			run("Paste");
			drawRect(xx, yy, 150, 20);
			yy=yy-10;
			xx=x-205;
			drawString("0",xx,yy);
			xx=x-50;
			drawString(ihigh_rg,xx,yy);
			xx=x-160;
			drawString("RFP/GFP",xx,yy);
			run("Select All");
			name3=filein+"_ratio_rg";
			fileout=name3;
			saveAs("Tiff",fileout);
			close();
			imageCalculator("Divide create 32-bit", "cfp","gfp");
			rename("Ratio_cg");
			imageCalculator("Multiply 32-bit", "Ratio_cg","Binary");
			selectWindow("Ratio_cg");
			setMinAndMax(0, ihigh_cg);
			run("8-bit");
			run("Fire");
			setFont("SansSerif" , 18);	
			newImage("rampje", "8-bit ramp", 150, 20, 1);
			run("Copy");
			close();
			selectWindow("Ratio_cg");
			setColor(255);
			xx=x-200;
			yy=y-30;
			makeRectangle(xx, yy, 150, 20);
			run("Paste");
			drawRect(xx, yy, 150, 20);
			yy=yy-10;
			xx=x-205;
			drawString("0",xx,yy);
			xx=x-50;
			drawString(ihigh_cg,xx,yy);
			xx=x-160;
			drawString("CFP/GFP",xx,yy);
			run("Select All");	
			name3=filein+"_ratio_cg";
			fileout=name3;
			saveAs("Tiff",fileout);
			close();
			selectWindow("gfp");
			close();

		}
		selectWindow("cfp");
		close();
		selectWindow("rfp");
		close();
	
	}
	selectWindow(name2);
	close();
	selectWindow("Binary");
	close();
	selectWindow("Thres_image");
	close();
}
if (open_bg==true){
	selectWindow("background");
	close();
}
selectWindow("flatfield");
close();





