import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:telenant/models/chatmodel.dart';
import 'package:telenant/models/model.dart';

class FirebaseFirestoreService {
  FirebaseFirestoreService._();
  static final instance = FirebaseFirestoreService._();
  Stream<QuerySnapshot<Object?>> readItems() {
    try {
      return FirebaseFirestore.instance
          .collection('transientDetails')
          .snapshots();
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }

  Stream<QuerySnapshot<Object?>> retrieveChatMessages(String name) {
    try {
      return FirebaseFirestore.instance
          .collection("chatMessage")
          .doc(name)
          .collection('messages')
          .orderBy('timepressed')
          .snapshots();
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }

  Stream<QuerySnapshot<Object?>> readFeedbacks() {
    try {
      return FirebaseFirestore.instance.collection('feedbacks').snapshots();
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }

  sendChatMessages(String name, String email, MessageModel message) {
    try {
      return FirebaseFirestore.instance
          .collection("chatMessage")
          .doc(name)
          .collection('messages')
          .doc()
          .set(message.toJson());
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }

  addTransient(details detail) {
    try {
      return FirebaseFirestore.instance
          .collection("transientDetails")
          .doc()
          .set(detail.toJson());
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }
}
