# A small script to pull down the permissions requested by the top X number of paid or free apps ( change the URL )
# in the Google Play store.
# It does not use an API so will probably fail spectacularly when google update the play store.
# Currently working fine as of 12/7/2013

# Output is in comma seperated format:
# Application URL,Application name, permission

# == Version
#
# 1.0 Released
#
# == Usage
#
# No command line args as yet, change the uri string from _paid to _free to scrape a different list of apps
#
# Author :: Ian Williams (ian.williams@xiphosresearch.co.uk) (ian@fishermansenemy.com)
# Licence :: Creative Commons Attribution-Share Alike

require 'net/http'

# how many pages to scrape?
pages = 8
pagecount = 0

while pagecount < pages do
	uri = URI.parse("https://play.google.com/store/apps/collection/topselling_new_paid?start=#{pagecount*25}&num=24")
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE

	request = Net::HTTP::Get.new(uri.request_uri)

	response = http.request(request)

	# parse out the app ID's from the HTML body returned from the query
	apps = Hash.new

	# break the body up using > as the delimiter to get every element on a single line.
	response.body.each_line('>') do |line| 
		if line =~ /^*data-docid/ then
			# locate the docid in the line
			start = line.index("data-docid")
			finish = line.index("\">",start)
			appid = line[start+12..finish-1]
			# use the extracted docid to request the apps detail page from Google Play
			detailuri = URI.parse("https://play.google.com/store/apps/details?id=#{appid}")
			requestdetail = Net::HTTP::Get.new(detailuri.request_uri)

			appname = detailuri.to_s
			responsedetail = http.request(requestdetail)
			# break the body up using /div> as the delimiter
			responsedetail.body.each_line('/div>') do |detailline|
				# locate the friendly application name in the response
				if detailline =~ /^*doc-banner-title/ then
					titlestart = detailline.index("doc-banner-title\">")
					titleend = detailline.index("<",titlestart)

					appname << ","+detailline[titlestart+18..titleend-1].gsub(/,/,"&#44;")
				# locate the permission descriptions in the response
				elsif detailline =~ /^*doc-permission-description"/ then 
					permissionstart = detailline.index("doc-permission-description\">")
					permissionend = detailline.index("<",permissionstart)

					puts appname + String.new(","+detailline[permissionstart+28..permissionend-1])
				end
			end
	 	end
	 end
	pagecount += 1
end