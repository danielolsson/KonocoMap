//
//  CoordinateConverter.h
//  Map
//
//  Created by Tobias Kräntzer on 22.07.10.
//  Copyright 2010 Konoco <http://konoco.org/> All rights reserved.
//
//  This file is part of Map.
//	
//  Map is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//	
//  Map is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public License
//  along with Map.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>

typedef struct {
    CLLocationDegrees latitudeDelta;
    CLLocationDegrees longitudeDelta;
} CoordinateSpan;

typedef struct {
    CLLocationCoordinate2D center;
    CoordinateSpan span;
} CoordinateRegion;

@interface CoordinateConverter : NSObject {
    
@private
    void * pj_merc;
    void * pj_wgs84;
}

#pragma mark -
#pragma mark Shared Converter

+ (CoordinateConverter *)sharedCoordinateConverter;

#pragma mark -
#pragma mark Coordinate Converter

- (CLLocationCoordinate2D)coordinateFromPoint:(CGPoint)point;
- (CGPoint)pointFromCoordinate:(CLLocationCoordinate2D)coordinate;
- (CoordinateRegion)regionFromRect:(CGRect)rect;
- (CGRect)rectFromRegion:(CoordinateRegion)region;
- (CoordinateRegion)regionFromCoordinate:(CLLocationCoordinate2D)coordinate withRadius:(CGFloat)radius;

@end
