/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSystemAccessCommands.h"

#import <XCTest/XCUIDevice.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <mach/mach.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <net/if.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <AVFoundation/AVFoundation.h>
#import <Contacts/Contacts.h>
#import <Photos/Photos.h>
#import <EventKit/EventKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import <UserNotifications/UserNotifications.h>

#import "FBResponsePayload.h"
#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "XCUIDevice+FBHelpers.h"

static CMMotionManager *_motionManager = nil;

@implementation FBSystemAccessCommands

+ (NSArray *)routes
{
  return
  @[
    // System Info
    [[FBRoute GET:@"/wda/system/info"].withoutSession respondWithTarget:self action:@selector(handleGetSystemInfo:)],
    [[FBRoute GET:@"/wda/system/info"] respondWithTarget:self action:@selector(handleGetSystemInfo:)],

    // Disk Space
    [[FBRoute GET:@"/wda/system/disk"].withoutSession respondWithTarget:self action:@selector(handleGetDiskSpace:)],
    [[FBRoute GET:@"/wda/system/disk"] respondWithTarget:self action:@selector(handleGetDiskSpace:)],

    // Memory Info
    [[FBRoute GET:@"/wda/system/memory"].withoutSession respondWithTarget:self action:@selector(handleGetMemoryInfo:)],
    [[FBRoute GET:@"/wda/system/memory"] respondWithTarget:self action:@selector(handleGetMemoryInfo:)],

    // CPU Info
    [[FBRoute GET:@"/wda/system/cpu"].withoutSession respondWithTarget:self action:@selector(handleGetCPUInfo:)],
    [[FBRoute GET:@"/wda/system/cpu"] respondWithTarget:self action:@selector(handleGetCPUInfo:)],

    // Network Info
    [[FBRoute GET:@"/wda/system/network"].withoutSession respondWithTarget:self action:@selector(handleGetNetworkInfo:)],
    [[FBRoute GET:@"/wda/system/network"] respondWithTarget:self action:@selector(handleGetNetworkInfo:)],

    // WiFi Info
    [[FBRoute GET:@"/wda/system/wifi"].withoutSession respondWithTarget:self action:@selector(handleGetWiFiInfo:)],
    [[FBRoute GET:@"/wda/system/wifi"] respondWithTarget:self action:@selector(handleGetWiFiInfo:)],

    // Cellular Info
    [[FBRoute GET:@"/wda/system/cellular"].withoutSession respondWithTarget:self action:@selector(handleGetCellularInfo:)],
    [[FBRoute GET:@"/wda/system/cellular"] respondWithTarget:self action:@selector(handleGetCellularInfo:)],

#if !TARGET_OS_TV
    // Contacts
    [[FBRoute GET:@"/wda/system/contacts"].withoutSession respondWithTarget:self action:@selector(handleGetContacts:)],
    [[FBRoute GET:@"/wda/system/contacts"] respondWithTarget:self action:@selector(handleGetContacts:)],

    // Calendar Events
    [[FBRoute GET:@"/wda/system/calendar"].withoutSession respondWithTarget:self action:@selector(handleGetCalendarEvents:)],
    [[FBRoute GET:@"/wda/system/calendar"] respondWithTarget:self action:@selector(handleGetCalendarEvents:)],

    // Reminders
    [[FBRoute GET:@"/wda/system/reminders"].withoutSession respondWithTarget:self action:@selector(handleGetReminders:)],
    [[FBRoute GET:@"/wda/system/reminders"] respondWithTarget:self action:@selector(handleGetReminders:)],

    // Photos
    [[FBRoute GET:@"/wda/system/photos/count"].withoutSession respondWithTarget:self action:@selector(handleGetPhotosCount:)],
    [[FBRoute GET:@"/wda/system/photos/count"] respondWithTarget:self action:@selector(handleGetPhotosCount:)],

    // Motion/Sensor Data
    [[FBRoute GET:@"/wda/system/motion"].withoutSession respondWithTarget:self action:@selector(handleGetMotionData:)],
    [[FBRoute GET:@"/wda/system/motion"] respondWithTarget:self action:@selector(handleGetMotionData:)],
    [[FBRoute POST:@"/wda/system/motion/start"].withoutSession respondWithTarget:self action:@selector(handleStartMotionUpdates:)],
    [[FBRoute POST:@"/wda/system/motion/stop"].withoutSession respondWithTarget:self action:@selector(handleStopMotionUpdates:)],

    // Brightness
    [[FBRoute GET:@"/wda/system/brightness"].withoutSession respondWithTarget:self action:@selector(handleGetBrightness:)],
    [[FBRoute GET:@"/wda/system/brightness"] respondWithTarget:self action:@selector(handleGetBrightness:)],
    [[FBRoute POST:@"/wda/system/brightness"].withoutSession respondWithTarget:self action:@selector(handleSetBrightness:)],
    [[FBRoute POST:@"/wda/system/brightness"] respondWithTarget:self action:@selector(handleSetBrightness:)],

    // Volume
    [[FBRoute GET:@"/wda/system/volume"].withoutSession respondWithTarget:self action:@selector(handleGetVolume:)],
    [[FBRoute GET:@"/wda/system/volume"] respondWithTarget:self action:@selector(handleGetVolume:)],

    // Notification Permissions Status
    [[FBRoute GET:@"/wda/system/notifications/status"].withoutSession respondWithTarget:self action:@selector(handleGetNotificationStatus:)],
    [[FBRoute GET:@"/wda/system/notifications/status"] respondWithTarget:self action:@selector(handleGetNotificationStatus:)],

    // Bluetooth Status
    [[FBRoute GET:@"/wda/system/bluetooth"].withoutSession respondWithTarget:self action:@selector(handleGetBluetoothStatus:)],
    [[FBRoute GET:@"/wda/system/bluetooth"] respondWithTarget:self action:@selector(handleGetBluetoothStatus:)],
#endif

    // Installed Apps
    [[FBRoute GET:@"/wda/system/apps"].withoutSession respondWithTarget:self action:@selector(handleGetInstalledApps:)],
    [[FBRoute GET:@"/wda/system/apps"] respondWithTarget:self action:@selector(handleGetInstalledApps:)],

    // Process Info
    [[FBRoute GET:@"/wda/system/process"].withoutSession respondWithTarget:self action:@selector(handleGetProcessInfo:)],
    [[FBRoute GET:@"/wda/system/process"] respondWithTarget:self action:@selector(handleGetProcessInfo:)],

    // Permissions Status
    [[FBRoute GET:@"/wda/system/permissions"].withoutSession respondWithTarget:self action:@selector(handleGetPermissionsStatus:)],
    [[FBRoute GET:@"/wda/system/permissions"] respondWithTarget:self action:@selector(handleGetPermissionsStatus:)],

    // Open Settings
    [[FBRoute POST:@"/wda/system/openSettings"].withoutSession respondWithTarget:self action:@selector(handleOpenSettings:)],
    [[FBRoute POST:@"/wda/system/openSettings"] respondWithTarget:self action:@selector(handleOpenSettings:)],

    // Clipboard (enhanced)
    [[FBRoute GET:@"/wda/system/clipboard"].withoutSession respondWithTarget:self action:@selector(handleGetClipboard:)],
    [[FBRoute GET:@"/wda/system/clipboard"] respondWithTarget:self action:@selector(handleGetClipboard:)],
  ];
}

