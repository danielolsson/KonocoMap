//
//  HeatMapLayer.m
//  Map
//
//  Created by Tobias Kräntzer on 20.07.10.
//  Copyright 2010 Konoco, Fraunhofer ISST. All rights reserved.
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

#import "HeatMapLayer.h"
#import "HeatMapSample.h"
#import "HeatMapCell.h"


@interface HeatMapLayer ()
- (void)handleHeatMapSample:(HeatMapSample *)aSample;
- (CoordinateRegion)regionForSample:(HeatMapSample *)sample;
- (CFTimeInterval)durationForSample:(HeatMapSample *)sample;
- (CGFloat)valueForSample:(HeatMapSample *)sample;
- (NSColor *)colorForValue:(CGFloat)value;
- (CAMediaTimingFunction *)timingFunctionForSample:(HeatMapSample *)sample;
@end


@implementation HeatMapLayer

@synthesize delegate;
@synthesize notificationName;

- (id)init {
    if ((self = [super init]) != nil) {
        // set composition filter
        CIFilter *compFilter = [CIFilter filterWithName:@"CIColorBlendMode"];
        self.compositingFilter = compFilter;
    }
    return self;
}

- (void)dealloc {
    [notificationObserver release];
    [super dealloc];
}

#pragma mark -
#pragma mark Manage Sample Source

- (void)setNotificationName:(NSString *)name {
    if (![notificationName isEqual:name]) {
        [notificationName release];
        notificationName = [name retain];
        
        [notificationObserver release];
        notificationObserver = [[[NSNotificationCenter defaultCenter]
                                 addObserverForName:notificationName
                                 object:nil
                                 queue:nil
                                 usingBlock:^(NSNotification *notification){
                                     if ([[notification object] isKindOfClass:[HeatMapSample class]]) {
                                         [self handleHeatMapSample:[notification object]];
                                     } else {
                                         NSLog(@"Received a notification with object of type other than HeatMapSample.");
                                     }
                                 }] retain];
    }
}

#pragma mark -
#pragma mark Handle Heat Map Samples

- (void)handleHeatMapSample:(HeatMapSample *)sample {
    
    CoordinateRegion cellRegion = [self regionForSample:sample];
    CGRect cellFrame = [[CoordinateConverter sharedCoordinateConverter] rectFromRegion:cellRegion];
    cellFrame = CGRectMake(cellFrame.origin.x * self.bounds.size.width,
                           cellFrame.origin.y * self.bounds.size.height, 
                           cellFrame.size.width * self.bounds.size.width, 
                           cellFrame.size.height * self.bounds.size.height);
    
    HeatMapCell *cell = [[HeatMapCell alloc] initWithSample:sample
                                                   duration:[self durationForSample:sample]
                                             timingFunction:[self timingFunctionForSample:sample]];
    cell.delegate = self;
    cell.frame = cellFrame;
    
    CGFloat currentScale = self.superlayer.affineTransform.a;
    cell.bounds = CGRectMake(0,
                             0,
                             cell.bounds.size.width * currentScale,
                             cell.bounds.size.height * currentScale);
    
    CGAffineTransform cellTransform = CGAffineTransformIdentity;
	cellTransform = CGAffineTransformScale(cellTransform, 1 / currentScale, 1 / currentScale);
	cell.affineTransform = cellTransform;
    
    [cell setNeedsDisplay];
    
    [self addSublayer:cell];
    [cell release];
}

#pragma mark -
#pragma mark Custom Cell Attributes for Sample

- (CoordinateRegion)regionForSample:(HeatMapSample *)sample {
    if ([self.delegate respondsToSelector:@selector(regionForSample:)]) {
        return [self.delegate regionForSample:sample];
    } else {
        return [[CoordinateConverter sharedCoordinateConverter]
                             regionFromCoordinate:sample.location.coordinate
                                       withRadius:3000];
    }
}

- (CFTimeInterval)durationForSample:(HeatMapSample *)sample {
    if ([self.delegate respondsToSelector:@selector(durationForSample:)]) {
        return [self.delegate durationForSample:sample];
    } else {
        return 60;
    }
}

- (CGFloat)valueForSample:(HeatMapSample *)sample {
    if ([self.delegate respondsToSelector:@selector(valueForSample:)]) {
        return [self.delegate valueForSample:sample];
    } else {
        return (float)rand()/RAND_MAX;
    }
}

- (CAMediaTimingFunction *)timingFunctionForSample:(HeatMapSample *)sample {
    if ([self.delegate respondsToSelector:@selector(timingFunctionForSample:)]) {
        return [self.delegate timingFunctionForSample:sample];
    } else {
        return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    }
}

- (NSColor *)colorForValue:(CGFloat)value {
    if ([self.delegate respondsToSelector:@selector(colorForValue:)]) {
        return [self.delegate colorForValue:value];
    } else {
        return [NSColor colorWithCalibratedHue:value
                                    saturation:1
                                    brightness:0.5
                                         alpha:0];        
    }
}

#pragma mark -
#pragma mark Draw Sample Cell Delegate

- (void)drawLayer:(CALayer *)layer
        inContext:(CGContextRef)ctx {
    
    if (![layer isKindOfClass:[HeatMapCell class]]) {
        DEBUG_LOG(@"Expecting HeatMapCell.");
        return;
    }
    
    HeatMapCell *cell = (HeatMapCell *)layer;
    
    CGContextSetRGBStrokeColor(ctx, 1, 0, 1, 1);
    
    CGGradientRef myGradient;
    CGColorSpaceRef myColorspace;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    
    NSColor *color = [self colorForValue:[self valueForSample:cell.sample]];
    
    CGFloat components[8] = {
        [color redComponent], [color greenComponent], [color blueComponent], 0.8,   // Start color
        [color redComponent], [color greenComponent], [color blueComponent], 0.0    // End color
    };
    
    myColorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    myGradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, num_locations);
    
    CGPoint myStartPoint = CGPointMake(cell.bounds.size.width / 2, cell.bounds.size.height / 2);
    CGPoint myEndPoint = myStartPoint;
    CGFloat myStartRadius = 0;
    CGFloat myEndRadius = cell.bounds.size.width / 2;
    
    CGContextDrawRadialGradient(ctx,
                                myGradient,
                                myStartPoint,
                                myStartRadius,
                                myEndPoint,
                                myEndRadius,
                                kCGGradientDrawsAfterEndLocation);
    
    CGGradientRelease(myGradient);
    CGColorSpaceRelease(myColorspace);
}

@end
