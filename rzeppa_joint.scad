/**
Rzeppa Joint v1.5


*/

// --- Parameters ---
/* [Render logic] */
display_inner = true;
display_cage = true;
display_outer = true;
display_spline_shaft = false;

// The angle for the inner race to be shown when rendering all.
display_angle_inner = 0; // [ 0: 1: 45]

// The angle for the cage to be shown when rendering all.

/* [Parameters] */

// Ball diameter
ball_dia = 3; // [3, 4, 6]

// The number of balls to use
num_balls = 5;

/* [ Tuning ] */
// The size of the inner race relative to the ball size
inner_multiplier = 1.2; // [ 1.0 : 0.05 : 1.5]
// The thickness of the cage relative to the ball size
cage_multiplier = 0.9; // [ 0.75 : 0.05 : 1.25 ]
// The thickness of the outer race relative to the ball size
outer_multiplier = 1.0; // [1.0:0.05:5]
// the preference for ball tracks to be more on inner or outer race.
ball_track_translation = 0.4; // [ 0 : 0.1: 0.5 ]
// Tolerance for gaps between parts in 3D printing
clearance = 0.05;

// Maximum cut angle for the ball track going down
max_ball_track_lower_angle = 45;
// Maximum cut angle for the ball track going up
max_ball_track_upper_angle=12;

cage_slot_upper_angle = 0;
cage_slot_lower_angle = 22.5;

// Should we print a slot in the cage
use_cage_slot = false;
// The width of the cage slot
cage_slot_width = 0.8;
// Where to put the in the cage slot, when it would fall over a bearing hole
cage_slot_angle = 20;

/* [ Shafts] */
inner_shaft_type = "shaft"; // ["shaft", "hex" ]

use_inner_shaft = (inner_shaft_type == "shaft");
inner_shaft_length= 20;
inner_shaft_diam = 8;

use_inner_hex = (inner_shaft_type == "hex");
inner_hex_depth = 4;

outer_shaft_type = "shaft"; // ["shaft", "hex" ]
use_outer_shaft = (outer_shaft_type == "shaft");
outer_shaft_length = 16;
outer_shaft_diam = 8;


/* [ Hidden ] */
// Thes are derived from above
r_ball = ball_dia / 2;
r_inner = ball_dia * inner_multiplier;
cage_height = 2*r_ball;
cage_thickness = r_ball * cage_multiplier;
r_outer_int = r_inner + cage_thickness + clearance;
wall_thickness = r_ball * outer_multiplier;
r_outer_ext = r_outer_int + wall_thickness;
display_angle_cage = display_angle_inner/2;

$fn = 60;

// Begin

if (display_inner) {
    rotate([0, display_angle_inner, 0]) {
        inner_race();
        translate([0,0,10])
        if (display_spline_shaft)
        outer_spline_sleeve();

    }

}
if (display_cage) {
    rotate([0,display_angle_cage,0]) {
      cage();
    }
}
if (display_outer) {
  outer_race();
}

// --- Modules ---


module hex_hole(width_across_flats, thickness) {
  // radius = (width / 2) / cos(30)
  r_outer = (width_across_flats / 2) / 0.866;
  cylinder(h = thickness, r = r_outer, center=true, $fn = 6);
}

// Parameters for 8mm base shaft
module splined_shaft(shaft_diameter=8, length=50, teeth=6) {
    union() {
        cylinder(d=shaft_diameter, h=length);
        for(i=[0:teeth-1]) {
            rotate([0,0,i*(360/teeth)])
                translate([shaft_diameter/2, 0, length/2])
                    cube([2, 2, length], center=true);
        }
    }
}

module outer_spline_sleeve(sleeve_length=30, shaft_diameter=8, teeth=6, spline_clearance=0.25) {

