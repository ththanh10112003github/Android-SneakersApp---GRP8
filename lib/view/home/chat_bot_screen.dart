import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const botWelcome =
    "Hello! Welcome to Customer Care Service. Please provide details about your issue.";
final mainIssues = [
  "Order Issues",
  "Item Quality",
  "Payment Issues",
  "Style Suggestion",
  "Other"
];

final orderIssueSub = [
  "I didn't receive my parcel",
  "I want to cancel my order",
  "I want to return my order",
  "Package was damaged",
  "Other"
];

class Order {
  final String id;
  final String status;
  final String summary;
  final int items;
  final String thumbUrl;
  Order({
    required this.id,
    required this.status,
    required this.summary,
    required this.items,
    required this.thumbUrl,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class Message {
  final String text;
  final bool fromUser;
  final DateTime time;
  Message({required this.text, this.fromUser = false}) : time = DateTime.now();
}

class _ChatScreenState extends State<ChatScreen> {
  int step = 0;
  String? selectedMain;
  String? selectedSub;
  String? description;
  Order? selectedOrder;
  List<Message> messages = [];
  final TextEditingController _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    messages.add(Message(text: botWelcome, fromUser: false));
  }

  void addUserMessage(String text) {
    setState(() {
      messages.add(Message(text: text, fromUser: true));
    });
  }

  void addBotMessage(String text) {
    setState(() {
      messages.add(Message(text: text, fromUser: false));
    });
  }

  void goNext() async {
    if (step == 0 && selectedMain == null) return;
    if (step == 1 && selectedSub == null) return;
    if (step == 2 && (description == null || description!.isEmpty)) return;
    if (step == 3 && selectedOrder == null && selectedMain == "Order Issues") {
      return;
    }

    setState(() {
      if (step == 0) {
        addUserMessage("Issue selected: $selectedMain");
        step = 1;
        addBotMessage("Please specify details for: $selectedMain");
      } else if (step == 1) {
        addUserMessage("Detail: $selectedSub");
        step = 2;
        addBotMessage("Please describe your issue in a few words.");
      } else if (step == 2) {
        addUserMessage("Description: $description");
        if (selectedMain == "Order Issues") {
          step = 3;
          addBotMessage("Select one of your orders:");
        } else {
          step = 4;
          addBotMessage("Ready to submit your request.");
        }
      } else if (step == 3) {
        addUserMessage("Selected order: ${selectedOrder!.id}");
        step = 4;
        addBotMessage("Ready. Tap Submit to send your request.");
      } else if (step == 4) {
        submitRequest();
      }
    });
  }

  void submitRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      addBotMessage("Please log in first.");
      return;
    }

    final summary = {
      "userId": user.uid,
      "email": user.email ?? "",
      "issueType": selectedMain ?? "",
      "detail": selectedSub ?? "",
      "description": description ?? "",
      "orderId": selectedOrder?.id ?? "",
      "status": "pending",
      "createdAt": DateTime.now().toString(),
    };

    try {
      await FirebaseFirestore.instance
          .collection("SupportTickets")
          .add(summary);

      final summaryText = '''
📝 **Ticket Summary**
━━━━━━━━━━━━━━━
📂 Issue Type: ${summary['issueType']}
📦 Order ID: ${summary['orderId']}
💬 Detail: ${summary['detail']}
🖊️ Description: ${summary['description']}
''';
      addUserMessage(summaryText);
      addBotMessage(
          "✅ Thank you! Your ticket has been submitted successfully.");
    } on JsonUnsupportedObjectError catch (e) {
      addBotMessage("⚠️ Failed to send request: $e");
    }
  }

  void resetChat() {
    setState(() {
      step = 0;
      selectedMain = null;
      selectedSub = null;
      selectedOrder = null;
      description = null;
      _descCtrl.clear();
      messages.clear();
      messages.add(Message(text: botWelcome, fromUser: false));
    });
  }

