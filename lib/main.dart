import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ButtonPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ButtonPage extends StatefulWidget {
  @override
  _ButtonPageState createState() => _ButtonPageState();
}

class _ButtonPageState extends State<ButtonPage> {
  List<Contact> selectedContacts = [];

  void navigateToContactsPage(BuildContext context) async {
    final result = await Navigator.push<List<Contact>>(
      context,
      MaterialPageRoute(
        builder: (context) => ContactsPage(selectedContacts: selectedContacts),
      ),
    );

    if (result != null) {
      setState(() {
        selectedContacts = result;
      });
    }
  }

  void removeContact(Contact contact) {
    setState(() {
      selectedContacts.remove(contact);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "***  App Name  ***",
          style: TextStyle(color: Colors.blue),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => navigateToContactsPage(context),
            child: Text('Open Contacts'),
          ),
          SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: selectedContacts.length,
              itemBuilder: (context, index) {
                final contact = selectedContacts[index];
                Uint8List? image = contact.photo;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: image != null
                          ? MemoryImage(image)
                          : AssetImage('assets/avatar_placeholder.png')
                              as ImageProvider,
                    ),
                    title: Text(
                      "${contact.displayName}",
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        removeContact(contact);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ContactsPage extends StatefulWidget {
  final List<Contact> selectedContacts;

  const ContactsPage({Key? key, required this.selectedContacts})
      : super(key: key);

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact>? contacts;
  List<bool>? checkedContacts;
  List<Contact> selectedContacts = [];
  List<int> selectedIndices = [];
  String searchQuery = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getContact(); // Move getContact call here
  }

  void getContact() async {
    setState(() {
      isLoading = true;
    });

    if (await FlutterContacts.requestPermission()) {
      contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
      print(contacts);
      checkedContacts = List<bool>.filled(contacts!.length, false);
      selectedContacts = widget.selectedContacts;
      selectedIndices = selectedContacts
          .map((contact) =>
              contacts!.indexWhere((c) => c.displayName == contact.displayName))
          .toList();
      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Contact> getFilteredContacts() {
    if (searchQuery.isEmpty) {
      return contacts ?? [];
    } else {
      return contacts?.where((contact) {
            final fullName = contact.displayName.toLowerCase();
            return fullName.contains(searchQuery.toLowerCase());
          }).toList() ??
          [];
    }
  }

  void toggleSelection(int index) {
    setState(() {
      if (!selectedIndices.contains(index)) {
        selectedIndices.add(index);
        selectedContacts.add(contacts![index]);
      } else {
        selectedIndices.remove(index);
        selectedContacts.remove(contacts![index]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredContacts = getFilteredContacts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredContacts.isEmpty
                    ? Center(child: Text('No contacts found'))
                    : ListView.builder(
                        itemCount: filteredContacts.length,
                        itemBuilder: (BuildContext context, int index) {
                          final contact = filteredContacts[index];
                          Uint8List? image = contact.photo;
                          String num = contact.phones.isNotEmpty
                              ? contact.phones.first.number
                              : "--";
                          final isSelected = selectedIndices.contains(index);

                          return ListTile(
                            leading: contact.photo == null
                                ? const CircleAvatar(child: Icon(Icons.person))
                                : CircleAvatar(
                                    backgroundImage: MemoryImage(image!),
                                  ),
                            title: Text(
                              "${contact.displayName}",
                            ),
                            subtitle: Text(num),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                toggleSelection(index);
                              },
                            ),
                            enabled: !isSelected,
                          );
                        },
                      ),
          ),
          if (selectedContacts.isNotEmpty) ...[
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedContacts),
              child: Text('OK'),
            ),
          ],
        ],
      ),
    );
  }
}
