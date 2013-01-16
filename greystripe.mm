/*
 
 This code is MIT licensed, see http://www.opensource.org/licenses/mit-license.php
 (C) 2013 Nightspade
 
 */

#include "gideros.h"
#include "lua.h"
#include "lauxlib.h"
#import "GSAdDelegate.h"
#import "GSMobileBannerAdView.h"
#import "GSFullscreenAd.h"

// some Lua helper functions
#ifndef abs_index
#define abs_index(L, i) ((i) > 0 || (i) <= LUA_REGISTRYINDEX ? (i) : lua_gettop(L) + (i) + 1)
#endif

static void luaL_newweaktable(lua_State *L, const char *mode)
{
	lua_newtable(L);			// create table for instance list
	lua_pushstring(L, mode);
	lua_setfield(L, -2, "__mode");	  // set as weak-value table
	lua_pushvalue(L, -1);             // duplicate table
	lua_setmetatable(L, -2);          // set itself as metatable
}

static void luaL_rawgetptr(lua_State *L, int idx, void *ptr)
{
	idx = abs_index(L, idx);
	lua_pushlightuserdata(L, ptr);
	lua_rawget(L, idx);
}

static void luaL_rawsetptr(lua_State *L, int idx, void *ptr)
{
	idx = abs_index(L, idx);
	lua_pushlightuserdata(L, ptr);
	lua_insert(L, -2);
	lua_rawset(L, idx);
}

enum
{
	GGREYSTRIPE_BANNER_LOADED_EVENT,
	GGREYSTRIPE_BANNER_FAILED_EVENT,
	GGREYSTRIPE_BANNER_CLOSED_EVENT,
	GGREYSTRIPE_BANNER_CLICKED_EVENT,
	GGREYSTRIPE_INTERSTITIAL_LOADED_EVENT,
	GGREYSTRIPE_INTERSTITIAL_FAILED_EVENT,
	GGREYSTRIPE_INTERSTITIAL_CLOSED_EVENT,
	GGREYSTRIPE_INTERSTITIAL_CLICKED_EVENT,
};

static const char *TOP = "top";
static const char *BOTTOM = "bottom";

static const int kTOP = 0;
static const int kBOTTOM = 1;

static const char *BANNER_LOADED = "bannerLoaded";
static const char *BANNER_FAILED = "bannerFailed";
static const char *BANNER_CLOSED = "bannerClosed";
static const char *BANNER_CLICKED = "bannerClicked";
static const char *INTERSTITIAL_LOADED = "interstitialLoaded";
static const char *INTERSTITIAL_FAILED = "interstitialFailed";
static const char *INTERSTITIAL_CLOSED = "interstitialClosed";
static const char *INTERSTITIAL_CLICKED = "interstitialClicked";

static char keyWeak = ' ';

class Greystripe;

// delegate for banner
@interface GreystripeBannerDelegate : NSObject<GSAdDelegate>
{
}

- (id) initWithInstance:(Greystripe*)instance;

@property (nonatomic, assign) Greystripe *instance;

@end

// delegate for full screen ad
@interface GreystripeInterstitialDelegate : NSObject<GSAdDelegate>
{
}

- (id) initWithInstance:(Greystripe*)instance;

@property (nonatomic, assign) Greystripe *instance;

@end

class Greystripe : public GEventDispatcherProxy
{
public:
	Greystripe(lua_State *L) : L(L), view_(nil), interstitial_(nil), alignment_(kBOTTOM), guid_(nil)
	{
        delegateBanner_ = [[GreystripeBannerDelegate alloc] initWithInstance:this];
        delegateIn_ = [[GreystripeInterstitialDelegate alloc] initWithInstance:this];
    }
    
	~Greystripe()
	{
        [delegateBanner_ release];
        [delegateIn_ release];
        
        view_.delegate = nil;
        [view_ removeFromSuperview];
        [view_ release];
        
        interstitial_.delegate = nil;
        [interstitial_ release];
	}
    
	void configure(const char* adUnitId)
	{
        [guid_ release];
        guid_ = [[NSString stringWithUTF8String:adUnitId] retain];
	}
    
	void showBanner()
	{
        if (!view_){
            view_ = [[GSMobileBannerAdView alloc] initWithDelegate:delegateBanner_ GUID:guid_];
        }
        [view_ fetch];
	}
    
    void hideBanner()
	{
        [view_ removeFromSuperview];
        [view_ release];
        view_ = nil;
	}
    
    void displayBanner()
    {
        UIViewController *viewController = g_getRootViewController();
        [viewController.view addSubview:view_];
        updateFramePosition();
    }
    
	void showInterstitial()
	{
        [interstitial_ release];
        interstitial_ = [[GSFullscreenAd alloc] initWithDelegate:delegateIn_ GUID:guid_];
		[interstitial_ fetch];
	}
    
    void displayInterstitial()
    {
        [interstitial_ displayFromViewController:g_getRootViewController()];
    }
    
	const char* getAlignment()
	{
        if (alignment_ == kTOP) {
            return TOP;
        } else {
            return BOTTOM;
        }
	}
    
