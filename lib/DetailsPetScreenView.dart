import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'utils/DialogUtils.dart';

class DetailsPetScreenView extends StatefulWidget {
  final Map<String, dynamic> petData;

  DetailsPetScreenView({required this.petData});

  @override
  _DetailsPetScreenViewState createState() => _DetailsPetScreenViewState();
}

class _DetailsPetScreenViewState extends State<DetailsPetScreenView> {
  late GoogleMapController mapController;

  void _launchWhatsApp(String phone) async {
    final Uri url = Uri.parse('https://wa.me/$phone');

    try {
      await launchUrl(url);
    } catch (e) {
      DialogUtils.showErrorDialog(
          context, 'Você não tem Whats, ou o usuário não possui Whats');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double latitude = double.parse(widget.petData['latitude']);
    final double longitude = double.parse(widget.petData['longitude']);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Pet'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      margin: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          widget.petData['photo'],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Text(
                      "Quem localizou?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Usuário: ${widget.petData['person_name']}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _launchWhatsApp('${widget.petData['phone']}');
                      },
                      child: Text(
                        'Whats/Phone: ${widget.petData['phone']}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Local",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 300,
                      height: 300,
                      child: GoogleMap(
                        onMapCreated: (controller) {
                          mapController = controller;
                        },
                        initialCameraPosition: CameraPosition(
                          target: LatLng(latitude, longitude),
                          zoom: 15.0,
                        ),
                        markers: Set<Marker>.from([
                          Marker(
                            markerId: MarkerId('petLocation'),
                            position: LatLng(latitude, longitude),
                          ),
                        ]),
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
