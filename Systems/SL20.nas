###############################################################################
##
## Zeppelin LZ 121 "Nordstern" airship for FlightGear.
##
##  Copyright (C) 2010 - 2016  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license v2 or later.
##
###############################################################################

###############################################################################
# External API
#
# autoWeightOff()
# printWOW()
# shiftTrimBallast(direction, amount)
# releaseBallast(location, amount)
# refillQuickReleaseBallast(location)
# setForwardGasValves()
# setAftGasValves()
# switchEngineDirection(engine)
# about()
#

# Constants
var FORWARD = -1;
var AFT     = -2;
var FORE_BALLAST = -1;
var AFT_BALLAST = -2;
var QUICK_RELEASE_BAG_CAPACITY = 220.5; # lb
var TRIM_BAG_CAPACITY = 9000.0; # lb

var mixture_timer = 0;
var sight_timer = 0;

###############################################################################
var weight_on_gear_p = "/fdm/jsbsim/forces/fbz-gear-lbs";

var trim_ballast_p =
    [
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[4]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[5]"
    ];
var fore_ballast_p =
    [
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[6]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[7]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[8]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[9]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[10]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[11]"
    ];
var fore_ballast_toggles_p =
    [
     "/controls/ballast/release[0]",
     "/controls/ballast/release[1]",
     "/controls/ballast/release[2]",
     "/controls/ballast/release[3]",
     "/controls/ballast/release[4]",
     "/controls/ballast/release[5]",
    ];
var aft_ballast_p =
    [
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[0]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[1]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[2]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[3]"
    ];
var aft_ballast_toggles_p =
    [
     "/controls/ballast/release[6]",
     "/controls/ballast/release[7]",
     "/controls/ballast/release[8]",
     "/controls/ballast/release[9]"
    ];
var fore_ballast_action_p =
    [
     "/controls/ballast/action[0]",
     "/controls/ballast/action[1]",
     "/controls/ballast/action[2]",
     "/controls/ballast/action[3]",
     "/controls/ballast/action[4]",
     "/controls/ballast/action[5]"
    ];
var aft_ballast_action_p =
    [
     "/controls/ballast/action[6]",
     "/controls/ballast/action[7]",
     "/controls/ballast/action[8]",
     "/controls/ballast/action[9]"
    ];
var all_ballast_p =
    [
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[0]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[1]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[2]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[3]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[6]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[7]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[8]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[9]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[10]",
     "/fdm/jsbsim/inertia/pointmass-weight-lbs[11]"
    ];
var all_ballast_toggles_p =
    [
     "/controls/ballast/release[0]",
     "/controls/ballast/release[1]",
     "/controls/ballast/release[2]",
     "/controls/ballast/release[3]",
     "/controls/ballast/release[4]",
     "/controls/ballast/release[5]",
     "/controls/ballast/release[6]",
     "/controls/ballast/release[7]",
     "/controls/ballast/release[8]",
     "/controls/ballast/release[9]"
    ];
var all_ballast_action_p =
    [
     "/controls/ballast/action[0]",
     "/controls/ballast/action[1]",
     "/controls/ballast/action[2]",
     "/controls/ballast/action[3]",
     "/controls/ballast/action[4]",
     "/controls/ballast/action[5]",
     "/controls/ballast/action[6]",
     "/controls/ballast/action[7]",
     "/controls/ballast/action[8]",
     "/controls/ballast/action[9]"
    ];
var current_fore_ballast_index = "/controls/ballast/current_fore_ballast_index";
var current_aft_ballast_index = "/controls/ballast/current_aft_ballast_index";

var printWOW = func
{
	if (getprop("/gear/gear[0]/wow"))
	{
		gui.popupTip("Current weight on gear " ~ -getprop(weight_on_gear_p) ~ " lbs.");
	}
	else
	{
		gui.popupTip("Current lift " ~ getprop("/fdm/jsbsim/static-condition/net-lift-lbs") ~ " lbs.");
	}
}

# Weight off to neutral
var autoWeighoff = func
{
	if (getprop("/gear/gear[0]/wow"))
	{
       gui.popupTip("Weight-off in progress.");
	   var lift = getprop("/fdm/jsbsim/static-condition/net-lift-lbs");
	   var n = size(trim_ballast_p);
	   print("SL20: Auto weigh off from " ~ (-lift) ~ " lb heavy to neutral.");
	   foreach(var p; trim_ballast_p)
	   {
		   var v = getprop(p) + lift/n;
           setprop(p, (v > 0 ? v : 0));
	   }
    }
    else
       gui.popupTip("Must be on ground for weight-off.");
}

var gascellInit_0  = 0;
var gascellInit_1  = 0;
var gascellInit_2  = 0;
var gascellInit_3  = 0;
var gascellInit_4  = 0;
var gascellInit_5  = 0;
var gascellInit_6  = 0;
var gascellInit_7  = 0;
var gascellInit_8  = 0;
var gascellInit_9  = 0;
var gascellInit_10 = 0;
var gascellInit_11 = 0;
var gascellInit_12 = 0;
var gascellInit_13 = 0;
var gascellInit_14 = 0;
var gascellInit_15 = 0;
var gascellInit_16 = 0;
var gascellInit_17 = 0;