	void setAlignment(const char* alignment)
	{
        if (0 == strcmp(alignment, TOP)) {
            alignment_ = kTOP;
        } else if (0 == strcmp(alignment, BOTTOM)) {
            alignment_ = kBOTTOM;
        }
        
		if (view_.superview != nil)
			updateFramePosition();
	}
    
	void dispatchEvent(int type, void *event)
	{
		luaL_rawgetptr(L, LUA_REGISTRYINDEX, &keyWeak);
		luaL_rawgetptr(L, -1, this);
        
		if (lua_isnil(L, -1))
		{
			lua_pop(L, 2);
			return;
		}
        
		lua_getfield(L, -1, "dispatchEvent");
        
		lua_pushvalue(L, -2);
        
		lua_getglobal(L, "Event");
		lua_getfield(L, -1, "new");
		lua_remove(L, -2);
        
		switch (type)
		{
            case GGREYSTRIPE_BANNER_LOADED_EVENT:
                lua_pushstring(L, BANNER_LOADED);
                break;
            case GGREYSTRIPE_BANNER_FAILED_EVENT:
                lua_pushstring(L, BANNER_FAILED);
                break;
            case GGREYSTRIPE_BANNER_CLOSED_EVENT:
                lua_pushstring(L, BANNER_CLOSED);
                break;
            case GGREYSTRIPE_BANNER_CLICKED_EVENT:
                lua_pushstring(L, BANNER_CLICKED);
                break;
            case GGREYSTRIPE_INTERSTITIAL_LOADED_EVENT:
                lua_pushstring(L, INTERSTITIAL_LOADED);
                break;
            case GGREYSTRIPE_INTERSTITIAL_FAILED_EVENT:
                lua_pushstring(L, INTERSTITIAL_FAILED);
                break;
            case GGREYSTRIPE_INTERSTITIAL_CLOSED_EVENT:
                lua_pushstring(L, INTERSTITIAL_CLOSED);
                break;
            case GGREYSTRIPE_INTERSTITIAL_CLICKED_EVENT:
                lua_pushstring(L, INTERSTITIAL_CLICKED);
                break;
		}
        
		lua_call(L, 1, 1);
        
		lua_call(L, 2, 0);
        
		lua_pop(L, 2);
	}
    
    void updateFramePosition()
	{
		CGRect frame = view_.frame;
		if (alignment_ == kTOP)
		{
			frame.origin = CGPointMake(0, 0);
		}
		else
		{
			int height;
			CGRect screenRect = [[UIScreen mainScreen] bounds];
            CGSize adSize =  frame.size;
            
            if (UIInterfaceOrientationIsPortrait(g_getRootViewController().interfaceOrientation))
				height = screenRect.size.height;
			else
				height = screenRect.size.width;
            
            frame.origin = CGPointMake(0, height - adSize.height);
		}
		view_.frame = frame;
	}
    
private:
	lua_State *L;
    
    GreystripeBannerDelegate *delegateBanner_;
    GreystripeInterstitialDelegate *delegateIn_;
    GSMobileBannerAdView *view_;
    GSFullscreenAd *interstitial_;
    NSString *guid_;
    int alignment_;
};

@implementation GreystripeBannerDelegate

@synthesize instance = instance_;

- (id)initWithInstance:(Greystripe *)instance
{
	if (self = [super init])
	{
        instance_ = instance;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	}
	
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [super dealloc];
}

- (void)orientationDidChange:(NSNotification *)notification
{
    if (instance_)
        instance_->updateFramePosition();
}

- (UIViewController *)greystripeBannerDisplayViewController
{
    return g_getRootViewController();
}

- (void)greystripeAdFetchSucceeded:(id<GSAd>)a_ad
{
    if (instance_){
        instance_->dispatchEvent(GGREYSTRIPE_BANNER_LOADED_EVENT, NULL);
        instance_->displayBanner();
    }
}

- (void)greystripeAdFetchFailed:(id<GSAd>)a_ad withError:(GSAdError)a_error
{
    if (instance_)
        instance_->dispatchEvent(GGREYSTRIPE_BANNER_FAILED_EVENT, NULL);
}

- (void)greystripeAdClickedThrough:(id<GSAd>)a_ad
{
    if (instance_)
        instance_->dispatchEvent(GGREYSTRIPE_BANNER_CLICKED_EVENT, NULL);
}

- (void)greystripeDidDismissModalViewController
{
    if (instance_)
        instance_->dispatchEvent(GGREYSTRIPE_BANNER_CLOSED_EVENT, NULL);
}

@end

//////////////////////////////////////////////////////////////////////////////

@implementation GreystripeInterstitialDelegate

@synthesize instance = instance_;

- (id)initWithInstance:(Greystripe *)instance
{
	if (self = [super init])
	{
        instance_ = instance;
	}
	
	return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)greystripeAdFetchSucceeded:(id<GSAd>)a_ad
{
    if (instance_){
        instance_->dispatchEvent(GGREYSTRIPE_INTERSTITIAL_LOADED_EVENT, NULL);
        instance_->displayInterstitial();
    }
}

