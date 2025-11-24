import 'package:flutter/material.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  void _onNavTap(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      // déjà sur messages
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/profile');
    } else if (index == 3) {
      // Navigation vers la page AddFriendsPage
      Navigator.pushReplacementNamed(context, '/addFriends');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Center(
          child: Text("Messages", style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.grey[900],
      ),
      body: const Center(
        child: Text(
          "Messages page (à implémenter)",
          style: TextStyle(fontSize: 18),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Onglet Message sélectionné
        onTap: (index) => _onNavTap(context, index),
        selectedItemColor: Colors.blue, // Couleur pour l'élément sélectionné
        unselectedItemColor: Color.fromARGB(
          255,
          73,
          73,
          73,
        ), // Couleur pour les éléments non sélectionnés
        backgroundColor: Colors.white, // Fond de la BottomNavigationBar
        type: BottomNavigationBarType
            .fixed, // Assurer que tous les textes soient visibles
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.post_add), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Add Friends', // L'élément pour "Add Friends"
          ),
        ],
      ),
    );
  }
}
