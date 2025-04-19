import 'package:flutter/material.dart';
import 'package:keyvalut/views/Widgets/card_list_view.dart';
import 'package:keyvalut/views/textforms/card_input_form.dart';
import '../../data/database_helper.dart';
import '../Widgets/credentials_widget.dart';

class PaymentsTab extends StatelessWidget {
  const PaymentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'create',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CardInputForm(
                dbHelper: DatabaseHelper.instance,
                card: null, // Optional, passing null since we're adding a new card
              ),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
      body: CardListView(),
    );
  }
}
