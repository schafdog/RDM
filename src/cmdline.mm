extern "C"
{
#import <getopt.h>
}


#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import <dlfcn.h>

#import "utils.h"
//#import "RDM-Swift.h"

void usage()
{
	fprintf(stderr, "Commandline options\n"
					"  --width    (-w)  Width\n"
					"  --height   (-h)  Height\n"
					"  --scale    (-s)  Scale (2.0 = Retina, default=current)\n"
					"  --bits     (-b)  Color depth (default=current)\n"
					"  --display  (-d)  Select display # (default=main)\n"
					"  --displays (-l)  List available displays\n"
					"  --modes    (-m)  List available modes\n");
}

int cmdline_main(int argc, char * const*argv)
{
	//exit(0);
	
 	{
		int width = 0;
		int height = 0;
		CGFloat scale = 0.0f;
		int bitRes = 0;
		int displayNo = 0;
		
		bool listDisplays = 0;
		bool listModes = 0;

		static struct option longopts[] = {
			{"width", required_argument, NULL, 'w'},
			{"height", required_argument, NULL, 'h'},
			{"scale", required_argument, NULL, 's'},
			{"bits", required_argument, NULL, 'b'},
			{"display", required_argument, NULL, 'd'},
			{"displays",no_argument, NULL, 'l'},
			{"modes", no_argument, NULL, 'm'},
			{NULL, 0, NULL, 0},
		};

		int ch;
		while ((ch = getopt_long(argc, argv, "w:h:s:b:d:lm", longopts, NULL)) != -1) {
			switch (ch) {
			case 'w':
				width = atoi(optarg);
				break;
			case 'h':
				height = atoi(optarg);
				break;
			case 's':
				scale = atof(optarg);
				break;
			case 'b':
				bitRes = atoi(optarg);
				break;
			case 'd':
				displayNo = atoi(optarg);
				break;
			case 'l':
				listDisplays = 1;
				break;
			case 'm':
				listModes = 1;
				break;
			default:
				usage();
				return -1;
			}
		}

		uint32_t nDisplays;
		CGDirectDisplayID displays[0x10];
		CGDirectDisplayID display;

		CGGetOnlineDisplayList(0x10, displays, &nDisplays);

		if(displayNo > nDisplays -1)
		{
			fprintf(stderr, "Error: display index %d exceeds display count %d\n", displayNo, nDisplays);
			exit(1);
		}
		display = displays[displayNo];

		if(listDisplays)
		{
			for(int i=0; i<nDisplays; i++)
			{
				int modeNum;
				CGSGetCurrentDisplayMode(displays[i], &modeNum);
				modes_D4 mode;
				CGSGetDisplayModeDescriptionOfLength(displays[i], modeNum, &mode, 0xD4);
				
				int mBitres = (mode.derived.depth == 4) ? 32 : 16;
				
				fprintf(stdout, "Display %d: {resolution=%dx%d, scale = %.1f, freq = %d, bits/pixel = %d}\n", i, mode.derived.width, mode.derived.height, mode.derived.density, mode.derived.freq, mBitres);
				
			}
			
			return 0;
		}

		if(listModes)
		{
			int nModes;
			modes_D4* modes;
			CopyAllDisplayModes(display, &modes, &nModes);
			
			for(int i=0; i<nModes; i++)
			{
				modes_D4 mode = modes[i];
				if(width && mode.derived.width != width)
					continue;
				if(height && mode.derived.height != height)
					continue;
				int mBitres = (mode.derived.depth == 4) ? 32 : 16;
				if(bitRes && mBitres != bitRes)
					continue;
				if(scale && mode.derived.density != scale)
					continue;
				
				fprintf(stdout, "mode: {resolution=%dx%d, scale = %.1f, freq = %d, bits/pixel = %d}\n", mode.derived.width, mode.derived.height, mode.derived.density, mode.derived.freq, mBitres);
				
			}
			
			free(modes);
			
			return 0;
			/*
			CFArrayRef modes = CGDisplayCopyAllDisplayModes(display, NULL);
		    for (int i = 0; i < CFArrayGetCount(modes); i++) {
		        CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(modes, i);
		        CFDictionaryRef infoDict = CGDisplayModeGetDictionary(mode);
				
		        CFNumberRef resolution = (CFNumberRef) CFDictionaryGetValue(infoDict, CFSTR("kCGDisplayResolution"));
		        CFNumberRef bits = (CFNumberRef) CFDictionaryGetValue(infoDict, CFSTR("BitsPerPixel"));
		        float modeScale = 1.0f;
		        int modeBitres;
		        if(resolution)
					CFNumberGetValue(resolution, kCFNumberFloatType, &modeScale);
		        CFNumberGetValue(bits, kCFNumberIntType, &modeBitres);
				
				int modeWidth = (int)CGDisplayModeGetWidth(mode);
				int modeHeight = (int)CGDisplayModeGetHeight(mode);
				
				//NSLog(@"%@", [mode description]);
				//NSLog(@"%@", [(NSDictionary*)infoDict description]);
				
				if(width && modeWidth != width)
					continue;
				if(height && modeHeight != height)
					continue;
				if(scale && modeScale != scale)
					continue;
				if(bitRes && modeBitres != bitRes)
					continue;
				
				
				
		        printf("mode: {resolution=%dx%d, scale = %.1f, bits/pixel = %d}\n", modeWidth,
		               modeHeight, modeScale, modeBitres);
		    }
		    CFRelease(modes);
			return 0;
			*/
		}

		{
			int modeNum;
			CGSGetCurrentDisplayMode(display, &modeNum);
			modes_D4 mode;
			CGSGetDisplayModeDescriptionOfLength(display, modeNum, &mode, 0xD4);
			
			if(!width && !height)
			{
				width = mode.derived.width;
				height = mode.derived.height;
			}
			if(!scale)
			{
				scale = mode.derived.density;
			}
			int mBitres = (mode.derived.depth == 4) ? 32 : 16;
			if(!bitRes)
			{
				bitRes = mBitres;
			}
		}
		
		
		{
			int nModes;
			modes_D4* modes;
			CopyAllDisplayModes(display, &modes, &nModes);
			
			int iMode = -1;
			
			for(int i=0; i<nModes; i++)
			{
				modes_D4 mode = modes[i];
				if(width && mode.derived.width != width)
					continue;
				if(height && mode.derived.height != height)
					continue;
				int mBitres = (mode.derived.depth == 4) ? 32 : 16;
				if(bitRes && mBitres != bitRes)
					continue;
				if(scale && mode.derived.density != scale)
					continue;
				
				iMode = i;
				break;
				//fprintf(stdout, "mode: {resolution=%dx%d, scale = %.1f, freq = %d, bits/pixel = %d}\n", mode.derived.width, mode.derived.height, mode.derived.density, mode.derived.freq, mode.derived.depth);
			}
			
			if(iMode != -1)
			{
				SetDisplayModeNum(display, iMode);
			}
			else
			{
				fprintf(stderr, "Error: could not select a new mode\n");
			}
			
			free(modes);
		}
		
		
    }
    return 0;
}
