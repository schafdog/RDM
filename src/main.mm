

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "RDMAppDelegate.h"
#import "cmdline.h"


int main(int argc, char* argv[])
{
    if (argc > 1)
    {
        int ret;
        ret = cmdline_main(argc, argv);
        exit(ret);
    }
    
    fprintf(stdout, "Currently running GUI.  Use ^C or close from menu\n");
    
    NSApplication* app = [NSApplication sharedApplication];
    [app setDelegate: [RDMAppDelegate new]];
    //NSApplication* app = [SRApplication sharedApplication];
    [app performSelectorOnMainThread: @selector(run) withObject: nil waitUntilDone: YES];
}
