###############################################################################
##
## SL20 airship for FlightGear.
## Walk view configuration.
##
##  Copyright (C) 2010 - 2011  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license v2 or later.
##
###############################################################################

# Constraints

var keelConstraint =
    walkview.makeUnionConstraint(
        [
         walkview.makePolylinePath(
             [
              [ 20.0,  0.0,  -9.28968],
              [ 30.0,  0.0,  -10.43958],
              [ 40.0,  0.0,  -10.97382],
              [ 50.0,  0.0,  -11.1359],
              [ 60.0,  0.0,  -11.13589],
              [ 70.0,  0.0,  -11.13589],
              [ 80.0,  0.0,  -11.13589],
              [ 90.0,  0.0,  -11.13589],
              [100.0,  0.0,  -11.13589],
              [110.0,  0.0,  -11.13589],
              [120.0,  0.0,  -11.1359],
              [130.0,  0.0,  -10.89294],
              [140.0,  0.0,  -10.35213],
              [150.0,  0.0,  -9.45342],
             ],
             0.20),
         walkview.makePolylinePath(
             [
              [129.68004, -5.90435, -9.47266],
              [129.68004, -0.25, -10.89294],
              [129.68004,  0.25, -10.89294],
              [129.68004,  5.90435, -9.47266],
             ],
             0.20),
         walkview.makePolylinePath(
             [
              [129.43462, -3.40, -10.10],
              [129.17999, -3.40, -15.45],
              [129.17999, -4.00, -15.45],
             ],
             0.20),
         walkview.makePolylinePath(
             [
              [128.1, -4.00, -15.45],
              [130.7, -4.00, -15.45],
             ],
             0.20),
         walkview.makePolylinePath(
             [
              [129.43462, 3.40, -10.10],
              [129.17999, 3.40, -15.45],
              [129.17999, 4.00, -15.45],
             ],
             0.20),
         walkview.makePolylinePath(
             [
              [128.1, 4.00, -15.45],
              [130.7, 4.00, -15.45],
             ],
             0.20),
         walkview.makePolylinePath(
             [
              [ 78.35, -11.50000, -10.00],
              [ 79.50, -11.50000, -10.00],
              [ 79.50, -11.00000, -10.00],
              [ 79.50,  -9.23263, -6.90471],
              [ 79.50,  -9.10806, -6.91566],
              [ 79.50,  -0.25, -11.13589],
              [ 79.50,   0.25, -11.13589],
              [ 79.50,   9.10806, -6.91566],
              [ 79.50,   9.23263, -6.90471],
              [ 79.50,  11.00000, -10.00],
              [ 79.50,  11.50000, -10.00],
              [ 78.35,  11.50000, -10.00],
             ],
             0.20),
         walkview.makePolylinePath(
             [
              [ 78.35, -11.50, -10.00],
              [ 80.85, -11.50, -10.00],
             ],
             0.20),
         walkview.makePolylinePath(
             [
              [ 78.35, 11.50, -10.00],
              [ 80.85, 11.50, -10.00],
             ],
             0.20),
         walkview.makePolylinePath(
             [
              [ 39.63, 0.00, -10.99533],
              [ 39.63, 0.61, -10.99533],
              [ 39.41, 0.61, -15.45],
              [ 39.41, 0.00, -15.45],
             ],
             0.20),
         walkview.makePolylinePath(
             [
              [ 38.45, 0.00, -15.45],
              [ 41.00, 0.00, -15.45],
             ],
             0.20),
         walkview.makePolylinePath(
             [
              [ 29.5969,  0.00, -10.40514],
              [ 29.5969, -0.4466, -10.40514],
              [ 29.5969, -0.4466, -13.27],
              [ 28.00, -0.4466, -13.27],
              [ 28.00,  0.4466, -13.27],
              [ 32.00,  0.4466, -13.27],
             ],
             0.20),
        ]);

#var ladderPosition = [22.7, -0.45, 0.0];

#var climbLadder = func {
#    var walker = walkview.active_walker();
#    if (walker != nil) {
#        var p = walker.get_pos();
#        if (math.abs(p[0] - ladderPosition[0]) < 0.5 and
#            math.abs(p[1] - ladderPosition[1]) < 0.5) {
#            
#            if (walker.get_constraints() == keelConstraint) {
#                walker.set_constraints(carConstraint);
#            } else {
#                walker.set_constraints(keelConstraint);
#            }
#        }
#    }
#}

# Create the view managers.
var rigger_walker = walkview.Walker.new("Watch Officer View", keelConstraint, [walkview.JSBSimPointmass.new(12)]);