var init_all = func(reinit=0)
{
    if (!reinit) {
        # Livery support.
        aircraft.livery.init("Aircraft/SL20/Models/Liveries");

		gascellInit_0  = getprop("fdm/jsbsim/buoyant_forces/gas-cell[0]/contents-mol");
		gascellInit_1  = getprop("fdm/jsbsim/buoyant_forces/gas-cell[1]/contents-mol");
		gascellInit_2  = getprop("fdm/jsbsim/buoyant_forces/gas-cell[2]/contents-mol");
		gascellInit_3  = getprop("fdm/jsbsim/buoyant_forces/gas-cell[3]/contents-mol");
		gascellInit_4  = getprop("fdm/jsbsim/buoyant_forces/gas-cell[4]/contents-mol");
		gascellInit_5  = getprop("fdm/jsbsim/buoyant_forces/gas-cell[5]/contents-mol");
		gascellInit_6  = getprop("fdm/jsbsim/buoyant_forces/gas-cell[6]/contents-mol");
		gascellInit_7  = getprop("fdm/jsbsim/buoyant_forces/gas-cell[7]/contents-mol");
		gascellInit_8  = getprop("fdm/jsbsim/buoyant_forces/gas-cell[8]/contents-mol");
		gascellInit_9  = getprop("fdm/jsbsim/buoyant_forces/gas-cell[9]/contents-mol");
		gascellInit_10 = getprop("fdm/jsbsim/buoyant_forces/gas-cell[10]/contents-mol");
		gascellInit_11 = getprop("fdm/jsbsim/buoyant_forces/gas-cell[11]/contents-mol");
		gascellInit_12 = getprop("fdm/jsbsim/buoyant_forces/gas-cell[12]/contents-mol");
		gascellInit_13 = getprop("fdm/jsbsim/buoyant_forces/gas-cell[13]/contents-mol");
		gascellInit_14 = getprop("fdm/jsbsim/buoyant_forces/gas-cell[14]/contents-mol");
		gascellInit_15 = getprop("fdm/jsbsim/buoyant_forces/gas-cell[15]/contents-mol");
		gascellInit_16 = getprop("fdm/jsbsim/buoyant_forces/gas-cell[16]/contents-mol");
		gascellInit_17 = getprop("fdm/jsbsim/buoyant_forces/gas-cell[17]/contents-mol");

        # Create FG /controls/gas/ aliases for FDM owned controls.
        var fdm = "fdm/jsbsim/buoyant_forces/gas-cell";
        props.globals.getNode(gascell ~ "[0]", 1).alias(props.globals.getNode(fdm ~ "[17]/valve_open"));
        props.globals.getNode(gascell ~ "[1]", 1).alias(props.globals.getNode(fdm ~ "[16]/valve_open"));
        props.globals.getNode(gascell ~ "[4]", 1).alias(props.globals.getNode(fdm ~ "[15]/valve_open"));
        props.globals.getNode(gascell ~ "[5]", 1).alias(props.globals.getNode(fdm ~ "[14]/valve_open"));
        props.globals.getNode(gascell ~ "[6]", 1).alias(props.globals.getNode(fdm ~ "[13]/valve_open"));
        props.globals.getNode(gascell ~ "[7]", 1).alias(props.globals.getNode(fdm ~ "[12]/valve_open"));

        props.globals.getNode(gascell ~ "[2]", 1).alias(props.globals.getNode(fdm ~ "[1]/valve_open"));
        props.globals.getNode(gascell ~ "[3]", 1).alias(props.globals.getNode(fdm ~ "[0]/valve_open"));
        props.globals.getNode(gascell ~ "[8]", 1).alias(props.globals.getNode(fdm ~ "[2]/valve_open"));
        props.globals.getNode(gascell ~ "[9]", 1).alias(props.globals.getNode(fdm ~ "[3]/valve_open"));
        props.globals.getNode(gascell ~ "[10]", 1).alias(props.globals.getNode(fdm ~ "[4]/valve_open"));
        props.globals.getNode(gascell ~ "[11]", 1).alias(props.globals.getNode(fdm ~ "[5]/valve_open"));
            settimer(func {
                ground_crew.place_ground_crew
                    (geo.aircraft_position(),
                     getprop("/orientation/heading-deg"));
                ground_crew.activate();
            }, 0.5);
    }
    mixture_timer = maketimer(1, updateMixture);
    mixture_timer.start();
    sight_timer = maketimer(1, updateBombSight);
    setlistener("/sim/current-view/name", checkView);
    print("SL20 Systems ... Check");
}

var _nordstern_initialized = 0;
setlistener("/sim/signals/fdm-initialized", func {
    init_all(_nordstern_initialized);
    _nordstern_initialized = 1;
	setprop("/fdm/jsbsim/crew/helmsman/heading-magnetic-cmd-deg" , getprop("/orientation/heading-deg"));
	setprop("/fdm/jsbsim/crew/elevatorman/altitude-cmd-ft" , getprop("/position/altitude-ft"));
	setprop("/autopilot/settings/target-pitch-deg" , 0);
    setprop("/controls/engines/engine[0]/opstatereq", 0);
    setprop("/controls/engines/engine[0]/opstateresp", 0);
    setprop("/controls/engines/engine[1]/opstatereq", 0);
    setprop("/controls/engines/engine[1]/opstateresp", 0);
    setprop("/controls/engines/engine[2]/opstatereq", 0);
    setprop("/controls/engines/engine[2]/opstateresp", 0);
    setprop("/controls/engines/engine[3]/opstatereq", 0);
    setprop("/controls/engines/engine[3]/opstateresp", 0);
    setprop("/controls/engines/engine[4]/opstatereq", 0);
    setprop("/controls/engines/engine[4]/opstateresp", 0);
    setprop("/controls/ballast/action[0]", 0);
    setprop("/controls/ballast/action[1]", 0);
    setprop("/controls/ballast/action[2]", 0);
    setprop("/controls/ballast/action[3]", 0);
    setprop("/controls/ballast/action[4]", 0);
    setprop("/controls/ballast/action[5]", 0);
    setprop("/controls/ballast/action[6]", 0);
    setprop("/controls/ballast/action[7]", 0);
    setprop("/controls/ballast/action[8]", 0);
    setprop("/controls/ballast/action[9]", 0);
    setprop("/controls/ballast/current_fore_ballast_index", 0);
    setprop("/controls/ballast/current_aft_ballast_index", 0);
    setlistener("controls/ballast/action[0]", func() { broadcast.send(message_id["drop_water"] ~ Binary.encodeByte(0) ~ Binary.encodeInt(getprop("/controls/ballast/action[0]"))); });
    setlistener("controls/ballast/action[1]", func() { broadcast.send(message_id["drop_water"] ~ Binary.encodeByte(1) ~ Binary.encodeInt(getprop("/controls/ballast/action[1]"))); });
    setlistener("controls/ballast/action[2]", func() { broadcast.send(message_id["drop_water"] ~ Binary.encodeByte(2) ~ Binary.encodeInt(getprop("/controls/ballast/action[2]"))); });
    setlistener("controls/ballast/action[3]", func() { broadcast.send(message_id["drop_water"] ~ Binary.encodeByte(3) ~ Binary.encodeInt(getprop("/controls/ballast/action[3]"))); });
    setlistener("controls/ballast/action[4]", func() { broadcast.send(message_id["drop_water"] ~ Binary.encodeByte(4) ~ Binary.encodeInt(getprop("/controls/ballast/action[4]"))); });
    setlistener("controls/ballast/action[5]", func() { broadcast.send(message_id["drop_water"] ~ Binary.encodeByte(5) ~ Binary.encodeInt(getprop("/controls/ballast/action[5]"))); });
    setlistener("controls/ballast/action[6]", func() { broadcast.send(message_id["drop_water"] ~ Binary.encodeByte(6) ~ Binary.encodeInt(getprop("/controls/ballast/action[6]"))); });
    setlistener("controls/ballast/action[7]", func() { broadcast.send(message_id["drop_water"] ~ Binary.encodeByte(7) ~ Binary.encodeInt(getprop("/controls/ballast/action[7]"))); });
    setlistener("controls/ballast/action[8]", func() { broadcast.send(message_id["drop_water"] ~ Binary.encodeByte(8) ~ Binary.encodeInt(getprop("/controls/ballast/action[8]"))); });
    setlistener("controls/ballast/action[9]", func() { broadcast.send(message_id["drop_water"] ~ Binary.encodeByte(9) ~ Binary.encodeInt(getprop("/controls/ballast/action[9]"))); });
    setlistener("/sim/weapons/dropping", func() {
               broadcast.send(message_id["drop_bombs"] ~ Binary.encodeByte(getprop("/sim/weapons/bomb[0]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[1]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[2]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[3]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[4]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[5]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[6]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[7]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[8]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[9]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[10]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[11]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[12]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[13]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[14]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[15]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[16]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[17]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[18]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[19]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[20]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[21]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[22]/present"))
                                                       ~ Binary.encodeByte(getprop("/sim/weapons/bomb[23]/present"))
                             ); });
});

