import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telenant/FirebaseServices/services.dart';
import 'package:telenant/authentication/login.dart';
import 'package:telenant/home/admin/addtransient.dart';
import 'package:telenant/home/components/near_me_widgets.dart';
import 'package:telenant/home/filtered.dart';
import 'package:telenant/home/searchbox.dart';
import 'package:telenant/home/transients_list.dart';
import 'package:telenant/utils/filter_transients.dart';
import 'package:textfield_search/textfield_search.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedValue = 'Near Town';
  int min = 200;
  int max = 10000;
  int currentPageIndex = 0;
  IconLabel? selectedIcon;
  late Future<List<Map<String, dynamic>>> _nearbyApartments;
  List propertyTypes = [];
  final TextEditingController _roomTypeController = TextEditingController();
  final TextEditingController _roomBedsController = TextEditingController();
  final TextEditingController _roomNumberController = TextEditingController();
  List<String> listOfPriceValue = [
    '200',
    '300',
    '400',
    '500',
    '1000',
    '2000',
    '3000',
    '5000',
    '10000'
  ];
  late TextEditingController searchController;
  bool fetchingLocation = false;

  List<PropertyType> propertyTypeList = [
    PropertyType(
      type: 'Townhouse',
      asset: 'assets/images/townhouse.png',
    ),
    PropertyType(
      type: 'Apartment',
      asset: 'assets/images/apartment.png',
    ),
  ];
  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  // @override
  // void dispose() {
  //   searchController.dispose();
  //   super.dispose();
  // }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('userEmail');
  }

  Future<void> _fetchNearbyApartments(LocationData location) async {
    try {
      _nearbyApartments = findNearbyApartments(location,
          100000); //km-m; 1000m = 1km; therefore here it is set to 100km radius
      _nearbyApartments.then((value) {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return NearMeWidget(
            data: value,
          );
        }));
        setState(() {
          fetchingLocation = false;
        });
      }).onError((error, stackTrace) {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text(error.toString()),
              );
            });
        setState(() {
          fetchingLocation = false;
        });
      });
      //display a alertdialog for error
    } catch (e) {
      print('Error getting location or apartments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            onPressed: () {
              showDialog(
                  context: context,
                  //barrierDismissible: false,
                  builder: ((context) {
                    return AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        ElevatedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              logout();
                              Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: ((context) =>
                                          const LoginPage())));
                            },
                            child: const Text('Yes'))
                      ],
                    );
                  }));
            },
            icon: const Icon(Icons.logout, color: Colors.black87)),
        title: const Text(
          'Filter',
          style: TextStyle(color: Colors.black87),
        ),
        actions: const [],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
            if (index == 1) {
              _selectedValue = 'Near Town';
            }
          });
          if (index == 0) {
            searchController = TextEditingController();
          }
        },
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_rounded),
            label: 'Profile',
          ),
        ],
      ),
      body: currentPageIndex == 0 ? homeWidget() : profileWidget(),
    );
  }

  //a column of profile page that displays id number and email, reading from the function readUserDetails
  Padding profileWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(
            height: 20,
          ),
          const Text(
            'Profile',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 20,
          ),
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestoreService.instance
                .getUserDetails(FirebaseAuth.instance.currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                Map<String, dynamic> data =
                    snapshot.data!.data() as Map<String, dynamic>;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    profileCard('ID Number: ${data['idNumber']}'),
                    profileCard('Email: ${data['email']}'),
                  ],
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ],
      ),
    );
  }

  Card profileCard(String data) {
    return Card(
      child: ListTile(
        title: Text(
          data,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  SingleChildScrollView homeWidget() {
    return SingleChildScrollView(
      child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestoreService.instance.readItems(),
            builder: ((context, snapshot) {
              List<String> listOfValue = ['Near Town'];
              List<String> listOfTransient = [];
              if (snapshot.hasData) {
                for (final detail in snapshot.data!.docs) {
                  if (!listOfValue.contains(detail['location'])) {
                    listOfValue.add(detail['location']);
                  }
                  listOfTransient.add(detail['name']);
                }
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Available Locations',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  DropdownButtonFormField(
                      decoration: InputDecoration(
                          focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black38)),
                          labelText: 'Select Location',
                          labelStyle: const TextStyle(color: Colors.black87),
                          border: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  width: 1.5, color: Colors.black38),
                              borderRadius: BorderRadius.circular(10.0))),
                      value: _selectedValue,
                      isExpanded: true,
                      isDense: true,
                      items: listOfValue.map((String val) {
                        return DropdownMenuItem(
                          value: val,
                          child: Row(
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width - 100,
                                child: Text(
                                  val,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedValue = value.toString();
                        });
                      }),
                  const Padding(padding: EdgeInsets.all(4)),
                  Center(
                    child: fetchingLocation
                        ? const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Fetching Current Location'),
                              LinearProgressIndicator(),
                            ],
                          )
                        : ElevatedButton.icon(
                            onPressed: () async {
                              setState(() {
                                fetchingLocation = true;
                              });
                              Location location = Location();
                              bool serviceEnabled;
                              PermissionStatus permissionGranted;
                              LocationData locationData;
                              serviceEnabled = await location.serviceEnabled();
                              if (!serviceEnabled) {
                                serviceEnabled =
                                    await location.requestService();
                                if (!serviceEnabled) {
                                  return;
                                }
                              }

                              permissionGranted =
                                  await location.hasPermission();
                              if (permissionGranted ==
                                  PermissionStatus.denied) {
                                permissionGranted =
                                    await location.requestPermission();
                                if (permissionGranted !=
                                    PermissionStatus.granted) {
                                  return;
                                }
                              }

                              locationData = await location.getLocation();
                              await _fetchNearbyApartments(locationData);
                            },
                            label: const Text('Near Me'),
                            style: ElevatedButton.styleFrom(
                                elevation: 3.0,
                                fixedSize: const Size(double.maxFinite, 50),
                                shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary),
                                    borderRadius: BorderRadius.circular(10))),
                            icon: const Icon(Icons.location_on),
                          ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Property Types',
                        style: TextStyle(
                            fontSize: 25, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          height: 270,
                          width: MediaQuery.of(context).size.width,
                          child: GridView.builder(
                            itemCount: propertyTypeList.length,
                            scrollDirection: Axis.horizontal,
                            // physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 1, childAspectRatio: 0.85),
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap: () {
                                  if (propertyTypeList[index].type ==
                                      'Apartment') {
                                    if (propertyTypes.contains(
                                        propertyTypeList[index].type)) {
                                      setState(() {
                                        propertyTypes.remove(
                                            propertyTypeList[index].type);
                                      });
                                    } else {
                                      setState(() {
                                        propertyTypes
                                            .add(propertyTypeList[index].type);
                                      });
                                    }
                                  } else if (propertyTypeList[index].type ==
                                      'Townhouse') {
                                    if (propertyTypes.contains(
                                        propertyTypeList[index].type)) {
                                      setState(() {
                                        propertyTypes.remove(
                                            propertyTypeList[index].type);
                                      });
                                    } else {
                                      setState(() {
                                        propertyTypes
                                            .add(propertyTypeList[index].type);
                                      });
                                    }
                                  }
                                },
                                child: cardPropertyType(
                                    context,
                                    propertyTypeList[index].type,
                                    propertyTypeList[index].asset),
                              );
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Room Details',
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownMenu<IconLabel>(
                                controller: _roomTypeController,
                                requestFocusOnTap: true,
                                label: const Text('Room Type'),
                                leadingIcon: selectedIcon == null
                                    ? null
                                    : Icon(selectedIcon!.icon),
                                onSelected: (IconLabel? icon) {
                                  setState(() {
                                    selectedIcon = icon;
                                  });
                                },
                                dropdownMenuEntries: IconLabel.entries,
                              ),
                            ),
                            const Padding(padding: EdgeInsets.all(4.0)),
                            IconLabel.allValues.indexOf(selectedIcon ??
                                        IconLabel.allValues.first) >
                                    2
                                ? Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _roomBedsController,
                                      keyboardType: TextInputType
                                          .number, // Numeric keyboard
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: '# of Beds',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink()
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextField(
                            controller: _roomNumberController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              labelText: '# of Rooms',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        'Price Range Per Head',
                        style: TextStyle(
                            fontSize: 25, fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 2.5,
                              child: DropdownButtonFormField(
                                  decoration: InputDecoration(
                                      focusedBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.black38)),
                                      contentPadding:
                                          const EdgeInsets.all(10.0),
                                      labelText: 'From',
                                      labelStyle: const TextStyle(
                                          color: Colors.black87),
                                      prefixIcon: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Php',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      border: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                              width: 1.5,
                                              color: Colors.black38),
                                          borderRadius:
                                              BorderRadius.circular(10.0))),
                                  value: '300',
                                  isExpanded: true,
                                  items: listOfPriceValue.map((String val) {
                                    return DropdownMenuItem(
                                      value: val,
                                      child: Row(
                                        children: [
                                          Text(
                                            val,
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      min = int.parse(value.toString());
                                    });
                                  }),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0, right: 8.0),
                              child: Text(
                                '-',
                                style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black26),
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 2.5,
                              child: DropdownButtonFormField(
                                  decoration: InputDecoration(
                                      focusedBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.black38)),
                                      contentPadding:
                                          const EdgeInsets.all(10.0),
                                      labelText: 'To',
                                      labelStyle: const TextStyle(
                                          color: Colors.black87),
                                      prefixIcon: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Php',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      border: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                              width: 1.5,
                                              color: Colors.black38),
                                          borderRadius:
                                              BorderRadius.circular(10.0))),
                                  value: '300',
                                  isExpanded: true,
                                  items: listOfPriceValue.map((String val) {
                                    return DropdownMenuItem(
                                      value: val,
                                      child: Row(
                                        children: [
                                          Text(
                                            val,
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      max = int.parse(value.toString());
                                    });
                                  }),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const Divider(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 45,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          const Text(
                            'Search by Name',
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: ((context) => Material(
                                child: SearchDemo(
                                  data: listOfTransient,
                                ),
                              ))));
                    },
                    child: TextFieldSearch(
                      label: 'Search',
                      controller: searchController,
                      initialList: listOfTransient,
                      decoration: const InputDecoration(
                          enabled: false,
                          contentPadding: EdgeInsets.all(15),
                          hintText: 'type in the transient name',
                          hintStyle: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                          ),
                          border: OutlineInputBorder()),
                    ),
                  ),
                  // const SizedBox(
                  //   height: 50,
                  // ),
                  ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward_ios_rounded),
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          fixedSize: const Size(double.maxFinite, 40)),
                      onPressed: () {
                        try {
                          Map<String, int> pricerange = {
                            'min': min,
                            'max': max,
                          };
                          Map<String, dynamic> filtered = {
                            'type': propertyTypes,
                            'location': _selectedValue,
                            'price': pricerange,
                            'numberofbeds': _roomBedsController.text,
                            'numberofrooms': _roomNumberController.text,
                            'roomType':
                                selectedIcon!.label.toString().toLowerCase(),
                          };
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: ((context) => ShowFiltered(
                                    filtered: filtered,
                                  ))));
                        } catch (e) {
                          // Navigator.of(context).push(MaterialPageRoute(
                          //     builder: ((context) =>
                          //         TransientsListUnauthenticated())));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Fields are empty!')));
                        }
                      },
                      label: const Text('Proceed')),
                ],
              );
            }),
          )),
    );
  }

  Card cardPropertyType(BuildContext context, String type, String asset) {
    return Card(
      shape: OutlineInputBorder(
          borderSide: BorderSide(
              width: 3.0,
              style: propertyTypes.contains(type)
                  ? BorderStyle.solid
                  : BorderStyle.none,
              color: Theme.of(context).colorScheme.primary)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              // width: 100,
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
              ),
            ),
            const Divider(),
            Text(
              type,
              style: Theme.of(context).textTheme.titleLarge,
            )
          ],
        ),
      ),
    );
  }

  Padding propertyType(IconData icon, String type) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (type == 'Apartment') {
                if (propertyTypes.contains(type)) {
                  setState(() {
                    propertyTypes.remove(type);
                  });
                } else {
                  setState(() {
                    propertyTypes.add(type);
                  });
                }
              } else if (type == 'Townhouse') {
                if (propertyTypes.contains(type)) {
                  setState(() {
                    propertyTypes.remove(type);
                  });
                } else {
                  setState(() {
                    propertyTypes.add(type);
                  });
                }
              } else if (type == 'Hotel') {
                if (propertyTypes.contains(type)) {
                  setState(() {
                    propertyTypes.remove(type);
                  });
                } else {
                  setState(() {
                    propertyTypes.add(type);
                  });
                }
              } else {
                if (propertyTypes.contains(type)) {
                  setState(() {
                    propertyTypes.remove(type);
                  });
                }
              }
            },
            child: Card(
              elevation: 5.0,
              shape: OutlineInputBorder(
                  borderSide: BorderSide(
                      width: 3.0,
                      style: propertyTypes.contains(type)
                          ? BorderStyle.solid
                          : BorderStyle.none,
                      color: Colors.blue)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.blue[800],
                ),
              ),
            ),
          ),
          Text(type)
        ],
      ),
    );
  }
}

class PropertyType {
  final String type;
  final String asset;

  PropertyType({required this.type, required this.asset});
}
