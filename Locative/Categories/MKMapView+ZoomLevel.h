@import MapKit;

@interface MKMapView (ZoomLevel)

- (void) setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                   zoomLevel:(NSUInteger)zoomLevel
                    animated:(BOOL)animated;

-(NSInteger) zoomLevel;

- (CGFloat) radiusMultiplier;

-(void) zoomToLocation:(CLLocation *)location withMarginInMeters:(CGFloat)meters animated:(BOOL)animated;

@end
