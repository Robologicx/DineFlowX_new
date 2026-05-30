// import 'package:cloud_firestore/cloud_firestore.dart';

// // Firestore Data Shape
// // Role Doc Example (hotels/{hotelId}/roles/{roleId}):
// // {
// //   "name": "Manager",
// //   "permissions": ["manage_employees", "view_reports", "approve_expenses"]
// // }

// // User Doc Example (hotels/{hotelId}/users/{userId}):
// // {
// //   "name": "Ali Khan",
// //   "roles": ["manager"],
// //   "extraPermissions": ["override_discount"]
// // }
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:hotel_management_system/data/repositories/business_repository.dart';
// import '../models/role_model.dart';
// import '../models/permission_model.dart';

// class RolePermissionRepository {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   // final String _hotelId;

//   // RolePermissionRepository({required String hotelId}) : _hotelId = hotelId;

//   // CollectionReference<Object?> get _productsRef => FirebaseFirestore.instance
//   //     .collection('hotels')
//   //     .doc(_hotelId)
//   //     .collection('branches')
//   //     .doc(BusinessRepository.branchId)
//   //     .collection('products');

//   /// Reference for roles collection in a hotel
//   CollectionReference<Map<String, dynamic>> rolesRef(
//     String hotelId,
//     String businessId,
//   ) {
//     return _firestore
//         .collection('businesses')
//         .doc(hotelId)
//         .collection('branches')
//         .doc(businessId)
//         .collection('roles');
//   }

//   /// Reference for users collection in a hotel
//   DocumentReference<Map<String, dynamic>> userRef(
//     String businessId,
//     String branchId,
//     String userId,
//   ) {
//     return _firestore
//         .collection('businesses')
//         .doc(businessId)
//         .collection('branches')
//         .doc(branchId)
//         .collection('users')
//         .doc(userId);
//   }

//   // ==========================
//   // ROLE MANAGEMENT
//   // ==========================

//   Future<void> createRole(String hotelId, String roleId, RoleModel role) async {
//     await rolesRef(hotelId).doc(roleId).set(role.toMap());
//   }

//   Future<RoleModel?> getRoleById(String hotelId, String roleId) async {
//     final doc = await rolesRef(hotelId).doc(roleId).get();
//     if (!doc.exists) return null;
//     return RoleModel.fromMap(doc.data()!);
//   }

//   Future<List<RoleModel>> getAllRoles(String hotelId) async {
//     final snapshot = await rolesRef(hotelId).get();
//     return snapshot.docs.map((doc) => RoleModel.fromMap(doc.data()!)).toList();
//   }

//   Future<void> updateRole(
//     String hotelId,
//     String roleId,
//     RoleModel updatedRole,
//   ) async {
//     await rolesRef(hotelId).doc(roleId).update(updatedRole.toMap());
//   }

//   Future<void> deleteRole(String hotelId, String roleId) async {
//     await rolesRef(hotelId).doc(roleId).delete();
//   }

//   // ==========================
//   // PERMISSION MANAGEMENT
//   // ==========================

//   Future<void> addPermissionToRole(
//     String hotelId,
//     String roleId,
//     PermissionModel permission,
//   ) async {
//     await rolesRef(hotelId).doc(roleId).update({
//       'permissions': FieldValue.arrayUnion([permission.toMap()]),
//     });
//   }

//   Future<void> removePermissionFromRole(
//     String hotelId,
//     String roleId,
//     PermissionModel permission,
//   ) async {
//     await rolesRef(hotelId).doc(roleId).update({
//       'permissions': FieldValue.arrayRemove([permission.toMap()]),
//     });
//   }

//   Future<List<PermissionModel>> getPermissions(
//     String hotelId,
//     String roleId,
//   ) async {
//     final role = await getRoleById(hotelId, roleId);
//     return role?.permissions ?? [];
//   }

//   // ==========================
//   // USER ROLE ASSIGNMENT
//   // ==========================

//   Future<void> assignRoleToUser(
//     String hotelId,
//     String userId,
//     String roleId,
//   ) async {
//     await userRef(hotelId, userId).update({
//       'roles': FieldValue.arrayUnion([roleId]),
//     });
//   }

//   Future<void> removeRoleFromUser(
//     String hotelId,
//     String userId,
//     String roleId,
//   ) async {
//     await userRef(hotelId, userId).update({
//       'roles': FieldValue.arrayRemove([roleId]),
//     });
//   }

//   Future<RoleModel> getUserRole(String hotelId, String userId) async {
//     final userDoc = await userRef(hotelId, userId).get();
//     return RoleModel.fromFirestore(userDoc.data()?['role']);
//   }

//   // ==========================
//   // EXTRA PERMISSIONS
//   // ==========================

//   Future<void> grantExtraPermission(
//     String hotelId,
//     String userId,
//     PermissionModel permission,
//   ) async {
//     await userRef(hotelId, userId).update({
//       'extraPermissions': FieldValue.arrayUnion([permission.toMap()]),
//     });
//   }

//   Future<void> revokeExtraPermission(
//     String hotelId,
//     String userId,
//     PermissionModel permission,
//   ) async {
//     await userRef(hotelId, userId).update({
//       'extraPermissions': FieldValue.arrayRemove([permission.toMap()]),
//     });
//   }

//   Future<List<PermissionModel>> getUserExtraPermissions(
//     String hotelId,
//     String userId,
//   ) async {
//     final userDoc = await userRef(hotelId, userId).get();
//     final extraPermissions =
//         (userDoc.data()?['extraPermissions'] as List<dynamic>?)
//             ?.map((p) => PermissionModel.fromFirestore(p))
//             .toList() ??
//         [];
//     return extraPermissions;
//   }

//   // ==========================
//   // ACCESS CONTROL CHECK
//   // ==========================

//   // Future<bool> hasPermission(
//   //   String hotelId,
//   //   String userId,
//   //   PermissionModel permission,
//   // ) async {
//   //   final userDoc = await userRef(hotelId, userId).get();
//   //   final data = userDoc.data();

//   //   if (data == null) return false;

//   //   final roles = (data['roles'] as List<dynamic>?)?.cast<String>() ?? [];

//   //   final extraPermissions =
//   //       (data['extraPermissions'] as List<dynamic>?)
//   //           ?.map((p) => PermissionModel.fromFirestore(p))
//   //           .toList() ??
//   //       [];

//   //   // Check extra permissions first
//   //   if (extraPermissions.any((perm) => perm.id == permission.id)) return true;

//   //   // Check roles
//   //   for (final roleId in roles) {
//   //     final rolePerms = await getPermissions(hotelId, roleId);
//   //     if (rolePerms.any((perm) => perm.id == permission)) return true;
//   //   }

//   //   return false;
//   // }
// }