# Initialize scenario network for full participation.
io.load_nasal(getprop("/sim/aircraft-dir") ~ "/Systems/scenario-network.nas", "SL20");
scenario_network_init(1);

###############################################################################
# Ballast controls

# Release one or more quick-release ballast units.
var releaseBallast = func(location, amount) {
    var units   = nil;
    var toggles = nil;
    var action = nil;
    var sIndex = nil;
    if (location == FORE_BALLAST) {
        units   = fore_ballast_p;
        toggles = fore_ballast_toggles_p;
        action = fore_ballast_action_p;
        sIndex = getprop(current_fore_ballast_index);
    } elsif (location == AFT_BALLAST) {
        units   = aft_ballast_p;
        toggles = aft_ballast_toggles_p;
        action = aft_ballast_action_p;
        sIndex = getprop(current_aft_ballast_index);
    } else {
        printlog("warn",
                 "SL20.releaseBallast(" ~ location ~ ", " ~ amount ~
                 "): Invalid ballast location.");
        return;
    }
    forindex (var i; units)
    {
        if (!amount) return;
        if ((getprop(action[sIndex]) == 0) and (getprop(units[sIndex]) > 0.0))
        {
            var act = action[sIndex];
            setprop(act, 1);
        #    settimer(func { stopBallastAction(act); }, 3);
            #interpolate(units[i], 0.0, 1.0);
            setprop(toggles[sIndex], 1.0);
            amount -= 1;
            sIndex += 1;
        }
        if (location == FORE_BALLAST)
        {
           if (sIndex > 5)
           {
               sIndex = 0;
               gui.popupTip("Fore Ballast empty!");
           }
           if ((sIndex == 0) and (getprop(units[sIndex]) == 0))
           {
               gui.popupTip("Fore Ballast empty!");
           }
           setprop(current_fore_ballast_index, sIndex);
        }
        else
        {
           if (sIndex > 3)
           {
               sIndex = 0;
               gui.popupTip("Aft Ballast empty!");
           }
           if ((sIndex == 0) and (getprop(units[sIndex]) == 0))
           {
               gui.popupTip("Aft Ballast empty!");
           }
           setprop(current_aft_ballast_index, sIndex);
        }
    }
}

var stopBallastAction = func(prop)
{
   setprop(prop, 0);
}

# Refills empty "ballasthosen" from the trim ballast bags.
var refillQuickReleaseBallast = func()
{
    var units   = all_ballast_p;
    var toggles = all_ballast_toggles_p;
	var action  = all_ballast_action_p;
    setprop(current_fore_ballast_index, 0);
    setprop(current_aft_ballast_index, 0);
    var n = size(trim_ballast_p);
    forindex (var ab; action)
    {
		setprop(action[ab], 0);
	}
	var val = 0;
	var count = 0;
    forindex (var qb; units)
    {
		if (getprop(units[qb]) != QUICK_RELEASE_BAG_CAPACITY)
		{
			count = count + 1;
			val = val + (QUICK_RELEASE_BAG_CAPACITY - getprop(units[qb]));
		}
		setprop(toggles[qb], 0.0);
	}
	if (count == 0)
	{
		return;
	}
	val = val / n;
	var last = 0;
    foreach(var tb; trim_ballast_p)
    {
		var tmp = getprop(tb) - val;
		if (tmp < 0)
		{
			last = last + tmp;
			tmp = 0;
		}
	    interpolate(tb, tmp, 10.0);
	}
	var subtract = last / count;
    forindex (var db; units)
    {
		if (getprop(units[db]) < QUICK_RELEASE_BAG_CAPACITY)
		{
			interpolate(units[db], QUICK_RELEASE_BAG_CAPACITY + subtract, 10.0);
		}
	}
    settimer(func { gui.popupTip("Refill Ballast finished"); }, 10);
}

# Listen to the /controls/ballast/release[x] controls.
forindex(var i; fore_ballast_toggles_p) {
    setlistener(fore_ballast_toggles_p[i], func (n) {
        if ((getprop(fore_ballast_toggles_p[n.getIndex()]) == 1) and (getprop(fore_ballast_p[n.getIndex()]) > 0))
        {
           setprop(fore_ballast_action_p[n.getIndex()], 1);
           settimer(func { stopBallastAction(fore_ballast_action_p[n.getIndex()]); }, 3);
        }
        interpolate(fore_ballast_p[n.getIndex()], 0.0, 1.0);
    }, 0, 0);
}
forindex(var i; aft_ballast_toggles_p) {
    setlistener(aft_ballast_toggles_p[i], func (n) {
        if ((getprop(aft_ballast_toggles_p[n.getIndex() - size(fore_ballast_toggles_p)]) == 1) and (getprop(aft_ballast_p[n.getIndex() - size(fore_ballast_toggles_p)]) > 0))
        {
		   setprop(aft_ballast_action_p[n.getIndex() - size(fore_ballast_toggles_p)], 1);
           settimer(func { stopBallastAction(aft_ballast_action_p[n.getIndex() - size(fore_ballast_toggles_p)]); }, 3);
        }
        interpolate(aft_ballast_p[n.getIndex() - size(fore_ballast_toggles_p)],
                    0.0, 1.0);
    }, 0, 0);
}


###############################################################################
# Gas valve controls
var gascell = "controls/gas/valve-cmd-norm";

var setForwardGasValves = func (v) {
    setprop(gascell ~ "[0]", v);
    setprop(gascell ~ "[1]", v);
    setprop(gascell ~ "[4]", v);
    setprop(gascell ~ "[5]", v);
    setprop(gascell ~ "[6]", v);
    setprop(gascell ~ "[7]", v);
}

var setAftGasValves = func (v) {
    setprop(gascell ~ "[2]", v);
    setprop(gascell ~ "[3]", v);
    setprop(gascell ~ "[8]", v);
    setprop(gascell ~ "[9]", v);
    setprop(gascell ~ "[10]", v);
    setprop(gascell ~ "[11]", v);
}

var elevator_trim_fwd = func()
{
	var lift = 6181.1023622 - (getprop("/controls/flight/elevator-trim") * 1581);
    setprop("/fdm/jsbsim/inertia/pointmass-location-X-inches[16]", lift);
}

###############################################################################
# Engine controls.