#pragma mark - System Info

+ (id<FBResponsePayload>)handleGetSystemInfo:(FBRouteRequest *)request
{
  struct utsname systemInfo;
  uname(&systemInfo);

  UIDevice *device = [UIDevice currentDevice];
  NSProcessInfo *processInfo = [NSProcessInfo processInfo];

  NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:@{
    @"systemName": device.systemName ?: @"unknown",
    @"systemVersion": device.systemVersion ?: @"unknown",
    @"deviceName": device.name ?: @"unknown",
    @"deviceModel": device.model ?: @"unknown",
    @"localizedModel": device.localizedModel ?: @"unknown",
    @"machine": [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding] ?: @"unknown",
    @"nodeName": [NSString stringWithCString:systemInfo.nodename encoding:NSUTF8StringEncoding] ?: @"unknown",
    @"uuid": device.identifierForVendor.UUIDString ?: @"unknown",
    @"processorCount": @(processInfo.processorCount),
    @"activeProcessorCount": @(processInfo.activeProcessorCount),
    @"physicalMemory": @(processInfo.physicalMemory),
    @"osVersion": processInfo.operatingSystemVersionString ?: @"unknown",
    @"thermalState": @(processInfo.thermalState),
    @"isLowPowerModeEnabled": @(processInfo.isLowPowerModeEnabled),
    @"uptime": @(processInfo.systemUptime),
#if TARGET_OS_SIMULATOR
    @"isSimulator": @(YES),
#else
    @"isSimulator": @(NO),
#endif
  }];

  if ([device isBatteryMonitoringEnabled] || YES) {
    [device setBatteryMonitoringEnabled:YES];
    info[@"batteryLevel"] = @(device.batteryLevel);
    info[@"batteryState"] = @(device.batteryState);
  }

  info[@"userInterfaceIdiom"] = @(device.userInterfaceIdiom);

  return FBResponseWithObject(info);
}

