import 'package:cribs_arena/screens/notification/notifications_screen.dart';
import 'package:cribs_arena/screens/saved/agent.dart';
import 'package:cribs_arena/screens/saved/property.dart';
import 'package:flutter/material.dart';
// Added for the header font
import 'package:cribs_arena/models/property.dart';
import 'package:cribs_arena/services/saved_property_service.dart';
import 'package:cribs_arena/models/agent.dart';
import 'package:cribs_arena/services/saved_agent_service.dart';
import 'package:cribs_arena/screens/schedule/schedule_screen.dart';
import 'package:cribs_arena/screens/components/modern_header.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import '../../constants.dart';

import 'package:cribs_arena/screens/saved/components/saved_tab_bar.dart';

class SavedPropertyScreen extends StatefulWidget {
  const SavedPropertyScreen({super.key});

  @override
  State<SavedPropertyScreen> createState() => _SavedPropertyScreenState();
}

class _SavedPropertyScreenState extends State<SavedPropertyScreen> {
  int _selectedTabIndex = 0;

  List<Property> _savedProperties = [];
  bool _isLoadingProperties = true;
  String _propertiesError = '';

  List<Agent> _savedAgents = [];
  bool _isLoadingAgents = true;
  String _agentsError = '';

  final SavedPropertyService _savedPropertyService = SavedPropertyService();
  final SavedAgentService _savedAgentService = SavedAgentService();

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await Future.wait([
      _fetchSavedProperties(),
      _fetchSavedAgents(),
    ]);
  }

  Future<void> _fetchSavedProperties() async {
    setState(() {
      _isLoadingProperties = true;
      _propertiesError = '';
    });
    try {
      final apiResponse = await _savedPropertyService.getSavedProperties();
      final fetchedProperties = apiResponse.data;
      setState(() {
        _savedProperties = fetchedProperties;
        _isLoadingProperties = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _propertiesError = getErrorMessage(e);
          _isLoadingProperties = false;
        });
      }
    }
  }

  Future<void> _fetchSavedAgents() async {
    setState(() {
      _isLoadingAgents = true;
      _agentsError = '';
    });
    try {
      final agents = await _savedAgentService.getSavedAgents();
      setState(() {
        _savedAgents = agents;
        _isLoadingAgents = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _agentsError = getErrorMessage(e);
          _isLoadingAgents = false;
        });
      }
    }
  }

  Future<void> _removeProperty(Property property) async {
    try {
      await _savedPropertyService.unsaveProperty(property.propertyId);
      setState(() {
        _savedProperties
            .removeWhere((p) => p.propertyId == property.propertyId);
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: Column(
          children: [
            ModernHeader(
              title: 'Saved',
              onCalendarPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyScheduleScreen(),
                  ),
                );
              },
              onNotificationPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            Expanded(
              child: CustomRefreshIndicator(
                onRefresh: _fetchAll,
                child: Column(
                  children: [
                    SavedTabBar(
                      selectedIndex: _selectedTabIndex,
                      onTabSelected: (index) {
                        setState(() {
                          _selectedTabIndex = index;
                        });
                      },
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: kPaddingAll16,
                          child: _selectedTabIndex == 0
                              ? AgentTab(
                                  agents: _savedAgents,
                                  isLoading: _isLoadingAgents,
                                  error: _agentsError,
                                  onRefresh: _fetchAll,
                                )
                              : PropertyTab(
                                  properties: _savedProperties,
                                  isLoading: _isLoadingProperties,
                                  error: _propertiesError,
                                  onRemove: _removeProperty,
                                  onRefresh: _fetchAll,
                                ),
                        ),
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