var GetTankState = func(eng)
{
   if (eng == 0)
   {
      if (getprop("/consumables/fuel/tank[2]/empty") and getprop("/consumables/fuel/tank[3]/empty"))
      {
         return 0;
      }
      else
      {
         return 1;
      }
   }
   if (eng == 1)
   {
      if (getprop("/consumables/fuel/tank[4]/empty") and getprop("/consumables/fuel/tank[5]/empty"))
      {
         return 0;
      }
      else
      {
         return 1;
      }
   }
   if (eng == 2)
   {
      if (getprop("/consumables/fuel/tank[0]/empty") and getprop("/consumables/fuel/tank[1]/empty"))
      {
         return 0;
      }
      else
      {
         return 1;
      }
   }
   if (eng == 3)
   {
      if (getprop("/consumables/fuel/tank[6]/empty") and getprop("/consumables/fuel/tank[7]/empty"))
      {
         return 0;
      }
      else
      {
         return 1;
      }
   }
   if (eng == 4)
   {
      if (getprop("/consumables/fuel/tank[8]/empty") and getprop("/consumables/fuel/tank[9]/empty"))
      {
         return 0;
      }
      else
      {
         return 1;
      }
   }
}

var SetEngineState = func (eng, state)
{
    var engineJSB = "/fdm/jsbsim/propulsion/engine" ~ "[" ~ eng ~ "]";
    var engineFG  = "/engines/engine" ~ "[" ~ eng ~ "]";
    var engineCon = "/controls/engines/engine" ~ "[" ~ eng ~ "]";
    var dir       = engineJSB ~ "/yaw-angle-rad";
    if (GetTankState(eng) == 0)
    {
        setprop(engineCon ~ "/cutoff", 1);
        setprop(engineCon ~ "/throttle", 0.0);
        setprop(engineCon ~ "/magnetos", 0);
        setprop(engineCon ~ "/starter", 0);
        setprop(dir, 0);
        setprop(engineCon ~ "/opstatereq", 0);
        settimer(func { setprop(engineCon ~ "/opstateresp", 0); }, 3);
        return;
    }
    if (getprop(engineFG ~ "/running"))
    {
        if (state == -1)
        {
            if ((eng < 0) or (eng > 1))
               return;
            setprop(engineCon ~ "/starter", 0);
            setprop(engineCon ~ "/throttle", 0.6);
            setprop(engineCon ~ "/opstatereq", -1);
            setprop(dir, 3.14159265);
            settimer(func { setprop(engineCon ~ "/opstateresp", -1); }, 3);
        }
        if (state == -2)
        {
            if ((eng < 0) or (eng > 1))
               return;
            setprop(engineCon ~ "/starter", 0);
            setprop(engineCon ~ "/throttle", 0.9);
            setprop(engineCon ~ "/opstatereq", -2);
            setprop(dir, 3.14159265);
            settimer(func { setprop(engineCon ~ "/opstateresp", -2); }, 3);
        }
        if (state == 0)
        {
            setprop(engineCon ~ "/cutoff", 1);
            setprop(engineCon ~ "/throttle", 0.0);
            setprop(engineCon ~ "/magnetos", 0);
            setprop(engineCon ~ "/starter", 0);
            setprop(dir, 0);
            setprop(engineCon ~ "/opstatereq", 0);
            settimer(func { setprop(engineCon ~ "/opstateresp", 0); }, 3);
        }
        if (state == 1)
        {
            setprop(engineCon ~ "/starter", 0);
            setprop(engineCon ~ "/throttle", 0.01);
            setprop(dir, 0);
            setprop(engineCon ~ "/opstatereq", 1);
            settimer(func { setprop(engineCon ~ "/opstateresp", 1); }, 3);
        }
        if (state == 2)
        {
            setprop(engineCon ~ "/starter", 0);
            setprop(engineCon ~ "/throttle", 0.6);
            setprop(dir, 0);
            setprop(engineCon ~ "/opstatereq", 2);
            settimer(func { setprop(engineCon ~ "/opstateresp", 2); }, 3);
        }
        if (state == 3)
        {
            setprop(engineCon ~ "/starter", 0);
            setprop(engineCon ~ "/throttle", 0.85);
            setprop(dir, 0);
            setprop(engineCon ~ "/opstatereq", 3);
            settimer(func { setprop(engineCon ~ "/opstateresp", 3); }, 3);
        }
        if (state == 4)
        {
            setprop(engineCon ~ "/starter", 0);
            if (getprop("/position/altitude-ft") > 6000.0)
            {
               setprop(engineCon ~ "/throttle", 1.0);
               setprop(dir, 0);
               setprop(engineCon ~ "/opstatereq", 4);
               settimer(func { setprop(engineCon ~ "/opstateresp", 4); }, 3);
            }
            else
            {
               setprop(engineCon ~ "/throttle", 1.0);
               setprop(dir, 0);
               setprop(engineCon ~ "/opstatereq", 4);
               settimer(func { setprop(engineCon ~ "/opstateresp", 5); }, 3);
            #   settimer(func { if (getprop(engineCon ~ "/opstateresp") == 5) { SetEngineState(eng, 3); } }, 90);
            }
        }
    }
    else
    {
        if (state != 0)
        {
           setprop(engineCon ~ "/cutoff", 0);
           setprop(engineCon ~ "/throttle", 0.9);
           setprop(engineCon ~ "/magnetos", 3);
           setprop(engineCon ~ "/starter", 1);
           setprop(engineCon ~ "/opstatereq", 1);
           setprop(engineCon ~ "/opstateresp", 0);
           setprop(dir, 0);
           var engineRunning = setlistener(engineFG ~ "/running", func {
              if (getprop(engineFG ~ "/running"))
              {
                 setprop(engineCon ~ "/starter", 0);
                 setprop(engineCon ~ "/throttle", 0.01);
                 removelistener(engineRunning);
                 setprop(engineCon ~ "/opstateresp", 1);
              }
           });
       }
    }
}

var updateMixture = func()
{
   if (getprop("/autopilot/locks/altitude") == "altitude-hold")
   {
       setprop("/fdm/jsbsim/crew/elevatorman/enabled", 1);
   }
   else
   {
       setprop("/fdm/jsbsim/crew/elevatorman/enabled", 0);
   }
   if (getprop("/autopilot/locks/heading") == "true-heading-hold")
   {
       setprop("/fdm/jsbsim/crew/helmsman/enabled", 1);
       var dK = getprop("/autopilot/settings/true-heading-deg");
       var aW = getprop("/environment/wind-from-heading-deg");
       var sW = getprop("/environment/wind-speed-kt");
       var dW = getprop("/velocities/airspeed-kt");
       if (dW != 0)
       {
	      var rK = (math.asin((math.sin((aW - dK) * D2R) * sW) / dW) * R2D) * 0.7;
          setprop("/fdm/jsbsim/crew/helmsman/heading-magnetic-cmd-deg", dK + rK);
       }
       else
       {
          setprop("/fdm/jsbsim/crew/helmsman/heading-magnetic-cmd-deg", getprop("/autopilot/settings/true-heading-deg"));
       }
   }
   else if (getprop("/autopilot/locks/heading") == "dg-heading-hold")
   {
       setprop("/fdm/jsbsim/crew/helmsman/enabled", 1);
   }
   else
   {
       setprop("/fdm/jsbsim/crew/helmsman/enabled", 0);
   }
	gui.menuEnable("refillEQ", getprop("/gear/gear[0]/wow"));
}

