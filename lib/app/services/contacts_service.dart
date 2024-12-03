import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';

class ContactsService extends GetxService {
  final contacts = <Contact>[].obs;
  final isLoading = false.obs;
  final hasPermission = false.obs;

  Future<bool> requestPermission() async {
    try {
      final permission = await FlutterContacts.requestPermission();
      hasPermission.value = permission;
      return permission;
    } catch (e) {
      print('Erreur lors de la demande de permission: $e');
      return false;
    }
  }

  Future<void> loadContacts() async {
    if (!hasPermission.value) {
      final granted = await requestPermission();
      if (!granted) return;
    }

    try {
      isLoading.value = true;
      final allContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
      contacts.value = allContacts;
    } catch (e) {
      print('Erreur lors du chargement des contacts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Contact>> searchContacts(String query) async {
    if (query.isEmpty) return [];
    
    return contacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      final phones = contact.phones.map((p) => p.number).join(' ').toLowerCase();
      final searchQuery = query.toLowerCase();
      
      return name.contains(searchQuery) || phones.contains(searchQuery);
    }).toList();
  }
} 