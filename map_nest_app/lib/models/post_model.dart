class PostModel {
  final String id;
  final String contactName;
  final List<String> contactNumbers; // Changed to support multiple phone numbers
  final List<String> imageUrls;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String type; // "rent" or "sold"
  final String propertyType; // "Land(Vacant Land/Land Only)", "Apartment(Condo)", "Apartment(HDB)", "Land with house"
  final String address; // Address of the property
  final String remark; // Optional remarks
  final String price; // Price of the property
  final String entranceWidth; // Entrance width of the property
  final String long; // Length of the property
  final String township; // Township of the property
  final String city; // City of the property
  final String street; // Street of the property

  PostModel({
    required this.id,
    required this.contactName,
    required this.contactNumbers,
    required this.imageUrls,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.type,
    required this.propertyType,
    this.address = '',
    this.remark = '',
    this.price = '',
    this.entranceWidth = '',
    this.long = '',
    this.township = '',
    this.city = '',
    this.street = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contactName': contactName,
      'contactNumbers': contactNumbers,
      'imageUrls': imageUrls,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'type': type,
      'propertyType': propertyType,
      'address': address,
      'remark': remark,
      'price': price,
      'entranceWidth': entranceWidth,
      'long': long,
      'township': township,
      'city': city,
      'street': street,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    // Handle both old format (single imageUrl) and new format (imageUrls list)
    List<String> images = [];
    if (map['imageUrls'] != null) {
      images = List<String>.from(map['imageUrls']);
    } else if (map['imageUrl'] != null) {
      // Backward compatibility with old single image format
      images = [map['imageUrl']];
    }

    // Handle both old format (single contactNumber) and new format (contactNumbers list)
    List<String> phoneNumbers = [];
    if (map['contactNumbers'] != null) {
      phoneNumbers = List<String>.from(map['contactNumbers']);
    } else if (map['contactNumber'] != null) {
      // Backward compatibility with old single phone number format
      phoneNumbers = [map['contactNumber']];
    }

    return PostModel(
      id: map['id'] ?? '',
      contactName: map['contactName'] ?? '',
      contactNumbers: phoneNumbers,
      imageUrls: images,
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      type: map['type'] ?? 'rent', // Default to 'rent' for backward compatibility
      propertyType: map['propertyType'] ?? 'Apartment(Condo)', // Default for backward compatibility
      address: map['address'] ?? '',
      remark: map['remark'] ?? '',
      price: map['price'] ?? '',
      entranceWidth: map['entranceWidth'] ?? '',
      long: map['long'] ?? '',
      township: map['township'] ?? '',
      city: map['city'] ?? '',
      street: map['street'] ?? '',
    );
  }
}
