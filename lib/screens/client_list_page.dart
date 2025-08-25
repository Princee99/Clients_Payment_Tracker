import 'package:flutter/material.dart';
import '../models/client.dart';
import 'add_edit_client_page.dart';
import 'client_ledger_screen.dart';
import 'dart:convert';
import '../config.dart';
import '../services/base_service.dart';

class ClientListPage extends StatefulWidget {
  @override
  _ClientListPageState createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  List<Client> clients = [];
  List<Client> filteredClients = [];
  TextEditingController searchController = TextEditingController();
  
  
  Future<void> fetchClientsFromBackend() async {
    try {
      final response = await BaseService.authenticatedGet('http://$ip/backend/clients.php');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            clients = List<Client>.from(
              data['data'].map((c) => Client.fromJson(c)),
            );
            _filterClients();
          });
        } else {
          print('Error fetching clients: ${data['message']}');
        }
      } else {
        print('Server error: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error fetching clients: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchClientsFromBackend();
    searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterClients() {
    setState(() {
      if (searchController.text.isEmpty) {
        // If search is empty, show all clients
        filteredClients = List.from(clients);
      } else {
        // Filter clients locally based on search text
        filteredClients =
            clients.where((client) {
              final searchLower = searchController.text.toLowerCase();
              return client.name.toLowerCase().contains(searchLower) ||
                  client.phone.contains(searchController.text);
            }).toList();
      }
    });
  }

  

  void addClient(Client client) async {
    try {
      print("Adding client: ${client.toJson()}");
      
      final response = await BaseService.authenticatedPost(
        'http://$ip/backend/clients.php',
        body: client.toJson(),
      );

      print("Response status: ${response.statusCode}");
      print("Response headers: ${response.headers}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/json')) {
          final data = json.decode(response.body);
          if (data['success']) {
            setState(() {
              clients.add(
                Client(
                  id: data['id'],
                  name: client.name,
                  phone: client.phone,
                  address: client.address,
                ),
              );
              _filterClients();
            });
          } else {
            print("Add failed: ${data['message']}");
          }
        } else {
          print("Invalid JSON response:\n${response.body}");
        }
      } else {
        print("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception during addClient: $e");
    }
  }

  void editClient(int index, Client client) async {
    try {
      final response = await BaseService.authenticatedPut(
        'http://$ip/backend/clients.php',
        body: client.toJson(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            clients[index] = client;
            _filterClients();
          });
        } else {
          print('Error updating client: ${data['message']}');
        }
      } else {
        print('Server error: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Exception during editClient: $e');
    }
  }

  void deleteClient(int clientId) async {
    try {
      final response = await BaseService.authenticatedDelete(
        'http://$ip/backend/clients.php?id=$clientId',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            clients.removeWhere((c) => c.id == clientId);
            filteredClients.removeWhere((c) => c.id == clientId);
          });
        } else {
          print('Error deleting client: ${data['message']}');
        }
      } else {
        print('Server error: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Exception during deleteClient: $e');
    }
  }

  void navigateToAddClient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditClientPage()),
    );
    if (result != null) addClient(result);
  }

  void navigateToEditClient(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditClientPage(client: clients[index]),
      ),
    );
    if (result != null) editClient(index, result);
  }

  void _navigateToLedger(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClientLedgerScreen(client: client)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Client Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone...',
                    prefixIcon: Icon(Icons.search, color: Colors.teal[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.teal[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.teal[600]!,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                // Count Header
                Row(
                  children: [
                    Icon(Icons.people_alt, size: 18, color: Colors.teal[600]),
                    SizedBox(width: 6),
                    Text(
                      'Clients: ${filteredClients.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: fetchClientsFromBackend,
                      icon: Icon(Icons.refresh, color: Colors.teal[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Client List
          Expanded(
            child: filteredClients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          clients.isEmpty
                              ? 'No clients added yet.'
                              : 'No clients found matching your search.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchClientsFromBackend,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(16),
                      itemCount: filteredClients.length,
                      itemBuilder: (context, index) {
                        final client = filteredClients[index];
                        final initial = client.name.isNotEmpty
                            ? client.name[0].toUpperCase()
                            : '?';
                        return Card(
                          elevation: 3,
                          shadowColor: Colors.grey.withOpacity(0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: EdgeInsets.only(bottom: 14),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.teal[100],
                                  child: Text(
                                    initial,
                                    style: TextStyle(
                                      color: Colors.teal[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        client.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              client.phone,
                                              style: TextStyle(color: Colors.grey[700]),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              client.address,
                                              style: TextStyle(color: Colors.grey[700]),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.blue[50],
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: Icon(
                                              Icons.account_balance_wallet,
                                              color: Colors.blue[700],
                                              size: 18,
                                            ),
                                            onPressed: () => _navigateToLedger(client),
                                            tooltip: 'View Ledger',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.teal[50],
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: Icon(
                                              Icons.edit,
                                              color: Colors.teal[700],
                                              size: 18,
                                            ),
                                            onPressed: () => navigateToEditClient(clients.indexOf(client)),
                                            tooltip: 'Edit',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.red[50],
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red[600],
                                              size: 18,
                                            ),
                                            onPressed: () => deleteClient(client.id!),
                                            tooltip: 'Delete',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAddClient,
        backgroundColor: Colors.teal,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
