import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FindMosqueScreen shows routes and green nearby mosque markers', () {
    final source = File(
      'lib/features/mosque/screens/find_mosque_screen.dart',
    ).readAsStringSync();

    expect(source, contains('maps.GoogleMap('));
    expect(source, contains('mapType: maps.MapType.normal'));
    expect(source, contains('onTap: _selectDestination'));
    expect(source, contains('_selectMosqueDestination'));
    expect(source, contains('consumeTapEvents: true'));
    expect(
      source,
      contains('onTap: () => unawaited(_selectMosqueDestination(mosque))'),
    );
    expect(source, contains('infoWindow: maps.InfoWindow('));
    expect(source, contains('selected_destination'));
    expect(source, contains('Selected location'));
    expect(source, contains('_destinationLabel'));
    expect(source, contains('polylines:'));
    expect(source, contains('directions/json'));
    expect(source, contains('_openSelectedNavigation'));
    expect(source, contains('defaultTargetPlatform'));
    expect(source, contains('TargetPlatform.iOS'));
    expect(source, contains('google.navigation:q='));
    expect(source, contains('comgooglemaps://?daddr='));
    expect(source, contains('mode=d'));
    expect(source, contains('Your location'));
    expect(source, contains('Drive'));
    expect(source, contains('Start'));
    expect(source, contains('Add stops'));
    expect(source, contains('Share'));
    expect(source, contains('Save'));
    expect(source, contains('_buildDirectionsHeader'));
    expect(source, contains('_buildRouteSummary'));
    expect(source, contains('MosqueService'));
    expect(source, contains('fetchNearbyMosques'));
    expect(source, contains('_loadNearbyMosques'));
    expect(source, contains('_buildMosqueMarker'));
    expect(source, contains('_createMosqueMarkerIcon'));
    expect(source, contains('_mosqueMarkerIcon'));
    expect(source, contains('Icons.mosque_rounded'));
    expect(source, contains('BitmapDescriptor.bytes'));
    expect(source, contains('Color(0xFF159447)'));
    expect(source, contains('mosque_'));
  });
}