var toggleLandingLight = func()
{
    if (getprop("/controls/lighting/landing-light") == 1)
    {
        setprop("/controls/lighting/landing-light", 0);
    }
    else
    {
        setprop("/controls/lighting/landing-light", 1);
    }
}

var toggleLight = func()
{
    if (getprop("/controls/lighting/panel-norm") == 1)
    {
        setprop("/controls/lighting/panel-norm", 0);
    }
    else
    {
        setprop("/controls/lighting/panel-norm", 1);
    }
}

var checkView = func()
{
    if (getprop("/sim/current-view/name") == "Bombsight View")
    {
        setprop("/sim/weapons/sightoff", 0);
        sight_timer.start();
    }
    else
    {
        sight_timer.stop();
        setprop("/sim/weapons/sightoff", 0);
    }
}

var updateBombSight = func()
{
    var h = getprop("/position/altitude-agl-ft") * 0.3048;
    var v = getprop("/velocities/groundspeed-kt") * 0.514444;
    var vorh = ((0.25674 / h) * ((math.sqrt((h * 2) / 9.81) * v) - 58)) / 2.0;
    setprop("/sim/weapons/sightoff", -vorh);
#    print("sight vorhalt " ~ vorh);
}

var EnableHelmsMan = func (state)
{
   setprop("/fdm/jsbsim/crew/helmsman/enabled" , state);
}

var selectNextBomb = func()
{
   var found = 0;
   for (var i = 0; i < 24; i = i + 1)
   {
      if ((getprop("/sim/weapons/bomb[" ~ i ~ "]/tobedropped") == 0) and (getprop("/sim/weapons/bomb[" ~ i ~ "]/dropped") == 0) and (getprop("/sim/weapons/bomb[" ~ i ~ "]/present") == 1))
      {
         prepareBombs(i);
         found = 1;
         gui.popupTip("bomb selected");
         break;
      }
   }
   if (found == 0)
   {
      gui.popupTip("no more bombs available!");
   }
}

var prepareBombs = func(num)
{
   if (getprop("/sim/weapons/bomb[" ~ num ~ "]/tobedropped") == 0)
   {
      setprop("/sim/weapons/bomb[" ~ num ~ "]/tobedropped", 1);
   }
   else
   {
      setprop("/sim/weapons/bomb[" ~ num ~ "]/tobedropped", 0);
   }
}

var dropBombs = func()
{
   settimer(dropBombsWork, 0.25);
}

var dropBombsWork = func()
{
   if (getprop("sim/model/door-positions/BDoor/position-norm") < 1)
   {
      gui.popupTip("open doors first.");
      return;
   }
   if (getprop("/position/altitude-agl-ft") < 400)
   {
      gui.popupTip("altitude too low.");
      return;
   }
   setprop("/sim/weapons/dropping", 1);
   for (var i = 0; i < 24; i = i + 1)
   {
      if ((getprop("/sim/weapons/bomb[" ~ i ~ "]/tobedropped") == 1) and (getprop("/sim/weapons/bomb[" ~ i ~ "]/dropped") == 0) and (getprop("/sim/weapons/bomb[" ~ i ~ "]/present") == 1))
      {
         setprop("/sim/weapons/bomb[" ~ i ~ "]/dropped", 1);
         setprop("/sim/weapons/bomb[" ~ i ~ "]/present", 0);
         if (i < 8)
         {
            setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[23]", getprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[23]") - 220);
         }
         else 
         {
            if (i > 15)
            {
               setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[25]", getprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[25]") - 220);
            }
            else
            {
               setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[24]", getprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[24]") - 220);
            }
         }
      }
   }
   gui.popupTip("bombs dropped.");
   setprop("/sim/weapons/dropping", 0);
}

var impactBomb = func(n)
{
   var node = props.globals.getNode(n.getValue(), 1);
   var impact = n.getValue();
   var solid = getprop(impact ~ "/material/solid");
   if (solid)
   {
      var lat = node.getNode("impact/latitude-deg").getValue();
      var lon = node.getNode("impact/longitude-deg").getValue();
      var ele = node.getNode("impact/elevation-m").getValue();
      var hea = node.getNode("impact/heading-deg").getValue();
      geo.put_model("Aircraft/SL20/Models/crater.xml", lat, lon, ele + 0.1, hea, 0, 0);
      geo.put_model("Aircraft/SL20/Models/bombe.xml", lat, lon, ele + 0.25, hea, 0, 0);
      start_terrain_fire(lat, lon, ele + 0.25, 230);
      var pos = geo.Coord.new().set_latlon(lat, lon, ele);
      broadcast.send(message_id["bomb_impact"] ~ Binary.encodeCoord(pos));
   }
}

setlistener("sim/ai/aircraft/impact/bomb", impactBomb);

var reinitWeights = func()
{
	gui.popupTip("Starting reloading Bombs");
	setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[4]", 30864.0);
	setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[5]", 30864.0);
	setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[0]", QUICK_RELEASE_BAG_CAPACITY);
	setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[1]", QUICK_RELEASE_BAG_CAPACITY);
	setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[2]", QUICK_RELEASE_BAG_CAPACITY);
	setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[3]", QUICK_RELEASE_BAG_CAPACITY);
	setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[6]", QUICK_RELEASE_BAG_CAPACITY);
	setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[7]", QUICK_RELEASE_BAG_CAPACITY);
	setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[8]", QUICK_RELEASE_BAG_CAPACITY);
	setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[9]", QUICK_RELEASE_BAG_CAPACITY);
	setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[10]", QUICK_RELEASE_BAG_CAPACITY);
	setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[11]", QUICK_RELEASE_BAG_CAPACITY);
	if (getprop("/payload/weight[0]/selected") == "Bombs 100 kg")
	{
		for (var i = 0; i < 8; i = i + 1)
		{
			setprop("/ai/submodels/submodel[" ~ i ~ "]/count", 1);
			setprop("/sim/weapons/bomb[" ~ i ~ "]/dropped", 0);
			setprop("/sim/weapons/bomb[" ~ i ~ "]/present", 1);
			setprop("/sim/weapons/bomb[" ~ i ~ "]/tobedropped", 0);
		}
		setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[23]", 1763.7);
	}
	if (getprop("/payload/weight[1]/selected") == "Bombs 100 kg")
	{
		for (var i = 8; i < 16; i = i + 1)
		{
			setprop("/ai/submodels/submodel[" ~ i ~ "]/count", 1);
			setprop("/sim/weapons/bomb[" ~ i ~ "]/dropped", 0);
			setprop("/sim/weapons/bomb[" ~ i ~ "]/present", 1);
			setprop("/sim/weapons/bomb[" ~ i ~ "]/tobedropped", 0);
		}
		setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[24]", 1763.7);
	}
	if (getprop("/payload/weight[2]/selected") == "Bombs 100 kg")
	{
		for (var i = 16; i < 24; i = i + 1)
		{
			setprop("/ai/submodels/submodel[" ~ i ~ "]/count", 1);
			setprop("/sim/weapons/bomb[" ~ i ~ "]/dropped", 0);
			setprop("/sim/weapons/bomb[" ~ i ~ "]/present", 1);
			setprop("/sim/weapons/bomb[" ~ i ~ "]/tobedropped", 0);
		}
		setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[25]", 1763.7);
	}
	setprop("/sim/weapons/dropping", 0);
	gui.popupTip("Starting refilling Fuel");
	for (var t = 0; t < 10; t = t + 1)
	{
		setprop("/consumables/fuel/tank[" ~ t ~ "]/level-norm", 1);
		setprop("/consumables/fuel/tank[" ~ t ~ "]/empty", 0);
	}
	gui.popupTip("Starting refilling Hydrogen gas");
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[0]/contents-mol", gascellInit_0);
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[1]/contents-mol", gascellInit_1);
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[2]/contents-mol", gascellInit_2);
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[3]/contents-mol", gascellInit_3);
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[4]/contents-mol", gascellInit_4);
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[5]/contents-mol", gascellInit_5);
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[6]/contents-mol", gascellInit_6);
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[7]/contents-mol", gascellInit_7);
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[8]/contents-mol", gascellInit_8);
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[9]/contents-mol", gascellInit_9);
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[10]/contents-mol", gascellInit_10);
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[11]/contents-mol", gascellInit_11);
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[12]/contents-mol", gascellInit_12);
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[13]/contents-mol", gascellInit_13);
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[14]/contents-mol", gascellInit_14);
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[15]/contents-mol", gascellInit_15);
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[16]/contents-mol", gascellInit_16);
	setprop("fdm/jsbsim/buoyant_forces/gas-cell[17]/contents-mol", gascellInit_17);
	gui.popupTip("Ship is ready again!");
}

