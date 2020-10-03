import 'package:flare_flutter/flare.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flutter/material.dart';
import "package:flutter_compass/flutter_compass.dart";
import 'package:geolocator/geolocator.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  AnimController _animController;
  double direction = 0;

  @override
  void initState() {
    _animController = AnimController(
        animationName: "animation1", min: 0, max: 360, speed: 45);

    FlutterCompass.events.listen((event) {
      setState(() {
        if (event == null) {
          direction = 0;
          _fetchPermissionStatus();
        } else {
          direction = event;
        }
        _animController.value = direction;
      });
    });

    super.initState();
  }

  void _getLocationByGPS() {
    getPositionStream(desiredAccuracy: LocationAccuracy.high, distanceFilter: 0)
        .listen((Position position) {
      setState(() {
        direction = position.heading;
        _animController.value = direction;
      });
    });
  }

  void _fetchLocationServiceStatus() async {
    await isLocationServiceEnabled().then((status) {
      if (status) {
        setState(() {
          _getLocationByGPS();
        });
      } else {
        openLocationSettings().then((_status) {
          _fetchLocationServiceStatus();
        });
      }
    });
  }

  int breaker = 0;
  void _fetchPermissionStatus() async {
    breaker++;
    await checkPermission().then((status) {
      if (status == LocationPermission.denied ||
          status == LocationPermission.deniedForever) {
        requestPermission().then((value) {
          if (value == LocationPermission.deniedForever) {
            openAppSettings();
            setState(() {});
          }
          if (breaker < 5) {
            _fetchPermissionStatus();
          }
        });
      } else {
        setState(() {
          _fetchLocationServiceStatus();
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: screenSize.height * .2,
            ),
            Container(
              height: screenSize.height * .5,
              color: Colors.black,
              child: Center(
                  child: Container(
                child: FlareActor(
                  "assets/flare/Compass12.flr",
                  animation: "animation1",
                  controller: _animController,
                ),
              )),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      " ${direction.toInt()}\u00B0",
                      style: TextStyle(fontSize: 40, color: Colors.white),
                    ),
                    Center(
                      child: Text(
                        _dirString(direction),
                        style: TextStyle(fontSize: 30, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        color: Colors.black,
      ),
    );
  }

// ignore: missing_return
  String _dirString(double dirn) {
    if (dirn >= 0 && dirn <= 22.5) {
      return "North";
    } else if (dirn > 22.5 && dirn <= 67.5) {
      return "North-East";
    } else if (dirn > 67.5 && dirn <= 112.5) {
      return "East";
    } else if (dirn > 112.5 && dirn <= 157.5) {
      return "South-East";
    } else if (dirn > 157.5 && dirn <= 202.5) {
      return "South";
    } else if (dirn > 202.5 && dirn <= 247.5) {
      return "South-West";
    } else if (dirn > 247.5 && dirn <= 292.5) {
      return "West";
    } else if (dirn > 292.5 && dirn <= 337.5) {
      return "North-West";
    } else if (dirn > 337.5 && dirn <= 360) {
      return "North";
    }
  }
}

class AnimController extends FlareController {
  String animationName;

  AnimController({this.animationName, this.min, this.max, this.speed});
  ActorAnimation actor;
  double _value = 0, min, max, speed, pos = 0;

  set value(double v) => _value = (v - min) / (max - min);

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    var d = (pos - _value).abs();
    var m = pos > _value ? -1 : 1;
    if (d > 0.5) {
      m = -m;
      d = 1.0 - d;
    }
    var e = elapsed / actor.duration * (1 + d * speed);
    pos = e < d ? (pos + e * m) : _value;
    pos %= 1.0;
    actor.apply(actor.duration * pos, artboard, 1.0);
    return true;
  }

  @override
  void initialize(FlutterActorArtboard artboard) {
    actor = artboard.getAnimation(animationName);
  }

  @override
  void setViewTransform(Mat2D viewTransform) {}
}
