import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class RouteService {
  RouteService._();

  static final ValueNotifier<List<LatLng>> routePoints = ValueNotifier([]);

  static void updateRoute(List<LatLng> points) {
    routePoints.value = List.unmodifiable(points);
  }

  static void clearRoute() {
    routePoints.value = const [];
  }
}