################################################################################
#put_remove_model places a new model at the location specified and then removes
# it time_sec later 
#it puts out 12 models/sec so normally time_sec=.4 or thereabouts it plenty of time to let it run
# If time_sec is too short then no particles will be emitted.  Typical problem is 
# many rounds from a gun slow FG's framerate to a crawl just as it is time to emit the 
# particles.  If time_sec is slower than the frame length then you get zero particle.
# Smallest safe value for time_sec is maybe .3 .4 or .5 seconds.
# 
var put_remove_model = func(lat_deg=nil, lon_deg=nil, elev_m=nil, time_sec=nil, startSize_m=nil, endSize_m=1, path="Models/bombable/Fire-Particles/flack-impact.xml" ) {

  if (lat_deg==nil or lon_deg==nil or elev_m==nil) { return; } 
 
  var delay_sec=0.1; #particles/models seem to cause FG crash *sometimes* when appearing within a model
  #we try to reduce this by making the smoke appear a fraction of a second later, after
  # the a/c model has moved out of the way. (possibly moved, anyway--depending on it's speed)  

 # debprint ("Bombable: Placing flack");
         
  settimer ( func {
    #start & end size in particle system appear to be in feet
    if (startSize_m!=nil) setprop ("/bombable/fire-particles/flack-startsize", startSize_m);
    if (endSize_m!=nil) setprop ("/bombable/fire-particles/flack-endsize", endSize_m);

    fgcommand("add-model", flackNode=props.Node.new({ 
            "path": path, 
            "latitude-deg": lat_deg, 
            "longitude-deg":lon_deg, 
            "elevation-ft": elev_m / 0.3048,
            "heading-deg"  : 0,
            "pitch-deg"    : 0,
            "roll-deg"     : 0, 
            "enable-hot"   : 0,
  
            
              
    }));
    
  var flackModelNodeName= flackNode.getNode("property").getValue();
  
  #add the -prop property in /models/model[X] for each of lat, long, elev, etc
  foreach (name; ["latitude-deg","longitude-deg","elevation-ft", "heading-deg", "pitch-deg", "roll-deg"]){
   setprop(  flackModelNodeName ~"/"~ name ~ "-prop",flackModelNodeName ~ "/" ~ name );
  }  
  
#  debprint ("Bombable: Placed flack, ", flackModelNodeName);
  
  settimer ( func { props.globals.getNode(flackModelNodeName).remove();}, time_sec);

  }, delay_sec);   

}

##############################################################
#Start a fire on terrain, size depending on ballisticMass_lb
#location at lat/lon
#
var start_terrain_fire = func ( lat_deg, lon_deg, alt_m=0, ballisticMass_lb=1.2 ) {

  var info = geodinfo(lat_deg, lon_deg);
  var smokeEndsize = rand()*75+33;
  setprop ("/bombable/fire-particles/smoke-endsize-small", smokeEndsize);
  var smokeEndsize = rand()*125+60;
  setprop ("/bombable/fire-particles/smoke-endsize-large", smokeEndsize);
  var smokeStartsize=rand()*10 + 5;
  setprop ("/bombable/fire-particles/smoke-startsize", smokeStartsize);
  setprop ("/bombable/fire-particles/smoke-startsize-small", smokeStartsize * (rand()/2 + 0.5));
  setprop ("/bombable/fire-particles/smoke-startsize-very-small", smokeStartsize * (rand()/8 + 0.2));
  setprop ("/bombable/fire-particles/smoke-startsize-large", smokeStartsize* (rand()*4 + 1));
  #get the altitude of the terrain
  if (info != nil)
  {
      #if it's water we don't set a fire . . . TODO make a different explosion or fire effect for water 
      if (typeof(info[1])=="hash" and contains(info[1], "solid") and info[1].solid==0) return;
     # else debprint (info);
      
      #we go with explosion point if possible, otherwise the height of terrain at this point
      if (alt_m==nil) alt_m=info[0];
      if (alt_m==nil) alt_m=0; 
      
  }
  time_sec=150; 
  fp1="Models/bombable/Fire-Particles/fire-particles-large.xml";
  put_remove_model(lat_deg:lat_deg, lon_deg:lon_deg, elev_m:alt_m, time_sec:time_sec, startSize_m: nil, endSize_m:nil, path:fp1 );
  time_sec1=600; 
  fp="Models/bombable/Fire-Particles/smoke-particles-large.xml";
  put_remove_model(lat_deg:lat_deg, lon_deg:lon_deg, elev_m:alt_m, time_sec:time_sec1, startSize_m: nil, endSize_m:nil, path:fp );
  ##put it out, but slowly, for large impacts
  if (ballisticMass_lb>50)
  {
    time_sec2=150; fp2="Models/bombable/Fire-Particles/fire-particles-very-small.xml";  
    settimer (func { put_remove_model(lat_deg:lat_deg, lon_deg:lon_deg, elev_m:alt_m, time_sec:time_sec2, startSize_m: nil, endSize_m:nil, path:fp2 )} , time_sec);
    
    time_sec3=150; fp3="Models/bombable/Fire-Particles/fire-particles-very-very-small.xml";  
    settimer (func { put_remove_model(lat_deg:lat_deg, lon_deg:lon_deg, elev_m:alt_m, time_sec:time_sec3, startSize_m: nil, endSize_m:nil, path:fp3 )} , time_sec+time_sec2);
    
    time_sec4=150; fp4="Models/bombable/Fire-Particles/fire-particles-very-very-very-small.xml";  
    settimer (func { put_remove_model(lat_deg:lat_deg, lon_deg:lon_deg, elev_m:alt_m, time_sec:time_sec4, startSize_m: nil, endSize_m:nil, path:fp4 )} , time_sec+time_sec2+time_sec3);
  
  }

}
###############################################################################
# Utility functions