#pragma mark - Disk Space

+ (id<FBResponsePayload>)handleGetDiskSpace:(FBRouteRequest *)request
{
  NSError *error;
  NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory()
                                                                                error:&error];
  if (!attrs) {
    return FBResponseWithUnknownError(error);
  }

  unsigned long long totalSpace = [attrs[NSFileSystemSize] unsignedLongLongValue];
  unsigned long long freeSpace = [attrs[NSFileSystemFreeSize] unsignedLongLongValue];
  unsigned long long usedSpace = totalSpace - freeSpace;

  return FBResponseWithObject(@{
    @"totalSpace": @(totalSpace),
    @"freeSpace": @(freeSpace),
    @"usedSpace": @(usedSpace),
    @"totalSpaceGB": @(totalSpace / (1024.0 * 1024.0 * 1024.0)),
    @"freeSpaceGB": @(freeSpace / (1024.0 * 1024.0 * 1024.0)),
    @"usedSpaceGB": @(usedSpace / (1024.0 * 1024.0 * 1024.0)),
  });
}

#pragma mark - Memory Info

+ (id<FBResponsePayload>)handleGetMemoryInfo:(FBRouteRequest *)request
{
  vm_statistics64_data_t vmStats;
  mach_msg_type_number_t infoCount = HOST_VM_INFO64_COUNT;
  kern_return_t kernReturn = host_statistics64(mach_host_self(),
                                                HOST_VM_INFO64,
                                                (host_info64_t)&vmStats,
                                                &infoCount);
  if (kernReturn != KERN_SUCCESS) {
    return FBResponseWithUnknownErrorFormat(@"Failed to get memory info: %d", kernReturn);
  }

  vm_size_t pageSize;
  host_page_size(mach_host_self(), &pageSize);

  unsigned long long freeMemory = (unsigned long long)vmStats.free_count * pageSize;
  unsigned long long activeMemory = (unsigned long long)vmStats.active_count * pageSize;
  unsigned long long inactiveMemory = (unsigned long long)vmStats.inactive_count * pageSize;
  unsigned long long wiredMemory = (unsigned long long)vmStats.wire_count * pageSize;
  unsigned long long compressedMemory = (unsigned long long)vmStats.compressor_page_count * pageSize;
  unsigned long long totalMemory = [NSProcessInfo processInfo].physicalMemory;

  return FBResponseWithObject(@{
    @"totalMemory": @(totalMemory),
    @"freeMemory": @(freeMemory),
    @"activeMemory": @(activeMemory),
    @"inactiveMemory": @(inactiveMemory),
    @"wiredMemory": @(wiredMemory),
    @"compressedMemory": @(compressedMemory),
    @"totalMemoryMB": @(totalMemory / (1024.0 * 1024.0)),
    @"freeMemoryMB": @(freeMemory / (1024.0 * 1024.0)),
    @"usedMemoryMB": @((totalMemory - freeMemory) / (1024.0 * 1024.0)),
  });
}

#pragma mark - CPU Info

+ (id<FBResponsePayload>)handleGetCPUInfo:(FBRouteRequest *)request
{
  NSProcessInfo *processInfo = [NSProcessInfo processInfo];

  processor_info_array_t cpuInfo;
  mach_msg_type_number_t numCpuInfo;
  natural_t numCPUs = 0;
  kern_return_t kr = host_processor_info(mach_host_self(),
                                          PROCESSOR_CPU_LOAD_INFO,
                                          &numCPUs,
                                          &cpuInfo,
                                          &numCpuInfo);

  NSMutableArray *cpuUsagePerCore = [NSMutableArray array];
  if (kr == KERN_SUCCESS) {
    for (natural_t i = 0; i < numCPUs; i++) {
      float inUse = cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] +
                    cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] +
                    cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE];
      float total = inUse + cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
      float usage = total > 0 ? (inUse / total) * 100.0f : 0.0f;
      [cpuUsagePerCore addObject:@{
        @"core": @(i),
        @"usage": @(usage),
      }];
    }
    vm_deallocate(mach_task_self(), (vm_address_t)cpuInfo, sizeof(integer_t) * numCpuInfo);
  }

  return FBResponseWithObject(@{
    @"processorCount": @(processInfo.processorCount),
    @"activeProcessorCount": @(processInfo.activeProcessorCount),
    @"cpuUsagePerCore": cpuUsagePerCore,
  });
}

