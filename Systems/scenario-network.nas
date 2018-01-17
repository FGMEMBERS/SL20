###############################################################################
##
## Submarine Scout airship
##
##  Copyright (C) 2007 - 2013  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license v2 or later.
##
###############################################################################

var Binary = nil;
var broadcast = nil;
var message_id = nil;
var Ppilot = nil;
###############################################################################
# MP broadcast message handler.
var handle_message = func (sender, msg) {
#    debug.dump(msg);
    if (size(msg) == 0) return;
    var type = msg[0];
#    print("Message from "~ sender.getNode("callsign").getValue() ~ " size: " ~ size(msg) ~ " Type: " ~ type);
    if (type == message_id["bomb_impact"][0])
    {
        var pos = Binary.decodeCoord(substr(msg, 1));
        geo.put_model("Aircraft/SL20/Models/crater.xml", pos.lat(), pos.lon(), pos.alt() + 0.1, 0, 0, 0);
        geo.put_model("Aircraft/SL20/Models/bombe.xml", pos.lat(), pos.lon(), pos.alt() + 0.25, 0, 0, 0);
        start_terrain_fire(pos.lat(), pos.lon(), pos.alt() + 0.25, 230);
    }
    if (type == message_id["place_ground_crew"][0])
    {
        SL20.ground_crew.place_remote_ground_crew(sender.getPath(),
             Binary.decodeCoord(substr(msg, 1)),
             Binary.decodeCoord(substr(msg, 1 + Binary.sizeOf["Coord"])),
             Binary.decodeDouble(substr(msg, 1 + 2 * Binary.sizeOf["Coord"])));
    }
    if (type == message_id["drop_water"][0])
    {
       var n = Binary.decodeByte(substr(msg, 1));
       var val = Binary.decodeInt(substr(msg, 1 + Binary.sizeOf["byte"]));
       setprop(Ppilot ~ "/controls/ballast/action[" ~ n ~ "]", val);
    }
    if (type == message_id["drop_bombs"][0])
    {
       setprop(Ppilot ~ "/sim/weapons/bomb[0]/dropped", Binary.decodeByte(substr(msg, 1)));
       setprop(Ppilot ~ "/sim/weapons/bomb[1]/dropped", Binary.decodeByte(substr(msg, 1 + Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[2]/dropped", Binary.decodeByte(substr(msg, 1 + 2 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[3]/dropped", Binary.decodeByte(substr(msg, 1 + 3 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[4]/dropped", Binary.decodeByte(substr(msg, 1 + 4 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[5]/dropped", Binary.decodeByte(substr(msg, 1 + 5 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[6]/dropped", Binary.decodeByte(substr(msg, 1 + 6 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[7]/dropped", Binary.decodeByte(substr(msg, 1 + 7 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[8]/dropped", Binary.decodeByte(substr(msg, 1 + 8 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[9]/dropped", Binary.decodeByte(substr(msg, 1 + 9 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[10]/dropped", Binary.decodeByte(substr(msg, 1 + 10 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[11]/dropped", Binary.decodeByte(substr(msg, 1 + 11 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[12]/dropped", Binary.decodeByte(substr(msg, 1 + 12 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[13]/dropped", Binary.decodeByte(substr(msg, 1 + 13 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[14]/dropped", Binary.decodeByte(substr(msg, 1 + 14 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[15]/dropped", Binary.decodeByte(substr(msg, 1 + 15 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[16]/dropped", Binary.decodeByte(substr(msg, 1 + 16 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[17]/dropped", Binary.decodeByte(substr(msg, 1 + 17 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[18]/dropped", Binary.decodeByte(substr(msg, 1 + 18 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[19]/dropped", Binary.decodeByte(substr(msg, 1 + 19 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[20]/dropped", Binary.decodeByte(substr(msg, 1 + 20 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[21]/dropped", Binary.decodeByte(substr(msg, 1 + 21 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[22]/dropped", Binary.decodeByte(substr(msg, 1 + 22 * Binary.sizeOf["byte"])));
       setprop(Ppilot ~ "/sim/weapons/bomb[23]/dropped", Binary.decodeByte(substr(msg, 1 + 23 * Binary.sizeOf["byte"])));
    }
}

###############################################################################
# MP Accept and disconnect handlers.
var listen_to = func (pilot) {
    if (pilot.getNode("sim/model/path") != nil and
        streq("Aircraft/SL20/Models/SL20.xml",
              pilot.getNode("sim/model/path").getValue())) {
    #    print("Accepted " ~ pilot.getPath());
        Ppilot = pilot.getPath();
        return 1;
    } else {
#        print("Rejected " ~ pilot.getPath());
        return 0;
    }
}

var when_disconnecting = func (pilot) {
    SL20.ground_crew.remove_remote_ground_crew(pilot.getPath());
}

###############################################################################
# Minimal ground_crew replacement.
var remote_ground_crew = {
    ##################################################
    init : func {
        me.model = {};
        me.model_path =
            me.find_model_path("SL20/Models/GroundCrew/wire-party.xml");
    },
    ##################################################
    place_remote_ground_crew : func (key, pos1, pos2, heading) {
        if (!contains(me.model, key)) me.model[key] = [nil, nil];

        if (me.model[key][0] != nil) me.model[key][0].remove();
        if (me.model[key][1] != nil) me.model[key][1].remove();
        me.model[key][0] = geo.put_model
            (me.model_path,
             pos1, heading + 135.0);
        me.model[key][1] = geo.put_model
            (me.model_path,
             pos2, heading - 135.0);
    },
    ##################################################
    remove_remote_ground_crew : func (key) {
        if (!contains(me.model, key)) return;
        if (me.model[key][0] != nil) me.model[key][0].remove();
        if (me.model[key][1] != nil) me.model[key][1].remove();
    },
    ##################################################
    # filename should include the aircraft's directory.
    find_model_path : func (filename) {
        # FIXME WORKAROUND: Search for the model in all aircraft dirs.
        var base = "/" ~ filename;
        var file = props.globals.getNode("/sim/fg-root").getValue() ~
            "/Aircraft" ~ base;
        if (io.stat(file) != nil) {
            return file;
        }
        foreach (var d;
                 props.globals.getNode("/sim").getChildren("fg-aircraft")) {
            file = d.getValue() ~ base;
            if (io.stat(file) != nil) {
                return file;
            }
        }
    }
};
remote_ground_crew.init();

###############################################################################
# Initialization.
var scenario_network_init = func (active_participant=0) {
    Binary = mp_broadcast.Binary;
    broadcast =
        mp_broadcast.BroadcastChannel.new("sim/multiplay/generic/string[0]", handle_message,
             0,
             listen_to,
             when_disconnecting,
             active_participant);
    # Set up the recognized message types.
    message_id = { bomb_impact       : Binary.encodeByte(1),
                   place_ground_crew : Binary.encodeByte(2),
                   drop_water        : Binary.encodeByte(3),
                   drop_bombs        : Binary.encodeByte(4)
                  };
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
var start_terrain_fire = func ( lat_deg, lon_deg, alt_m=0, ballisticMass_lb=1.2 )
{
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
  time_sec=75; 
  fp1="Aircraft/SL20/Models/bombable/Fire-Particles/fire-particles-large.xml";
  put_remove_model(lat_deg:lat_deg, lon_deg:lon_deg, elev_m:alt_m, time_sec:time_sec, startSize_m: nil, endSize_m:nil, path:fp1 );
  time_sec1=300; 
  fp="Aircraft/SL20/Models/bombable/Fire-Particles/smoke-particles-large.xml";
  put_remove_model(lat_deg:lat_deg, lon_deg:lon_deg, elev_m:alt_m, time_sec:time_sec1, startSize_m: nil, endSize_m:nil, path:fp );
  ##put it out, but slowly, for large impacts
  if (ballisticMass_lb>50)
  {
    time_sec2=75; fp2="Aircraft/SL20/Models/bombable/Fire-Particles/fire-particles-very-small.xml";  
    settimer (func { put_remove_model(lat_deg:lat_deg, lon_deg:lon_deg, elev_m:alt_m, time_sec:time_sec2, startSize_m: nil, endSize_m:nil, path:fp2 )} , time_sec);
    
    time_sec3=75; fp3="Aircraft/SL20/Models/bombable/Fire-Particles/fire-particles-very-very-small.xml";  
    settimer (func { put_remove_model(lat_deg:lat_deg, lon_deg:lon_deg, elev_m:alt_m, time_sec:time_sec3, startSize_m: nil, endSize_m:nil, path:fp3 )} , time_sec+time_sec2);
    
    time_sec4=75; fp4="Aircraft/SL20/Models/bombable/Fire-Particles/fire-particles-very-very-very-small.xml";  
    settimer (func { put_remove_model(lat_deg:lat_deg, lon_deg:lon_deg, elev_m:alt_m, time_sec:time_sec4, startSize_m: nil, endSize_m:nil, path:fp4 )} , time_sec+time_sec2+time_sec3);
  
  }

}