# Set up aTransfer fluid between two properties without losing or creating any.
#  amount [lb]
#  rate   [lb/sec]
var SmoothTransfer = {
    # Set up a smooth value transfer between two properties.
    #  from, to       : property paths or property nodes
    #  rate           : units/sec. MUST be positive.
    #  amount         : the amount to transfer. MUST be positive.
    #  stop_at_zero   : stop if the from property reaches 0.0.
    new: func(from, to, rate, amount=-1, stop_at_zero=1) {
        var m = { parents: [SmoothTransfer] };
        m.from         = aircraft.makeNode(from);
        m.to           = aircraft.makeNode(to);
        m.left         = amount;
        m.rate         = rate;
        m.stop_at_zero = stop_at_zero;
        m.last_time    = getprop("/sim/time/elapsed-sec");
        settimer(func{ m._loop_(); }, 0.0);
        return m;
    },
    stop: func {
        me.left = 0.0;
    },
    _loop_: func() {
        var t = getprop("/sim/time/elapsed-sec");
        var a = me.rate * (t - me.last_time);
        a = (a < me.left) ? a : me.left;
        if (me.stop_at_zero) {
            var f = me.from.getValue();
            a = (a < f) ? a : f;
        }
        me.from.setValue(f - a);
        me.to.setValue(me.to.getValue() + a);
        me.left -= a;
        me.last_time = t;
        if (me.left > 0.0) {
            settimer(func{ me._loop_(); }, 0.0);
        }
    }
};

###############################################################################
# fake part of the electrical system.
var fake_electrical = func {
#    setprop("systems/electrical/ac-volts", 24);
#    setprop("systems/electrical/volts", 24);

#    setprop("/systems/electrical/outputs/comm[0]", 24.0);
#    setprop("/systems/electrical/outputs/comm[1]", 24.0);
#    setprop("/systems/electrical/outputs/nav[0]", 24.0);
#    setprop("/systems/electrical/outputs/nav[1]", 24.0);
#    setprop("/systems/electrical/outputs/dme", 24.0);
#    setprop("/systems/electrical/outputs/adf", 24.0);
#    setprop("/systems/electrical/outputs/transponder", 24.0);
#    setprop("/systems/electrical/outputs/instrument-lights", 24.0);
#    setprop("/systems/electrical/outputs/gps", 24.0);
#    setprop("/systems/electrical/outputs/efis", 24.0);

#    setprop("/instrumentation/clock/flight-meter-hour",0);

    var beacon_switch =
        props.globals.initNode("controls/lighting/beacon", 1, "BOOL");
    var beacon = aircraft.light.new("sim/model/lights/beacon",
                                    [0.05, 1.2],
                                    "/controls/lighting/beacon");
    var strobe_switch =
        props.globals.initNode("controls/lighting/strobe", 1, "BOOL");
    var strobe = aircraft.light.new("sim/model/lights/strobe",
                                    [0.05, 3],
                                    "/controls/lighting/strobe");
}
###############################################################################

###########################################################################
## MP integration of user's fixed local mooring locations.
## NOTE: Should this be here or elsewhere?
#settimer(func { mp_network_init(1); }, 0.1);

###############################################################################
# About dialog.

var ABOUT_DLG = 0;

var dialog = {
#################################################################
    init : func (x = nil, y = nil) {
        me.x = x;
        me.y = y;
        me.bg = [0, 0, 0, 0.3];    # background color
        me.fg = [[1.0, 1.0, 1.0, 1.0]]; 
        #
        # "private"
        me.title = "About";
        me.dialog = nil;
        me.namenode = props.Node.new({"dialog-name" : me.title });
    },
#################################################################
    create : func {
        if (me.dialog != nil)
            me.close();

        me.dialog = gui.Widget.new();
        me.dialog.set("name", me.title);
        if (me.x != nil)
            me.dialog.set("x", me.x);
        if (me.y != nil)
            me.dialog.set("y", me.y);

        me.dialog.set("layout", "vbox");
        me.dialog.set("default-padding", 0);

        var titlebar = me.dialog.addChild("group");
        titlebar.set("layout", "hbox");
        titlebar.addChild("empty").set("stretch", 1);
        titlebar.addChild("text").set
            ("label",
             "About");
        var w = titlebar.addChild("button");
        w.set("pref-width", 16);
        w.set("pref-height", 16);
        w.set("legend", "");
        w.set("default", 0);
        w.set("key", "esc");
        w.setBinding("nasal", "SL20.dialog.destroy(); ");
        w.setBinding("dialog-close");
        me.dialog.addChild("hrule");

        var content = me.dialog.addChild("group");
        content.set("layout", "vbox");
        content.set("halign", "center");
        content.set("default-padding", 5);
        props.globals.initNode("sim/about/text",
             "Schuette-Lanz SL 20 airship for FlightGear\n" ~
             "Copyright (C) 2017  Franz Schmid\n\n" ~
             "Copyright (C) 2010 - 2016  Anders Gidenstam\n\n" ~
             "FlightGear flight simulator\n" ~
             "Copyright (C) 1996 - 2016  http://www.flightgear.org\n\n" ~
             "This is free software, and you are welcome to\n" ~
             "redistribute it under certain conditions.\n" ~
             "See the GNU GENERAL PUBLIC LICENSE Version 2 for the details.",
             "STRING");
        var text = content.addChild("textbox");
        text.set("halign", "fill");
        #text.set("slider", 20);
        text.set("pref-width", 400);
        text.set("pref-height", 300);
        text.set("editable", 0);
        text.set("property", "sim/about/text");

        #me.dialog.addChild("hrule");

        fgcommand("dialog-new", me.dialog.prop());
        fgcommand("dialog-show", me.namenode);
    },
#################################################################
    close : func {
        fgcommand("dialog-close", me.namenode);
    },
#################################################################
    destroy : func {
        ABOUT_DLG = 0;
        me.close();
        delete(gui.dialog, "\"" ~ me.title ~ "\"");
    },
#################################################################
    show : func {
        if (!ABOUT_DLG) {
            ABOUT_DLG = 1;
            me.init(400, getprop("/sim/startup/ysize") - 500);
            me.create();
        }
    }
};
###############################################################################

# Popup the about dialog.
var about = func {
    dialog.show();
}
###############################################################################
## Ground party.