#pragma mark - Network Info

+ (id<FBResponsePayload>)handleGetNetworkInfo:(FBRouteRequest *)request
{
  NSMutableArray *interfaces = [NSMutableArray array];
  struct ifaddrs *ifaddrs = NULL;

  if (getifaddrs(&ifaddrs) == 0) {
    struct ifaddrs *addr = ifaddrs;
    while (addr != NULL) {
      if (addr->ifa_addr != NULL) {
        NSString *name = [NSString stringWithUTF8String:addr->ifa_name];
        NSString *address = @"";
        NSString *family = @"unknown";

        if (addr->ifa_addr->sa_family == AF_INET) {
          char buf[INET_ADDRSTRLEN];
          inet_ntop(AF_INET, &((struct sockaddr_in *)addr->ifa_addr)->sin_addr, buf, sizeof(buf));
          address = [NSString stringWithUTF8String:buf];
          family = @"IPv4";
        } else if (addr->ifa_addr->sa_family == AF_INET6) {
          char buf[INET6_ADDRSTRLEN];
          inet_ntop(AF_INET6, &((struct sockaddr_in6 *)addr->ifa_addr)->sin6_addr, buf, sizeof(buf));
          address = [NSString stringWithUTF8String:buf];
          family = @"IPv6";
        }

        BOOL isUp = (addr->ifa_flags & IFF_UP) != 0;
        BOOL isRunning = (addr->ifa_flags & IFF_RUNNING) != 0;

        if (address.length > 0) {
          [interfaces addObject:@{
            @"name": name,
            @"address": address,
            @"family": family,
            @"isUp": @(isUp),
            @"isRunning": @(isRunning),
          }];
        }
      }
      addr = addr->ifa_next;
    }
    freeifaddrs(ifaddrs);
  }

  NSString *wifiIP = [XCUIDevice.sharedDevice fb_wifiIPAddress];

  return FBResponseWithObject(@{
    @"interfaces": interfaces,
    @"wifiIPAddress": wifiIP ?: NSNull.null,
  });
}

#pragma mark - WiFi Info

+ (id<FBResponsePayload>)handleGetWiFiInfo:(FBRouteRequest *)request
{
  NSMutableDictionary *wifiInfo = [NSMutableDictionary dictionary];
  wifiInfo[@"ipAddress"] = [XCUIDevice.sharedDevice fb_wifiIPAddress] ?: NSNull.null;

#if !TARGET_OS_TV
  NSArray *interfaces = (__bridge_transfer NSArray *)CNCopySupportedInterfaces();
  if (interfaces) {
    for (NSString *interfaceName in interfaces) {
      NSDictionary *networkInfo = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)interfaceName);
      if (networkInfo) {
        wifiInfo[@"ssid"] = networkInfo[(__bridge NSString *)kCNNetworkInfoKeySSID] ?: NSNull.null;
        wifiInfo[@"bssid"] = networkInfo[(__bridge NSString *)kCNNetworkInfoKeyBSSID] ?: NSNull.null;
        break;
      }
    }
  }
#endif

  return FBResponseWithObject(wifiInfo);
}

#pragma mark - Cellular Info

+ (id<FBResponsePayload>)handleGetCellularInfo:(FBRouteRequest *)request
{
#if TARGET_OS_SIMULATOR
  return FBResponseWithObject(@{@"available": @(NO), @"reason": @"Simulator does not support cellular"});
#else
  CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];

  NSMutableDictionary *result = [NSMutableDictionary dictionary];

  if (@available(iOS 12.0, *)) {
    NSDictionary<NSString *, CTCarrier *> *carriers = networkInfo.serviceSubscriberCellularProviders;
    NSDictionary<NSString *, NSString *> *radioTech = networkInfo.serviceCurrentRadioAccessTechnology;

    NSMutableArray *services = [NSMutableArray array];
    for (NSString *key in carriers) {
      CTCarrier *carrier = carriers[key];
      NSMutableDictionary *serviceInfo = [NSMutableDictionary dictionary];
      serviceInfo[@"serviceId"] = key;
      serviceInfo[@"carrierName"] = carrier.carrierName ?: NSNull.null;
      serviceInfo[@"mobileCountryCode"] = carrier.mobileCountryCode ?: NSNull.null;
      serviceInfo[@"mobileNetworkCode"] = carrier.mobileNetworkCode ?: NSNull.null;
      serviceInfo[@"isoCountryCode"] = carrier.isoCountryCode ?: NSNull.null;
      serviceInfo[@"allowsVOIP"] = @(carrier.allowsVOIP);
      serviceInfo[@"radioAccessTechnology"] = radioTech[key] ?: NSNull.null;
      [services addObject:serviceInfo];
    }
    result[@"services"] = services;
  } else {
    CTCarrier *carrier = networkInfo.subscriberCellularProvider;
    if (carrier) {
      result[@"carrierName"] = carrier.carrierName ?: NSNull.null;
      result[@"mobileCountryCode"] = carrier.mobileCountryCode ?: NSNull.null;
      result[@"mobileNetworkCode"] = carrier.mobileNetworkCode ?: NSNull.null;
      result[@"isoCountryCode"] = carrier.isoCountryCode ?: NSNull.null;
      result[@"allowsVOIP"] = @(carrier.allowsVOIP);
    }
  }

  result[@"available"] = @(YES);
  return FBResponseWithObject(result);
