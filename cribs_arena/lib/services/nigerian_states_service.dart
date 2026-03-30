class NigerianStatesService {
  static final List<Map<String, String>> states = [
    {'title': 'Lagos', 'subtitle': 'Ikeja'},
    {'title': 'Abuja', 'subtitle': 'FCT'},
    {'title': 'Delta', 'subtitle': 'Asaba'},
    {'title': 'Rivers', 'subtitle': 'Port Harcourt'},
    {'title': 'Abia', 'subtitle': 'Umuahia'},
    {'title': 'Adamawa', 'subtitle': 'Yola'},
    {'title': 'Akwa Ibom', 'subtitle': 'Uyo'},
    {'title': 'Anambra', 'subtitle': 'Awka'},
    {'title': 'Bauchi', 'subtitle': 'Bauchi'},
    {'title': 'Bayelsa', 'subtitle': 'Yenagoa'},
    {'title': 'Benue', 'subtitle': 'Makurdi'},
    {'title': 'Borno', 'subtitle': 'Maiduguri'},
    {'title': 'Cross River', 'subtitle': 'Calabar'},
    {'title': 'Ebonyi', 'subtitle': 'Abakaliki'},
    {'title': 'Edo', 'subtitle': 'Benin City'},
    {'title': 'Ekiti', 'subtitle': 'Ado Ekiti'},
    {'title': 'Enugu', 'subtitle': 'Enugu'},
    {'title': 'Gombe', 'subtitle': 'Gombe'},
    {'title': 'Imo', 'subtitle': 'Owerri'},
    {'title': 'Jigawa', 'subtitle': 'Dutse'},
    {'title': 'Kaduna', 'subtitle': 'Kaduna'},
    {'title': 'Kano', 'subtitle': 'Kano'},
    {'title': 'Katsina', 'subtitle': 'Katsina'},
    {'title': 'Kebbi', 'subtitle': 'Birnin Kebbi'},
    {'title': 'Kogi', 'subtitle': 'Lokoja'},
    {'title': 'Kwara', 'subtitle': 'Ilorin'},
    {'title': 'Nasarawa', 'subtitle': 'Lafia'},
    {'title': 'Niger', 'subtitle': 'Minna'},
    {'title': 'Ogun', 'subtitle': 'Abeokuta'},
    {'title': 'Ondo', 'subtitle': 'Akure'},
    {'title': 'Osun', 'subtitle': 'Oshogbo'},
    {'title': 'Oyo', 'subtitle': 'Ibadan'},
    {'title': 'Plateau', 'subtitle': 'Jos'},
    {'title': 'Sokoto', 'subtitle': 'Sokoto'},
    {'title': 'Taraba', 'subtitle': 'Jalingo'},
    {'title': 'Yobe', 'subtitle': 'Damaturu'},
    {'title': 'Zamfara', 'subtitle': 'Gusau'},
  ];

  /// Get all Nigerian states
  static List<Map<String, String>> getAllStates() {
    return states;
  }

  /// Search states by query
  static List<Map<String, String>> searchStates(String query) {
    if (query.isEmpty) {
      return states;
    }

    final queryLower = query.toLowerCase();
    return states.where((state) {
      final titleLower = state['title']!.toLowerCase();
      final subtitleLower = state['subtitle']!.toLowerCase();
      return titleLower.contains(queryLower) ||
          subtitleLower.contains(queryLower);
    }).toList();
  }

  /// Get state by title
  static Map<String, String>? getStateByTitle(String title) {
    try {
      return states.firstWhere(
        (state) => state['title']!.toLowerCase() == title.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get total number of states
  static int get totalStates => states.length;
}
