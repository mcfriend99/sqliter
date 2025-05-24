import clib
import reflect

var Objc = clib.load('libobjc')
var Foundation = clib.load('/System/Library/Frameworks/Foundation.framework/Foundation')
var AppKit = clib.load('/System/Library/Frameworks/AppKit.framework/AppKit')

# Define the necessary Objective-C types and functions
var NSUInteger = clib.long_double
var NSInteger = clib.long
var CGFloat = clib.double
var NSString = clib.ptr
var NSURL = clib.ptr


var objc = {
  objc_getClass: Objc.define('objc_getClass', clib.ptr, clib.char_ptr),
  objc_msgSend: Objc.define('objc_msgSend', clib.ptr, clib.ptr, clib.ptr),
  objc_msgSend2: Objc.define('objc_msgSend', clib.ptr, clib.ptr, clib.ptr, clib.ptr),
  objc_msgSend3: Objc.define('objc_msgSend', clib.char_ptr, clib.ptr, clib.ptr),
  objc_msgSend4: Objc.define('objc_msgSend', clib.ptr, clib.ptr, clib.ptr, clib.long),
  objc_runModal: Objc.define('objc_msgSend', clib.long, clib.ptr, clib.ptr),
  objc_msgSend5: Objc.define('objc_msgSend', clib.long, clib.ptr, clib.ptr),
  sel_registerName: Objc.define('sel_registerName', clib.ptr, clib.char_ptr),
}

/**
 * Convert Python string to NSString.
 */
def nsstring_from_str(s) {
  var cfstr = s.to_bytes()
  var nsstr = objc.objc_msgSend(
    objc.objc_getClass('NSString'), 
    objc.sel_registerName('alloc')
  )
  nsstr = objc.objc_msgSend2(
    nsstr, 
    objc.sel_registerName('initWithUTF8String:'),
    cfstr
  )
  return nsstr
}

/**
 * Convert NSString to Python string.
 */
def nsstring_to_str(nsstr) {
  if !nsstr return ''
  return objc.objc_msgSend3(nsstr, objc.sel_registerName('UTF8String'))
}

/**
 * Create NSMutableArray for filtering the dialog
 */
def create_filter_list(filters) {
  var list = objc.objc_msgSend(
    objc.objc_getClass('NSMutableArray'), 
    objc.sel_registerName('alloc')
  )

  list = objc.objc_msgSend(
    list,
    objc.sel_registerName('init')
  )

  for filter in filters {
    objc.objc_msgSend2(
      list,
      objc.sel_registerName('addObject:'),
      nsstring_from_str(filter)
    )
  }

  return list
}

/**
 * Opens a file selection dialog on macOS using Objective-C (Cocoa).
 * 
 * Returns:
 *    str: The path to the selected file, or None if the user cancels.
 */
def file_open_dialog(filters) {
  catch {
    # Get the NSOpenPanel class
    var openPanelClass = objc.objc_getClass('NSOpenPanel')

    # Create an instance of NSOpenPanel
    var openPanel = objc.objc_msgSend(openPanelClass, objc.sel_registerName('openPanel'))

    # Configure the open panel
    objc.objc_msgSend4(openPanel, objc.sel_registerName('setCanChooseFiles:'), 1)
    objc.objc_msgSend4(openPanel, objc.sel_registerName('setCanChooseDirectories:'), 0)
    objc.objc_msgSend4(openPanel, objc.sel_registerName('setAllowsMultipleSelection:'), 0)
    objc.objc_msgSend2(openPanel, objc.sel_registerName('setAllowedFileTypes:'), create_filter_list(filters))

    # Run the open panel.  Use the correct function prototype.
    var result = objc.objc_runModal(openPanel, objc.sel_registerName('runModal'))

    # Check the result. This is now safe because result is an NSInteger.
    if result == 1 {  # NSModalResponseOK
      # Get the selected URLs (plural, even if we only allow one)
      var urls = objc.objc_msgSend(openPanel, objc.sel_registerName('URLs'))
      
      if urls {
        var count = objc.objc_msgSend5(urls, objc.sel_registerName('count'))
        
        if count > 0 {
          var firstURL = objc.objc_msgSend4(urls, objc.sel_registerName('objectAtIndex:'), 0)

          # Get the path from the URL.
          var path = objc.objc_msgSend(firstURL, objc.sel_registerName('path'))
          return nsstring_to_str(path)
        }
      }
    }

    return nil
  } as e

  if e {
    echo 'An error occurred: ${e.message} -> ${e.stacktrace}'
    return nil
  }
}
