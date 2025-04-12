import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> openGoogleMaps(String latitude, String longitude) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        print('No app available to handle $url');
      }
    } catch (e) {
      print('Error launching URL:$e');
            }
        }

  final player = AudioPlayer();
  Set<String> alreadyPlayed = {}; //newly added


  Future<void> playSound() async {
    try {
      await player.play(
        AssetSource('audios/alert.mp3'),
      ); // Replace 'alert.mp3' with your audio file name
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nearby Accidents"), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('accidents').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            List documents = snapshot.data!.docs;
            print(documents.length.toString());
            if (documents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sentiment_satisfied_alt, size: 60, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      "No nearby accidents reported.",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final changes = snapshot.data!.docChanges;

            /*for (var change in changes) {
              if (change.type == DocumentChangeType.added) {
                playSound();
              }
            }*/

            for (var change in changes) {
              if (change.type == DocumentChangeType.added) {
                final docId = change.doc.id;
                if (!alreadyPlayed.contains(docId)) {
                  playSound();
                  alreadyPlayed.add(docId);
                }
              }
            }

            final firebaseFirestore = FirebaseFirestore.instance.collection(
              'accidents',
            );
            return ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                final docId = doc.id;
                final data = documents[index].data() as Map<String, dynamic>;
                return Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.place, color: Colors.red),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Lat: ${data['latitude']} | Lng: ${data['longitude']}",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.local_hospital, color: Colors.redAccent),
                            SizedBox(width: 6),
                            Text(
                              "Status: ${data['ambulance-status'].toString().toUpperCase()}",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 18, color: Colors.grey[700]),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Reported at: ${data['timestamp']}",
                                style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  if (data['ambulance-status'] == 'allocated') {
                                    await firebaseFirestore.doc(docId).update({
                                      'ambulance-status': 'Not allocated',
                                    });
                                  } else {
                                    await firebaseFirestore.doc(docId).update({
                                      'ambulance-status': 'allocated',
                                    });
                                  }
                                } catch (e) {
                                  print("Error updating ambulance status: $e");
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: data['ambulance-status'] == 'allocated'
                                    ? Colors.orangeAccent
                                    : Colors.lightBlueAccent,
                              ),
                              child: Text(
                                data['ambulance-status'] == 'allocated' ? "Cancel" : "Allocate",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),

                            ElevatedButton(
                              onPressed: () {
                                openGoogleMaps(
                                  data['latitude'].toString(),
                                  data['longitude'].toString(),
                                );
                              },
                              child: Text('Open maps'),
                            ),
                            ElevatedButton(
                              onPressed:
                                  data['ambulance-status'] == 'allocated'
                                      ? () async {
                                        try {
                                          await firebaseFirestore
                                              .doc(docId)
                                              .update({
                                                'ambulance-status': 'reached',
                                              });
                                          // Delay a bit before deleting (optional)
                                          await Future.delayed(Duration(seconds: 2));

                                          // Delete the document
                                          await firebaseFirestore.doc(docId).delete();
                                        } catch (e) {
                                          throw Exception();
                                        }
                                      }
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    data['ambulance-status'] == 'allocated' ||
                                            data['ambulance-status'] ==
                                                'allocate'
                                        ? Colors.green
                                        : Colors.white,
                              ),
                              child: Text("Reached"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return Center(child: Text('Something went wrong'));
        },
      ),
    );
  }
}
