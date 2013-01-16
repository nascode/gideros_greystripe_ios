require "greystripe"

print("Greystripe test")

-- LIST OF EVENTS --

greystripe:addEventListener(Event.BANNER_LOADED, function()
	print("BANNER_LOADED")
end)

greystripe:addEventListener(Event.BANNER_FAILED, function()
	print("BANNER_FAILED")
end)

greystripe:addEventListener(Event.BANNER_CLOSED, function()
	print("BANNER_CLOSED")
	greystripe:hideBanner()
	greystripe:showInterstitial()
end)

greystripe:addEventListener(Event.BANNER_CLICKED, function()
	print("BANNER_CLICKED")
end)

greystripe:addEventListener(Event.INTERSTITIAL_LOADED, function()
	print("INTERSTITIAL_LOADED")
end)

greystripe:addEventListener(Event.INTERSTITIAL_FAILED, function()
	print("INTERSTITIAL_FAILED")
end)

greystripe:addEventListener(Event.INTERSTITIAL_CLOSED, function()
	print("INTERSTITIAL_CLOSED")
end)

greystripe:addEventListener(Event.INTERSTITIAL_CLICKED, function()
	print("INTERSTITIAL_CLICKED")
end)

-- LIST OF API --

-- id configuration (default id used)
greystripe:configure("31d51c95-d79b-48c1-925e-ad328eb48c87")

-- show banner
greystripe:showBanner()

-- hide banner
--greystripe:hideBanner()

-- show interstitial
--greystripe:showInterstitial()