#endif
}

#if !TARGET_OS_TV
#pragma mark - Contacts

+ (id<FBResponsePayload>)handleGetContacts:(FBRouteRequest *)request
{
  CNContactStore *store = [[CNContactStore alloc] init];
  CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];

  if (status != CNAuthorizationStatusAuthorized) {
    return FBResponseWithObject(@{
      @"authorized": @(NO),
      @"authorizationStatus": @(status),
      @"contacts": @[],
      @"message": @"Contacts access not authorized. Grant permission in Settings > Privacy > Contacts",
    });
  }

  NSNumber *limit = request.arguments[@"limit"] ?: @50;
  NSNumber *offset = request.arguments[@"offset"] ?: @0;

  NSArray *keysToFetch = @[
    CNContactGivenNameKey,
    CNContactFamilyNameKey,
    CNContactPhoneNumbersKey,
    CNContactEmailAddressesKey,
    CNContactOrganizationNameKey,
    CNContactJobTitleKey,
  ];

  CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
  fetchRequest.sortOrder = CNContactSortOrderGivenName;

  NSMutableArray *contacts = [NSMutableArray array];
  __block NSUInteger currentIndex = 0;
  NSUInteger offsetVal = offset.unsignedIntegerValue;
  NSUInteger limitVal = limit.unsignedIntegerValue;

  NSError *error;
  [store enumerateContactsWithFetchRequest:fetchRequest error:&error usingBlock:^(CNContact *contact, BOOL *stop) {
    if (currentIndex >= offsetVal && currentIndex < offsetVal + limitVal) {
      NSMutableArray *phones = [NSMutableArray array];
      for (CNLabeledValue<CNPhoneNumber *> *phone in contact.phoneNumbers) {
        [phones addObject:@{
          @"label": phone.label ?: @"",
          @"number": phone.value.stringValue ?: @"",
        }];
      }

      NSMutableArray *emails = [NSMutableArray array];
      for (CNLabeledValue<NSString *> *email in contact.emailAddresses) {
        [emails addObject:@{
          @"label": email.label ?: @"",
          @"email": email.value ?: @"",
        }];
      }

      [contacts addObject:@{
        @"givenName": contact.givenName ?: @"",
        @"familyName": contact.familyName ?: @"",
        @"organization": contact.organizationName ?: @"",
        @"jobTitle": contact.jobTitle ?: @"",
        @"phoneNumbers": phones,
        @"emailAddresses": emails,
      }];
    }
    currentIndex++;
    if (currentIndex >= offsetVal + limitVal) {
      *stop = YES;
    }
  }];

  if (error) {
    return FBResponseWithUnknownError(error);
  }

  return FBResponseWithObject(@{
    @"authorized": @(YES),
    @"contacts": contacts,
    @"total": @(currentIndex),
  });
}

#pragma mark - Calendar

+ (id<FBResponsePayload>)handleGetCalendarEvents:(FBRouteRequest *)request
{
  EKEventStore *store = [[EKEventStore alloc] init];
  EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];

  if (status != EKAuthorizationStatusAuthorized) {
    return FBResponseWithObject(@{
      @"authorized": @(NO),
      @"authorizationStatus": @(status),
      @"events": @[],
      @"message": @"Calendar access not authorized. Grant permission in Settings > Privacy > Calendars",
    });
  }

  NSNumber *days = request.arguments[@"days"] ?: @30;
  NSDate *startDate = [NSDate date];
  NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:days.doubleValue * 86400];

  NSPredicate *predicate = [store predicateForEventsWithStartDate:startDate
                                                          endDate:endDate
                                                        calendars:nil];
  NSArray<EKEvent *> *events = [store eventsMatchingPredicate:predicate];

  NSMutableArray *result = [NSMutableArray array];
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";

  for (EKEvent *event in events) {
    [result addObject:@{
      @"title": event.title ?: @"",
      @"location": event.location ?: @"",
      @"startDate": event.startDate ? [formatter stringFromDate:event.startDate] : @"",
      @"endDate": event.endDate ? [formatter stringFromDate:event.endDate] : @"",
      @"isAllDay": @(event.allDay),
      @"calendar": event.calendar.title ?: @"",
      @"notes": event.notes ?: @"",
    }];
  }

  return FBResponseWithObject(@{
    @"authorized": @(YES),
    @"events": result,
  });
}

