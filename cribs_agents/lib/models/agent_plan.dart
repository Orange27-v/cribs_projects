class AgentPlan {
  final int id;
  final String name;
  final int propertyLimit;
  final double price;
  final String description;
  final List<String> features;

  AgentPlan({
    required this.id,
    required this.name,
    required this.propertyLimit,
    required this.price,
    required this.description,
    required this.features,
  });

  factory AgentPlan.fromJson(Map<String, dynamic> json) {
    return AgentPlan(
      id: json['plan_id'] is int
          ? json['plan_id']
          : int.parse(json['plan_id'].toString()),
      name: json['name'],
      propertyLimit: json['property_limit'] is int
          ? json['property_limit']
          : int.parse(json['property_limit'].toString()),
      price: json['price'] is double
          ? json['price']
          : double.parse(json['price'].toString()),
      description: json['description'] ?? '',
      features:
          json['features'] != null ? List<String>.from(json['features']) : [],
    );
  }
}
