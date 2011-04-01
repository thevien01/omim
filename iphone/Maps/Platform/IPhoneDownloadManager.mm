#include "../../platform/download_manager.hpp"

#import "IPhoneDownload.h"

#import <UIKit/UIApplication.h>

class IPhoneDownloadManager : public DownloadManager
{
	NSMutableArray * activeDownloads;

public:
	IPhoneDownloadManager()
  {
  	activeDownloads = [[NSMutableArray alloc] init];
  }

	virtual ~IPhoneDownloadManager()
  {
  	for (NSUInteger i = 0; i < [activeDownloads count]; ++i)
    	[[activeDownloads objectAtIndex:i] release];

    [activeDownloads removeAllObjects];
    [activeDownloads release];
  }

  virtual void DownloadFile(char const * url, char const * fileName,
  		TDownloadFinishedFunction finishFunc, TDownloadProgressFunction progressFunc, bool resume)
  {
		// check if download is already active
  	for (NSUInteger i = 0; i < [activeDownloads count]; ++i)
    {
    	IPhoneDownload * download = [activeDownloads objectAtIndex:i];
    	if ([download Url] == url)
      {
      	NSLog(@"Download is already active for url %s", url);
      	return;
      }
    }

  	IPhoneDownload * download = [[IPhoneDownload alloc] init];
    if ([download StartDownloadWithUrl:url
    							andFile:fileName
                  andFinishFunc:finishFunc
                  andProgressFunc:progressFunc
                  andUseResume:resume])
    {
    	// save download in array to cancel it later if necessary
    	[activeDownloads addObject:download];
      // prevent device from going to standby
      [UIApplication sharedApplication].idleTimerDisabled = YES;
    }
    else
    {
    	// free memory
      [download release];
    }
  }

  /// @note Doesn't notify clients on canceling!
  virtual void CancelDownload(char const * url)
  {
    // disable network activity indicator in top system toolbar
    // note that this method is called also from successful/failed download to "selfdestruct" below
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    for (NSUInteger i = 0; i < [activeDownloads count]; ++i)
    {
    	IPhoneDownload * download = [activeDownloads objectAtIndex:i];
    	if ([download Url] == url)
      {
      	[activeDownloads removeObjectAtIndex:i];
        [download Cancel];
        [download release];
      	break;
      }
    }
    // enable standby if no more downloads are left
    if ([activeDownloads count] == 0)
    	[UIApplication sharedApplication].idleTimerDisabled = NO;
  }

  virtual void CancelAllDownloads()
  {
    // disable network activity indicator in top system toolbar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

  	for (NSUInteger i = 0; i < [activeDownloads count]; ++i) {
    	IPhoneDownload * download = [activeDownloads objectAtIndex:i];
      [download Cancel];
      [download release];
    }
    [activeDownloads removeAllObjects];
  }
};

DownloadManager & GetDownloadManager()
{
  static IPhoneDownloadManager downloadManager;
  return downloadManager;
}