#pragma mark - Reminders

+ (id<FBResponsePayload>)handleGetReminders:(FBRouteRequest *)request
{
  EKEventStore *store = [[EKEventStore alloc] init];
  EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder];

  if (status != EKAuthorizationStatusAuthorized) {
    return FBResponseWithObject(@{
      @"authorized": @(NO),
      @"authorizationStatus": @(status),
      @"reminders": @[],
      @"message": @"Reminders access not authorized. Grant permission in Settings > Privacy > Reminders",
    });
  }

  NSPredicate *predicate = [store predicateForRemindersInCalendars:nil];

  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  __block NSArray<EKReminder *> *fetchedReminders = nil;

  [store fetchRemindersMatchingPredicate:predicate completion:^(NSArray<EKReminder *> *reminders) {
    fetchedReminders = reminders;
    dispatch_semaphore_signal(semaphore);
  }];

  dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));

  NSMutableArray *result = [NSMutableArray array];
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";

  for (EKReminder *reminder in fetchedReminders) {
    NSDate *dueDate = reminder.dueDateComponents ? [[NSCalendar currentCalendar] dateFromComponents:reminder.dueDateComponents] : nil;
    [result addObject:@{
      @"title": reminder.title ?: @"",
      @"isCompleted": @(reminder.completed),
      @"priority": @(reminder.priority),
      @"calendar": reminder.calendar.title ?: @"",
      @"notes": reminder.notes ?: @"",
      @"dueDate": dueDate ? [formatter stringFromDate:dueDate] : NSNull.null,
    }];
  }

  return FBResponseWithObject(@{
    @"authorized": @(YES),
    @"reminders": result,
  });
}

#pragma mark - Photos

+ (id<FBResponsePayload>)handleGetPhotosCount:(FBRouteRequest *)request
{
  PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];

  if (status != PHAuthorizationStatusAuthorized) {
    return FBResponseWithObject(@{
      @"authorized": @(NO),
      @"authorizationStatus": @(status),
      @"message": @"Photos access not authorized. Grant permission in Settings > Privacy > Photos",
    });
  }

  PHFetchResult *allPhotos = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
  PHFetchResult *allVideos = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:nil];
  PHFetchResult *allAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                     subtype:PHAssetCollectionSubtypeAny
                                                                     options:nil];

  NSMutableArray *albums = [NSMutableArray array];
  for (PHAssetCollection *collection in allAlbums) {
    PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    [albums addObject:@{
      @"title": collection.localizedTitle ?: @"",
      @"count": @(assets.count),
    }];
  }

  return FBResponseWithObject(@{
    @"authorized": @(YES),
    @"photoCount": @(allPhotos.count),
    @"videoCount": @(allVideos.count),
    @"albumCount": @(allAlbums.count),
    @"albums": albums,
  });
}

#pragma mark - Motion / Sensors