- (void)greystripeAdFetchFailed:(id<GSAd>)a_ad withError:(GSAdError)a_error
{
    if (instance_)
        instance_->dispatchEvent(GGREYSTRIPE_INTERSTITIAL_FAILED_EVENT, NULL);
}

- (void)greystripeAdClickedThrough:(id<GSAd>)a_ad
{
    if (instance_)
        instance_->dispatchEvent(GGREYSTRIPE_INTERSTITIAL_CLICKED_EVENT, NULL);
}

- (void)greystripeDidDismissModalViewController;
{
    if (instance_)
        instance_->dispatchEvent(GGREYSTRIPE_INTERSTITIAL_CLOSED_EVENT, NULL);
}

@end

static int destruct(lua_State* L)
{
	void *ptr =*(void**)lua_touserdata(L, 1);
	GReferenced* object = static_cast<GReferenced*>(ptr);
	Greystripe *greystripe = static_cast<Greystripe*>(object->proxy());
    
	greystripe->unref();
    
	return 0;
}

static Greystripe *getInstance(lua_State *L, int index)
{
	GReferenced *object = static_cast<GReferenced*>(g_getInstance(L, "MoPub", index));
	Greystripe *greystripe = static_cast<Greystripe*>(object->proxy());
    
	return greystripe;
}

static int configure(lua_State *L)
{
	Greystripe *greystripe = getInstance(L, 1);
    
	const char *appId = lua_tostring(L, 2);
    
	greystripe->configure(appId);
    
	return 0;
}

static int showBanner(lua_State *L)
{
	Greystripe *greystripe = getInstance(L, 1);
    
	greystripe->showBanner();
    
	return 0;
}

static int hideBanner(lua_State *L)
{
	Greystripe *greystripe = getInstance(L, 1);
    
	greystripe->hideBanner();
    
	return 0;
}

static int showInterstitial(lua_State *L)
{
	Greystripe *greystripe = getInstance(L, 1);
    
	greystripe->showInterstitial();
    
	return 0;
}

static int loader(lua_State *L)
{
	const luaL_Reg functionList[] = {
		{"configure", configure},
		{"showBanner", showBanner},
		{"hideBanner", hideBanner},
		{"showInterstitial", showInterstitial},
		{NULL, NULL}
	};
    
    g_createClass(L, "Greystripe", "EventDispatcher", NULL, destruct, functionList);
    
    // create a weak table in LUA_REGISTRYINDEX that can be accessed with the address of keyWeak
	luaL_newweaktable(L, "v");
	luaL_rawsetptr(L, LUA_REGISTRYINDEX, &keyWeak);
    
	lua_getglobal(L, "Greystripe");
	lua_pushstring(L, "top");
	lua_setfield(L, -2, "ALIGN_TOP");
	lua_pushstring(L, "bottom");
	lua_setfield(L, -2, "ALIGN_BOTTOM");
	lua_pop(L, 1);
    
    lua_getglobal(L, "Event");
	lua_pushstring(L, BANNER_LOADED);
	lua_setfield(L, -2, "BANNER_LOADED");
	lua_pushstring(L, BANNER_FAILED);
	lua_setfield(L, -2, "BANNER_FAILED");
	lua_pushstring(L, BANNER_CLOSED);
	lua_setfield(L, -2, "BANNER_CLOSED");
	lua_pushstring(L, BANNER_CLICKED);
	lua_setfield(L, -2, "BANNER_CLICKED");
	lua_pushstring(L, INTERSTITIAL_LOADED);
	lua_setfield(L, -2, "INTERSTITIAL_LOADED");
	lua_pushstring(L, INTERSTITIAL_FAILED);
	lua_setfield(L, -2, "INTERSTITIAL_FAILED");
	lua_pushstring(L, INTERSTITIAL_CLOSED);
	lua_setfield(L, -2, "INTERSTITIAL_CLOSED");
	lua_pushstring(L, INTERSTITIAL_CLICKED);
	lua_setfield(L, -2, "INTERSTITIAL_CLICKED");
	lua_pop(L, 1);
    
	Greystripe *mopub = new Greystripe(L);
	g_pushInstance(L, "Greystripe", mopub->object());
    
	luaL_rawgetptr(L, LUA_REGISTRYINDEX, &keyWeak);
	lua_pushvalue(L, -2);
	luaL_rawsetptr(L, -2, mopub);
	lua_pop(L, 1);
    
	lua_pushvalue(L, -1);
	lua_setglobal(L, "greystripe");
    
    return 1;
}

static void g_initializePlugin(lua_State *L)
{
    lua_getglobal(L, "package");
	lua_getfield(L, -1, "preload");
    
	lua_pushcfunction(L, loader);
	lua_setfield(L, -2, "greystripe");
    
	lua_pop(L, 2);
}

static void g_deinitializePlugin(lua_State *L)
{
    
}

REGISTER_PLUGIN("Greystripe", "2013.01")
