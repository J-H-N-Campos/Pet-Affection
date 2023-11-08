import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'HomeScreen.dart';
import 'service/LostPetService.dart';
import 'utils/DialogUtils.dart';

class EditMapLocationForm extends StatefulWidget {
  final int id;
  final String latitude;
  final String longitude;

  const EditMapLocationForm({
    Key? key,
    required this.id,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  _EditMapLocationFormState createState() => _EditMapLocationFormState();
}

class _EditMapLocationFormState extends State<EditMapLocationForm> {
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  LatLng _markerPosition = LatLng(0, 0);
  late GoogleMapController mapController;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _initializeMarkerPosition();
  }

  void _initializeMarkerPosition() {
    _markerPosition = LatLng(
      double.parse(widget.latitude),
      double.parse(widget.longitude),
    );
    _latitudeController.text = widget.latitude;
    _longitudeController.text = widget.longitude;
  }

  void _onMarkerDragEnd(LatLng position) {
    setState(() {
      _markerPosition = position;
      _latitudeController.text = _markerPosition.latitude.toString();
      _longitudeController.text = _markerPosition.longitude.toString();
    });
  }

  Future<void> _submitForm() async {
    final latitude = _latitudeController.text;
    final longitude = _longitudeController.text;

    Map<String, dynamic> accountData = {
      'id': widget.id,
      'latitude': latitude,
      'longitude': longitude,
    };

    final lostPetService = LostPetService(
      accountData: accountData,
      context: context,
    );

    await lostPetService.updateLostPet(accountData);

    DialogUtils.showSuccessDialog(
      context,
      'Dados enviados com sucesso!',
      () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Editar Localização no Mapa'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 300,
              child: GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                  _initializeMarkerPosition();
                  _addMarker();
                },
                initialCameraPosition: CameraPosition(
                  target: _markerPosition,
                  zoom: 15.0,
                ),
                markers: markers,
                onLongPress: (LatLng newPosition) {
                  _onMarkerDragEnd(newPosition);
                },
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _latitudeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Latitude',
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.brown),
                ),
                labelStyle: TextStyle(color: Colors.brown),
              ),
              style: TextStyle(fontSize: 15),
              cursorColor: Colors.brown,
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _longitudeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Longitude',
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.brown),
                ),
                labelStyle: TextStyle(color: Colors.brown),
              ),
              style: TextStyle(fontSize: 15),
              cursorColor: Colors.brown,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _submitForm,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed)) {
                      return const Color.fromRGBO(188, 170, 164, 1);
                    }
                    return Colors.brown[600]!;
                  },
                ),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
              child: Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _addMarker() {
    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: _markerPosition,
          draggable: true,
          onDragEnd: _onMarkerDragEnd,
        ),
      );
    });
  }
}
