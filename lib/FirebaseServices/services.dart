import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:telenant/models/chatmodel.dart';
import 'package:telenant/models/model.dart';

import '../models/RateModel.dart';

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

  Future<List<DocumentSnapshot>> getApartmentsFromFirestore() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('transientDetails').get();

    return querySnapshot.docs;
  }

  Stream<QuerySnapshot<Object?>> retrieveChatMessages(String name) {
    try {
      return FirebaseFirestore.instance
          .collection("chatMessaging")
          .doc(name)
          .collection('messages')
          .orderBy('timepressed')
          .snapshots();
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }

  Stream<QuerySnapshot<Object?>> testretrieveChatMessages(String name) {
    try {
      return FirebaseFirestore.instance
          .collection("chatMessaging")
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

  sendChatMessages(String name, MessageModel message) {
    try {
      return FirebaseFirestore.instance
          .collection("chatMessaging")
          .doc(name)
          .collection('messages')
          .doc()
          .set(message.toJson());
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }

  addTransient(Details detail) {
    try {
      return FirebaseFirestore.instance
          .collection("transientDetails")
          .doc()
          .set(detail.toJson());
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }

  addRating(RateModel detail) {
    try {
      return FirebaseFirestore.instance
          .collection("ratings")
          .doc()
          .set(detail.toJson());
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }

  addUserDetails(
      {required String uid,
      required String idType,
      required String idNumber,
      required String email}) {
    Map<String, dynamic> data = {
      "uid": uid,
      "idType": idType,
      "idNumber": idNumber,
      "email": email
    };
    try {
      return FirebaseFirestore.instance
          .collection("userDetails")
          .doc(uid)
          .set(data);
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }

  Future<Map<String, dynamic>> deleteDocument({required String docId}) async {
    try {
      await FirebaseFirestore.instance
          .collection('transientDetails')
          .doc(docId)
          .delete();
      return {'message': 'Transient Deleted!'};
    } catch (e) {
      return {'message': 'Error updating document $e'};
    }
  }

  //create a function that returns the data of userdetails based on passed uid
  Future<DocumentSnapshot<Object?>> getUserDetails(String uid) async {
    try {
      return await FirebaseFirestore.instance
          .collection("userDetails")
          .doc(uid)
          .get();
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }
}