var ground_crew = {
    ##################################################
    init : func {
        me.UPDATE_INTERVAL = 0.42;
        me.loopid = 0;
        # There are two handling guy parties.
        me.position = geo.aircraft_position();
        me.pos = [geo.aircraft_position(), geo.aircraft_position()];
        me.connected =
            [props.globals.getNode
             ("/fdm/jsbsim/landing-party/wire-connected[0]"),
             props.globals.getNode
             ("/fdm/jsbsim/landing-party/wire-connected[1]")];
        me.wire_length =
            props.globals.getNode("/fdm/jsbsim/landing-party/wire-length-ft");
        me.model = {local : [nil, nil]};
        me.wind_heading =
            props.globals.getNode("/environment/wind-from-heading-deg");
        me.active = 0;

#        if (props.globals.getNode("/sim/presets/onground").getValue()) {
            me.active = 1;
            me.connected[0].setValue(0.99);
            me.connected[1].setValue(0.99);
#        }
        me.reset();
        print("Ground crew ... Standing by.");
    },
    ##################################################
    # Place the ground crew.
    place_ground_crew : func (pos, heading=nil, altitude=nil, name="local") {
        if (heading == nil) {
            me.heading = me.wind_heading.getValue();
        } else {
            me.heading = heading;
        }
        me.position = pos;
        me.pos[0].set(pos);
        me.pos[1].set(pos);
        me.pos[0].apply_course_distance(me.heading - 45.0, 20.0);
        me.pos[1].apply_course_distance(me.heading + 45.0, 20.0);
        if (altitude == nil) {
            me.pos[0].set_alt(geodinfo(me.pos[0].lat(), me.pos[0].lon())[0]);
            me.pos[1].set_alt(geodinfo(me.pos[1].lat(), me.pos[1].lon())[0]);
        } else {
            me.pos[0].set_alt(altitude);
            me.pos[1].set_alt(altitude);
        }  
        print("ground_crew: Handling parties at ");
        me.pos[0].dump(); me.pos[1].dump();

        setprop("/fdm/jsbsim/landing-party/latitude-deg[0]", me.pos[0].lat());
        setprop("/fdm/jsbsim/landing-party/longitude-deg[0]", me.pos[0].lon());
        setprop("/fdm/jsbsim/landing-party/altitude-ft[0]",
                me.pos[0].alt() * M2FT);
        setprop("/fdm/jsbsim/landing-party/latitude-deg[1]", me.pos[1].lat());
        setprop("/fdm/jsbsim/landing-party/longitude-deg[1]", me.pos[1].lon());
        setprop("/fdm/jsbsim/landing-party/altitude-ft[1]",
                me.pos[1].alt() * M2FT);
    
        if (me.model.local[0] != nil) me.model.local[0].remove();
        if (me.model.local[1] != nil) me.model.local[1].remove();
        me.model.local[0] = geo.put_model
            (getprop("/sim/aircraft-dir") ~ "/Models/GroundCrew/wire-party.xml",
             me.pos[0], me.heading + 135.0);
        me.model.local[1] = geo.put_model
            (getprop("/sim/aircraft-dir") ~ "/Models/GroundCrew/wire-party.xml",
             me.pos[1], me.heading - 135.0);
        broadcast.send(message_id["place_ground_crew"] ~
                       Binary.encodeCoord(me.pos[0]) ~
                       Binary.encodeCoord(me.pos[1]) ~
                       Binary.encodeDouble(me.heading));
    },
    ##################################################
    place_remote_ground_crew : func (key, pos1, pos2, heading) {
        if (!contains(me.model, key)) me.model[key] = [nil, nil];

        if (me.model[key][0] != nil) me.model[key][0].remove();
        if (me.model[key][1] != nil) me.model[key][1].remove();
        me.model[key][0] = geo.put_model
            (getprop("/sim/aircraft-dir") ~ "/Models/GroundCrew/wire-party.xml",
             pos1, heading + 135.0);
        me.model[key][1] = geo.put_model
            (getprop("/sim/aircraft-dir") ~ "/Models/GroundCrew/wire-party.xml",
             pos2, heading - 135.0);
    },
    ##################################################
    remove_remote_ground_crew : func (key) {
        if (!contains(me.model, key)) return;
        if (me.model[key][0] != nil) me.model[key][0].remove();
        if (me.model[key][1] != nil) me.model[key][1].remove();
    },
    ##################################################
    let_go : func {
        if (me.connected[0].getValue() or me.connected[1].getValue())
            me.announce("Handling guys released!");
        me.active = 0;
        me.connected[0].setValue(0.0);
        me.connected[1].setValue(0.0);
        me.wire_length.setValue(650.0);
    },
    ##################################################
    activate : func {
        me.active = 1;
        me.wire_length.setValue(650.0);
        me.place_ground_crew(me.position);
        me.announce("Ready for landing!");
    },
    ##################################################
    announce : func(msg) {
        setprop("/sim/messages/ground", msg);
    },
    ##################################################
    update : func {
        if (!me.active) return;
        
        if ((me.connected[0].getValue() < 1.0) and
            (getprop("/fdm/jsbsim/landing-party/total-distance-ft[0]") <
             2.0*getprop("/fdm/jsbsim/landing-party/wire-length-ft"))) {
            me.connected[0].setValue(1.0);
            me.announce("Left handling guy secured!");
        }
        if ((me.connected[1].getValue() < 1.0) and
            (getprop("/fdm/jsbsim/landing-party/total-distance-ft[1]") <
             2.0*getprop("/fdm/jsbsim/landing-party/wire-length-ft"))) {
            me.connected[1].setValue(1.0);
            me.announce("Right handling guy secured!");
        }
        if ((me.connected[0].getValue() >= 0.99) and
            (me.connected[1].getValue() >= 0.99) and
            (me.wire_length.getValue() == 650.0)) {
            interpolate(me.wire_length, 40.0, 30.0);
        }
    },
    ##################################################
    reset : func {
        me.loopid += 1;
        me._loop_(me.loopid);
    },
    ##################################################
    _loop_ : func(id) {
        id == me.loopid or return;
        me.update();
        settimer(func { me._loop_(id); }, me.UPDATE_INTERVAL);
    }
};

setlistener("/sim/signals/fdm-initialized", func {
    ground_crew.init();
    ground_crew.place_ground_crew(geo.aircraft_position(),
                                  getprop("/orientation/heading-deg"));

    setlistener("/sim/signals/click", func {
        var click_pos = geo.click_position();
        if (__kbd.ctrl.getBoolValue()) {
            SL20.ground_crew.place_ground_crew(click_pos,
                                                         nil,
                                                         click_pos.alt());
        }
    });
});

var weather_dialog = gui.Dialog.new("/sim/gui/dialogs/sl20/weather/dialog", "Aircraft/SL20/Dialogs/weather-report.xml");
var autopilot_dialog = gui.Dialog.new("sim/gui/dialogs/autopilot/dialog", "Aircraft/SL20/Dialogs/autopilot.xml");

