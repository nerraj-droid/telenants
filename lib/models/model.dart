// ignore: camel_case_types
class details {
  String? name;
  String? location;
  String? coverPage;
  String? bedrooms;
  PriceRange? priceRange;
  LocationLatLng? locationLatLng;
  List<dynamic>? gallery;
  String? contact;
  String? type;
  String? website;
  String? managedBy;
  String? docId;

  details(
      {this.name,
      this.location,
      this.coverPage,
      this.bedrooms,
      this.priceRange,
      this.locationLatLng,
      this.gallery,
      this.contact,
      this.type,
      this.managedBy,
      this.website,
      this.docId});

  details.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    location = json['location'];
    coverPage = json['cover_page'];
    bedrooms = json['bedrooms'];
    priceRange = (json['price_range'] != null
        ? PriceRange.fromJson(json['price_range'])
        : null)!;
    locationLatLng = (json['location_latlng'] != null
        ? LocationLatLng.fromJson(json['location_latlng'])
        : null)!;
    gallery = json['gallery'];
    contact = json['contact'];
    type = json['type'];
    website = json['website'];
    managedBy = json['managedBy'];
    docId = json['docId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['location'] = location;
    data['cover_page'] = coverPage;
    data['bedrooms'] = bedrooms;
    if (priceRange != null) {
      data['price_range'] = priceRange!.toJson();
    }
    if (locationLatLng != null) {
      data['location_latlng'] = locationLatLng!.toJson();
    }
    data['gallery'] = gallery;
    data['contact'] = contact;
    data['type'] = type;
    data['managedBy'] = managedBy;
    data['website'] = website;
    data['docId'] = docId;
    return data;
  }
}

class PriceRange {
  int? min;
  int? max;

  PriceRange({this.min, this.max});

  PriceRange.fromJson(Map<String, dynamic> json) {
    min = json['min'];
    max = json['max'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['min'] = min;
    data['max'] = max;
    return data;
  }
}

class LocationLatLng {
  double? latitude;
  double? longitude;

  LocationLatLng({this.latitude, this.longitude});

  LocationLatLng.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude'];
    longitude = json['longitude'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = <String, dynamic>{};
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    return data;
  }
}
