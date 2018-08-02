/*
 Copyright (C) 2018 by Martin Hrubý <hrubymar10@gmail.com>
 Part of the Battle for Wesnoth Project https://www.wesnoth.org/
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY.
 
 See the COPYING file for more details.
 */

#ifdef __APPLE__

#include "apple_version.hpp"

#import "game_version.hpp"

#if defined(__APPLE__) && defined(__MACH__) && defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__)
#define __IPHONEOS__ (__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__*1000)
#endif

#if defined(__IPHONEOS__)
#include <sys/sysctl.h>
#include <Plist.hpp>
#else
#import <Foundation/Foundation.h>
#endif

namespace desktop {
	namespace apple {
		std::string os_version() {
#if defined(__IPHONEOS__)

			//
			// Standard iOS version
			//
			
			struct utsname systemInfo;
			uname(&systemInfo);
			
			std::string device_info = "";
			
			//TODO: Move this map to better place and add all devices
			std::map<std::string, std::string> devices {
				{ "x86_64", "iOS Simulator" },
				{ "iPad7,5", "iPad 2018" },
			};
			
			if ( devices.find(systemInfo.machine) == devices.end() ) {
				device_info += std::string(systemInfo.machine);
			} else {
				device_info += devices[systemInfo.machine];
			}
			
			device_info += ", ";
			
			static const std::string version_plist = "/System/Library/CoreServices/SystemVersion.plist";
			std::map<std::string, boost::any> systemVersion;
			
			if(filesystem::file_exists(version_plist)) {
				Plist::readPlist("/System/Library/CoreServices/SystemVersion.plist", systemVersion);
			}
			
			if ( systemVersion.find("ProductVersion") == systemVersion.end() ) {
				size_t size;
				sysctlbyname("kern.osrelease", nullptr, &size, nullptr, 0);
				
				auto *answer = static_cast<char *>(malloc(size));
				sysctlbyname("kern.osrelease", answer, &size, nullptr, 0);
				
				std::string result(answer);
				free(answer);
				
				device_info += "Darwin " + std::string(result);
			} else {
				device_info += "iOS " + std::string(boost::any_cast<std::string>(systemVersion["ProductVersion"]));
			}
			
			device_info += " (";
			
			if ( systemVersion.find("ProductBuildVersion") == systemVersion.end() ) {
				size_t size;
				sysctlbyname("kern.osversion", nullptr, &size, nullptr, 0);
				
				auto *answer = static_cast<char *>(malloc(size));
				sysctlbyname("kern.osversion", answer, &size, nullptr, 0);
				
				std::string result(answer);
				free(answer);
				
				device_info += std::string(result);
			} else {
				device_info += std::string(boost::any_cast<std::string>(systemVersion["ProductBuildVersion"]));
			}
			
			device_info += ")";
			
			return device_info;
#else

			//
			// Standard macOS version
			//

			std::string version_string = "Apple";
			NSArray *version_array = [[[NSProcessInfo processInfo] operatingSystemVersionString] componentsSeparatedByString:@" "];
			
			const version_info version_info([[version_array objectAtIndex:1] UTF8String]);
			
			if (version_info.major_version() == 10 && version_info.minor_version() < 12) {
				version_string += " OS X ";
			} else {
				version_string += " macOS ";
			}
			
			version_string += [[version_array objectAtIndex:1] UTF8String];
			version_string += " (";
			version_string += [[version_array objectAtIndex:3] UTF8String];
			
			return version_string;
#endif
		}
		
	} // end namespace apple
} // end namespace desktop

#endif //end __APPLE__
