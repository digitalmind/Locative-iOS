#import "MKMapView+ZoomLevel.h"

#define MERCATOR_RADIUS 85445659.44705395

@implementation MKMapView (ZoomLevel)

- (void) setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                   zoomLevel:(NSUInteger)zoomLevel
                    animated:(BOOL)animated {
    MKCoordinateSpan span = MKCoordinateSpanMake(0, 360/pow(2, zoomLevel)*self.frame.size.width/256);
    [self setRegion:MKCoordinateRegionMake(centerCoordinate, span) animated:animated];
}

-(NSInteger) zoomLevel {
	return 21 - round(log2(self.region.span.longitudeDelta * MERCATOR_RADIUS * M_PI / (180.0 * self.bounds.size.width)));
}

- (CGFloat) radiusMultiplier {
    return (15.0f / (float)[self zoomLevel]) * pow(fmax(1, (15 - [self zoomLevel])), 2);
}

-(void) zoomToLocation:(CLLocation *)location withMarginInMeters:(CGFloat)meters animated:(BOOL)animated {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location.coordinate, meters * 10, meters * 10);
    [self setRegion:region animated:YES];
}

@end
