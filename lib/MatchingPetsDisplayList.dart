import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'DetailsPetScreenView.dart';
import 'HomeScreen.dart';

class MatchingPetsDisplayList extends StatefulWidget {
  final List<Map<String, dynamic>> similarPets;

  MatchingPetsDisplayList({required this.similarPets});

  @override
  _MatchingPetsDisplayListState createState() =>
      _MatchingPetsDisplayListState();
}

class _MatchingPetsDisplayListState extends State<MatchingPetsDisplayList> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pets Encontrados'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(),
              ),
            );
          },
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
            if (widget.similarPets.isNotEmpty)
              CarouselSlider(
                items: widget.similarPets.map((similarPet) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailsPetScreenView(petData: similarPet),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.all(8.0),
                      child: Column(
                        children: <Widget>[
                          Image.network(similarPet['photo']),
                          Text(
                            "${similarPet['name'] != null && similarPet['name'].isNotEmpty ? 'Nome: ' + similarPet['name'] : 'Sem Nome'}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                options: CarouselOptions(
                  height: 600,
                  enlargeCenterPage: false,
                  aspectRatio: 16 / 9,
                  viewportFraction: 0.8,
                  initialPage: 0,
                  autoPlay: true,
                  autoPlayInterval: Duration(seconds: 3),
                  autoPlayAnimationDuration: Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                ),
              )
            else
              Container(
                height: 600,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/background_padrao.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Nenhuma imagem disponível',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.similarPets.asMap().entries.map((entry) {
                final int index = entry.key;
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: EdgeInsets.symmetric(horizontal: 2.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPage
                        ? Colors.brown[900]
                        : Colors.brown[100],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
