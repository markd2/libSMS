## Building

* Most classes requires iOS 5+
* Most classes have been updated to use ARC
* Categories (and some views) are separated into a separate .a file so that they can be force loaded by the linker.
* The scheme named "Build" will produce a universal binary for use on an iOS device and in the simulator.

### Build Settings

Other Linker Flags:
	
	-force_load "$(SRCROOT)/<SUBFOLDER>/libSMSForceLoad.a"
	-lxml2

Header Search Paths:

	/usr/include/libxml2

## Some classes

### SMSColumnsView

A *UIScrollView* subclass for laying out columns of subviews.

![alt SMSColumnsView](/readme_images_/SMSColumnsView.png "Title")

### SMSDrawingView

A *UIView* subclass for drawing clipart. Can be added as a subview (with a clear background) to another view to annotate other content.

### SMSTagsView

A *UIView* subclass that lays out subviews (of varying widths) sequentially in rows.

### SMSTilesView

A *UIScrollView* subclass that manages tiles in a grid with a similar API to *UITableView*.

### SMSChatViewController

A copy of the iOS Messages user interface.

### SMSSplitViewController

A split view controller that allows for horizontal and vertical layouts as well as different sizing in portrait and landscape.

## License

Most libSMS files are licensed under the [Modified BSD License](http://en.wikipedia.org/wiki/BSD_license). See the header of each file for details.