    difference() {
        // The outer housing
        cylinder(d=shaft_diameter + 6, h=sleeve_length);

        // The hollow core with clearance
        translate([0, 0, -1]) // Overlap for clean cut
            cylinder(d=shaft_diameter + spline_clearance, h=sleeve_length + 2);

        // The tooth channels
        for(i=[0:teeth-1]) {
            rotate([0, 0, i * (360/teeth)])
                translate([shaft_diameter/2, 0, sleeve_length/2])
                    cube([3, 2 + spline_clearance, sleeve_length + 2], center=true);
        }
    }
}

/*
  Generates the grooves where balls will fit on both the inner and outer races.
*/
module ball_tracks() {

  for (i = [0 : num_balls - 1]) {
    rotate([0, 0, i * (360 / num_balls)])
    // Create an arc of spheres instead of a straight hull
    for (a = [-max_ball_track_upper_angle : 5 : max_ball_track_lower_angle]) { // 5-degree steps for smoothness
      rotate([0, a, 0])
      translate([r_inner + r_ball*ball_track_translation, 0, 0])
      sphere(r = r_ball + clearance);
    }
  }
}

module inner_race() {
  color("SteelBlue")

  union() {

    difference() {
      sphere(r = r_inner);
      ball_tracks();
    }

    if (use_inner_shaft) {
        translate([0,0, r_inner/2]) {
          cylinder(h= r_outer_ext, r = inner_shaft_diam/2, center = false);
      }
      translate([0,0, r_outer_ext]) {
       splined_shaft(shaft_diameter=inner_shaft_diam, length=inner_shaft_length);
      }
    }


    if (use_inner_hex) {
      translate( [0,0, r_inner+ball_dia/2-inner_hex_depth])
      hex_hole(width_across_flats = inner_shaft_diam, thickness=r_inner);
    }
  }
}

module cage() {
  color("LightGrey", 0.5)
  difference() {
    // Outer shell of cage
    sphere(r = r_inner  + cage_thickness);

    // Inner hollow for inner race
    sphere(r = r_inner + clearance);

    // Slot logic for the cage module
    for (i = [0 : num_balls - 1]) {
      rotate([0, 0, i * (360 / num_balls)])
      hull() {
          // Upper limit of ball travel
          rotate([0, cage_slot_upper_angle, 0])
          translate([r_inner + r_ball/2, 0, 0])
              sphere(r = r_ball + clearance);

          // Lower limit of ball travel
          rotate([0, cage_slot_lower_angle, 0])
          translate([r_inner + r_ball/2, 0, 0])
              sphere(r = r_ball + clearance);
      }
    }

    // shaft end (top)
    translate([0, 0, r_outer_ext + cage_height/2 + r_ball/2]) {
      cube(r_outer_ext * 2, center = true);
    }

    // inside end - make it deeper to cover over inside race
    translate([0, 0, -(cage_height/2 + r_outer_ext + 1.5*r_ball)]) {
      cube(r_outer_ext * 2, center = true);
    }

    // a slot to help it flex for assembly
    if (use_cage_slot) {
      rotate([0,0,cage_slot_angle])
        translate([0,r_inner + cage_thickness/2, 0])
          cube([cage_slot_width, cage_thickness + 2,  cage_height * 2],center=true);
    }
  }
}

module outer_race() {
  opening_radius = r_inner +clearance;

  color("White", 0.2)
  union() {
    difference() {
      sphere(r = r_outer_ext);


      // a flat bottom inside the outer race to keep the cage in place
      difference() {
        sphere(r = r_outer_int);
        translate([0,0, -r_outer_int])
          cylinder(h = r_ball, r = r_inner, center = true);
      }

      ball_tracks();


      // bevel top
      translate([0,0, r_inner/2 - r_ball])
        cylinder(h = r_outer_ext,
                 r1 = opening_radius,
                 r2 = r_outer_ext,
                 center = false);

      // flat part top
      //translate([0,0, r_inner*0.6 ])
      //  cylinder(h=r_outer_ext, r=r_outer_ext, center=false);

    }
    // the shaft
    translate([0,0, -(r_outer_ext + outer_shaft_length/2 )])
      cylinder(h = outer_shaft_length + wall_thickness, r = outer_shaft_diam/2, center = true);
  }
}
