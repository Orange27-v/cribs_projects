import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';

class ContactPickerModal extends StatefulWidget {
  const ContactPickerModal({super.key});

  @override
  State<ContactPickerModal> createState() => _ContactPickerModalState();
}

class _ContactPickerModalState extends State<ContactPickerModal> {
  final List<Map<String, String>> _contacts = [
    {
      'name': 'John Doe',
      'phone': '+1234567890',
      'avatar': 'assets/images/agent1.jpg',
    },
    {
      'name': 'Jane Smith',
      'phone': '+0987654321',
      'avatar': 'assets/images/agent2.jpg',
    },
    {
      'name': 'Peter Jones',
      'phone': '+1122334455',
      'avatar': 'assets/images/agent3.jpg',
    },
    {
      'name': 'Mary Williams',
      'phone': '+5544332211',
      'avatar': 'assets/images/agent4.jpg',
    },
  ];

  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final filteredContacts = _contacts.where((contact) {
      return contact['name']!.toLowerCase().contains(_searchText.toLowerCase());
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: kRadius20Top,
          ),
          child: Column(
            children: [
              const Text(
                'Select Contact',
                style: TextStyle(
                  fontSize: kFontSize16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 80, // set height
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchText = value;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search contact',
                    prefixIcon: Icon(Icons.search),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 0,
                    ), // controls internal height
                    border: OutlineInputBorder(
                      borderRadius: kRadius12,
                      borderSide: BorderSide(color: kBorderGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: kRadius12,
                      borderSide: BorderSide(color: kPrimaryColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage(contact['avatar']!),
                      ),
                      title: Text(
                        contact['name']!,
                        style: const TextStyle(
                          fontSize: kFontSize12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        contact['phone']!,
                        style: const TextStyle(fontSize: kFontSize10),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: kBlack54,
                      ),
                      onTap: () {
                        Navigator.of(context).pop(contact);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