+ (id<FBResponsePayload>)handleStartMotionUpdates:(FBRouteRequest *)request
{
  if (!_motionManager) {
    _motionManager = [[CMMotionManager alloc] init];
  }

  NSNumber *interval = request.arguments[@"interval"] ?: @0.1;
  _motionManager.accelerometerUpdateInterval = interval.doubleValue;
  _motionManager.gyroUpdateInterval = interval.doubleValue;
  _motionManager.deviceMotionUpdateInterval = interval.doubleValue;

  if (_motionManager.isAccelerometerAvailable) {
    [_motionManager startAccelerometerUpdates];
  }
  if (_motionManager.isGyroAvailable) {
    [_motionManager startGyroUpdates];
  }
  if (_motionManager.isDeviceMotionAvailable) {
    [_motionManager startDeviceMotionUpdates];
  }

  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleStopMotionUpdates:(FBRouteRequest *)request
{
  if (_motionManager) {
    [_motionManager stopAccelerometerUpdates];
    [_motionManager stopGyroUpdates];
    [_motionManager stopDeviceMotionUpdates];
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleGetMotionData:(FBRouteRequest *)request
{
  if (!_motionManager) {
    _motionManager = [[CMMotionManager alloc] init];
  }

  NSMutableDictionary *data = [NSMutableDictionary dictionary];

  data[@"accelerometerAvailable"] = @(_motionManager.isAccelerometerAvailable);
  data[@"gyroAvailable"] = @(_motionManager.isGyroAvailable);
  data[@"deviceMotionAvailable"] = @(_motionManager.isDeviceMotionAvailable);
  data[@"magnetometerAvailable"] = @(_motionManager.isMagnetometerAvailable);

  if (_motionManager.accelerometerData) {
    CMAccelerometerData *accel = _motionManager.accelerometerData;
    data[@"accelerometer"] = @{
      @"x": @(accel.acceleration.x),
      @"y": @(accel.acceleration.y),
      @"z": @(accel.acceleration.z),
    };
  }

  if (_motionManager.gyroData) {
    CMGyroData *gyro = _motionManager.gyroData;
    data[@"gyroscope"] = @{
      @"x": @(gyro.rotationRate.x),
      @"y": @(gyro.rotationRate.y),
      @"z": @(gyro.rotationRate.z),
    };
  }

  if (_motionManager.deviceMotion) {
    CMDeviceMotion *motion = _motionManager.deviceMotion;
    data[@"attitude"] = @{
      @"roll": @(motion.attitude.roll),
      @"pitch": @(motion.attitude.pitch),
      @"yaw": @(motion.attitude.yaw),
    };
    data[@"gravity"] = @{
      @"x": @(motion.gravity.x),
      @"y": @(motion.gravity.y),
      @"z": @(motion.gravity.z),
    };
    data[@"userAcceleration"] = @{
      @"x": @(motion.userAcceleration.x),
      @"y": @(motion.userAcceleration.y),
      @"z": @(motion.userAcceleration.z),
    };
    data[@"magneticField"] = @{
      @"x": @(motion.magneticField.field.x),
      @"y": @(motion.magneticField.field.y),
      @"z": @(motion.magneticField.field.z),
      @"accuracy": @(motion.magneticField.accuracy),
    };
  }

  return FBResponseWithObject(data);
}

#pragma mark - Brightness

+ (id<FBResponsePayload>)handleGetBrightness:(FBRouteRequest *)request
{
  return FBResponseWithObject(@{
    @"brightness": @([UIScreen mainScreen].brightness),
  });
}

+ (id<FBResponsePayload>)handleSetBrightness:(FBRouteRequest *)request
{
  NSNumber *value = request.arguments[@"brightness"];
  if (!value) {
    return FBResponseWithStatus([FBCommandStatus invalidArgumentErrorWithMessage:@"'brightness' value is required (0.0 - 1.0)"
                                                                       traceback:nil]);
  }
  [UIScreen mainScreen].brightness = value.floatValue;
  return FBResponseWithOK();
}

#pragma mark - Volume

+ (id<FBResponsePayload>)handleGetVolume:(FBRouteRequest *)request
{
  AVAudioSession *session = [AVAudioSession sharedInstance];
  [session setActive:YES error:nil];
  return FBResponseWithObject(@{
    @"outputVolume": @(session.outputVolume),
    @"inputAvailable": @(session.isInputAvailable),
    @"category": session.category ?: @"unknown",
    @"sampleRate": @(session.sampleRate),
    @"outputNumberOfChannels": @(session.outputNumberOfChannels),
    @"inputNumberOfChannels": @(session.inputNumberOfChannels),
  });
}

#pragma mark - Notifications Status

+ (id<FBResponsePayload>)handleGetNotificationStatus:(FBRouteRequest *)request
{
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  __block NSDictionary *result = nil;

  [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
    result = @{
      @"authorizationStatus": @(settings.authorizationStatus),
      @"soundSetting": @(settings.soundSetting),
      @"badgeSetting": @(settings.badgeSetting),
      @"alertSetting": @(settings.alertSetting),
      @"notificationCenterSetting": @(settings.notificationCenterSetting),
      @"lockScreenSetting": @(settings.lockScreenSetting),
      @"alertStyle": @(settings.alertStyle),
    };
    dispatch_semaphore_signal(semaphore);
  }];

  dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));

  if (!result) {
    return FBResponseWithUnknownErrorFormat(@"Timed out getting notification settings");
  }

  return FBResponseWithObject(result);
}

#pragma mark - Bluetooth Status

+ (id<FBResponsePayload>)handleGetBluetoothStatus:(FBRouteRequest *)request
{
  return FBResponseWithObject(@{
    @"note": @"Bluetooth state can be checked via CBCentralManager. Instantiation requires background mode entitlement for full access.",
  });
}
#endif