  Widget buildMessage(Message m) {
    final align =
        m.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = m.fromUser ? Colors.blue : Colors.grey.shade200;
    final txtColor = m.fromUser ? Colors.white : Colors.black87;
    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(m.text, style: TextStyle(color: txtColor)),
        ),
      ],
    );
  }

  Widget buildIssuesStep() => _buildChipStep("What's your issue?", mainIssues,
      selectedMain, (v) => setState(() => selectedMain = v));

  Widget buildSubStep() {
    final list = selectedMain == "Order Issues"
        ? orderIssueSub
        : ["Product damaged", "Wrong size", "Other"];
    return _buildChipStep("Please choose details", list, selectedSub,
        (v) => setState(() => selectedSub = v));
  }

  Widget _buildChipStep(String title, List<String> list, String? selected,
      Function(String) onSel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: const EdgeInsets.all(12),
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold))),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: list.map((t) {
            final isSel = selected == t;
            return ChoiceChip(
              label: Text(t),
              selected: isSel,
              onSelected: (_) => onSel(t),
              selectedColor: Colors.blue,
              backgroundColor: Colors.white,
              shape: const StadiumBorder(
                  side: BorderSide(color: Colors.blueAccent)),
              labelStyle: TextStyle(
                color: isSel ? Colors.white : Colors.blueAccent,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget buildDescStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _descCtrl,
        decoration: InputDecoration(
          labelText: "Describe your issue...",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              setState(() {
                description = _descCtrl.text.trim();
              });
              goNext();
            },
          ),
        ),
        maxLines: 3,
      ),
    );
  }

  Future<List<Order>> fetchOrders(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Orders')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Order(
        id: data['orderId'] ?? '',
        status: data['status'] ?? '',
        summary: data['address'] ?? '',
        items: (data['items'] as List?)?.length ?? 0,
        thumbUrl: (data['items']?[0]?['productThumbnail'] ??
            "https://via.placeholder.com/80") as String,
      );
    }).toList();
  }

  Widget buildOrderStep() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<Order>>(
      future: fetchOrders(currentUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data!;
        if (orders.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("You don’t have any orders."),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text("Select one of your orders:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...orders.map((o) {
              final sel = selectedOrder?.id == o.id;
              return GestureDetector(
                onTap: () => setState(() => selectedOrder = o),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sel ? Colors.blue.shade50 : Colors.white,
                    border: Border.all(
                        color: sel ? Colors.blue : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Image.network(o.thumbUrl,
                          width: 56, height: 56, fit: BoxFit.cover),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text("Order ${o.id}\nStatus: ${o.status}"),
                      ),
                      Text(sel ? "✓" : "Select",
                          style: TextStyle(
                              color: sel ? Colors.blue : Colors.grey)),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget buildConfirmStep() => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text("Ready to submit your request."),
            if (selectedMain != null) Text("Issue: $selectedMain"),
            if (selectedSub != null) Text("Detail: $selectedSub"),
            if (description != null) Text("Desc: $description"),
            if (selectedOrder != null) Text("Order: ${selectedOrder!.id}"),
          ],
        ),
      );

  Widget buildBottomBar() {
    final label = step == 4 ? "Submit" : "Next";
    bool disabled = (step == 0 && selectedMain == null) ||
        (step == 1 && selectedSub == null) ||
        (step == 2 && (description == null || description!.isEmpty)) ||
        (step == 3 && selectedMain == "Order Issues" && selectedOrder == null);

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: disabled ? null : goNext,
              child: Text(label),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: resetChat,
            icon: const Icon(Icons.refresh),
            tooltip: "Restart chat",
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Bot"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length + 1,
              itemBuilder: (context, i) {
                if (i < messages.length) {
                  return buildMessage(messages[i]);
                } else {
                  return const SizedBox(height: 180);
                }
              },
            ),
          ),
          Container(
            color: Colors.grey.shade50,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (step == 0) buildIssuesStep(),
                if (step == 1) buildSubStep(),
                if (step == 2) buildDescStep(),
                if (step == 3) buildOrderStep(),
                if (step == 4) buildConfirmStep(),
              ],
            ),
          ),
          buildBottomBar(),
        ],
      ),
    );
  }
}