#pragma mark - Installed Apps

+ (id<FBResponsePayload>)handleGetInstalledApps:(FBRouteRequest *)request
{
  Class LSApplicationWorkspace = NSClassFromString(@"LSApplicationWorkspace");
  if (!LSApplicationWorkspace) {
    return FBResponseWithObject(@{@"apps": @[], @"error": @"LSApplicationWorkspace not available"});
  }

  id workspace = [LSApplicationWorkspace performSelector:NSSelectorFromString(@"defaultWorkspace")];
  if (!workspace) {
    return FBResponseWithObject(@{@"apps": @[], @"error": @"Could not get default workspace"});
  }

  NSArray *allApps = [workspace performSelector:NSSelectorFromString(@"allInstalledApplications")];
  NSMutableArray *apps = [NSMutableArray array];

  for (id app in allApps) {
    NSString *bundleId = nil;
    NSString *name = nil;
    NSString *appType = nil;

    @try {
      bundleId = [app performSelector:NSSelectorFromString(@"applicationIdentifier")];
      name = [app performSelector:NSSelectorFromString(@"localizedName")];
      appType = [app performSelector:NSSelectorFromString(@"applicationType")];
    } @catch (NSException *e) {
      continue;
    }

    if (bundleId) {
      [apps addObject:@{
        @"bundleId": bundleId ?: @"",
        @"name": name ?: @"",
        @"type": appType ?: @"",
      }];
    }
  }

  return FBResponseWithObject(@{
    @"apps": apps,
    @"count": @(apps.count),
  });
}

#pragma mark - Process Info

+ (id<FBResponsePayload>)handleGetProcessInfo:(FBRouteRequest *)request
{
  NSProcessInfo *info = [NSProcessInfo processInfo];
  return FBResponseWithObject(@{
    @"processName": info.processName,
    @"processIdentifier": @(info.processIdentifier),
    @"arguments": info.arguments,
    @"environment": info.environment,
    @"hostName": info.hostName,
    @"globallyUniqueString": info.globallyUniqueString,
    @"operatingSystemVersionString": info.operatingSystemVersionString,
  });
}

#pragma mark - Permissions Status

+ (id<FBResponsePayload>)handleGetPermissionsStatus:(FBRouteRequest *)request
{
  NSMutableDictionary *permissions = [NSMutableDictionary dictionary];

#if !TARGET_OS_TV
  // Location
  permissions[@"location"] = @([CLLocationManager authorizationStatus]);

  // Contacts
  permissions[@"contacts"] = @([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts]);

  // Calendar
  permissions[@"calendar"] = @([EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent]);

  // Reminders
  permissions[@"reminders"] = @([EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder]);

  // Photos
  permissions[@"photos"] = @([PHPhotoLibrary authorizationStatus]);

  // Camera
  permissions[@"camera"] = @([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]);

  // Microphone
  permissions[@"microphone"] = @([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio]);
#endif

  return FBResponseWithObject(permissions);
}

#pragma mark - Open Settings

+ (id<FBResponsePayload>)handleOpenSettings:(FBRouteRequest *)request
{
  NSError *error;
  if (![XCUIDevice.sharedDevice fb_openUrl:UIApplicationOpenSettingsURLString error:&error]) {
    return FBResponseWithUnknownError(error);
  }
  return FBResponseWithOK();
}

#pragma mark - Clipboard

+ (id<FBResponsePayload>)handleGetClipboard:(FBRouteRequest *)request
{
#if TARGET_OS_TV
  return FBResponseWithStatus([FBCommandStatus unsupportedOperationErrorWithMessage:@"Clipboard not available on tvOS"
                                                                          traceback:nil]);
#else
  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
  NSMutableDictionary *result = [NSMutableDictionary dictionary];

  result[@"hasStrings"] = @(pasteboard.hasStrings);
  result[@"hasURLs"] = @(pasteboard.hasURLs);
  result[@"hasImages"] = @(pasteboard.hasImages);
  result[@"hasColors"] = @(pasteboard.hasColors);
  result[@"numberOfItems"] = @(pasteboard.numberOfItems);
  result[@"changeCount"] = @(pasteboard.changeCount);

  if (pasteboard.hasStrings) {
    result[@"string"] = pasteboard.string ?: NSNull.null;
  }
  if (pasteboard.hasURLs) {
    result[@"url"] = pasteboard.URL.absoluteString ?: NSNull.null;
  }

  return FBResponseWithObject(result);
#endif
}

@end
