// const { initializeApp } = require("firebase-admin/app");
// const {
//   getFirestore,
//   FieldValue,
//   Timestamp,
// } = require("firebase-admin/firestore");
// const {
//   onDocumentCreated,
//   onDocumentUpdated,
// } = require("firebase-functions/v2/firestore");
// const { logger } = require("firebase-functions");
// const geofire = require("geofire-common");

// initializeApp();

// const db = getFirestore();

// const MAX_MATCH_DISTANCE_KM = 8;
// const MAX_RIDER_MATCH_DISTANCE_KM = 5;
// const OFFER_EXPIRY_MINUTES = 2;

// // Rider fallback freshness windows
// const RIDER_LOCATION_FRESHNESS_WINDOWS_MINUTES = [5, 10, 30];

// /* -------------------------------------------------------------------------- */
// /*                              LAUNDRY MATCHING                              */
// /* -------------------------------------------------------------------------- */

// exports.offerLaundryOnBookingCreate = onDocumentCreated(
//   "bookings/{bookingId}",
//   async (event) => {
//     const snapshot = event.data;
//     if (!snapshot) return;

//     const bookingId = event.params.bookingId;
//     const booking = snapshot.data();

//     if (booking.status !== "awaiting_laundry_assignment") {
//       logger.info("Skipping create trigger. Booking not awaiting assignment.", {
//         bookingId,
//         status: booking.status,
//       });
//       return;
//     }

//     await offerLaundryForBooking(bookingId);
//   },
// );

// exports.reofferLaundryOnBookingUpdate = onDocumentUpdated(
//   "bookings/{bookingId}",
//   async (event) => {
//     const before = event.data?.before?.data();
//     const after = event.data?.after?.data();
//     const bookingId = event.params.bookingId;

//     if (!before || !after) return;

//     const statusChanged =
//       before.status !== after.status &&
//       after.status === "awaiting_laundry_assignment";

//     const offerExpired =
//       before.status === "offered_to_laundry" &&
//       after.status === "awaiting_laundry_assignment";

//     if (!statusChanged && !offerExpired) return;

//     const laundrySnapshot = getLaundrySnapshot(after);

//     if (laundrySnapshot.id) {
//       logger.info("Skipping re-offer because laundrySnapshot still exists.", {
//         bookingId,
//         laundryId: laundrySnapshot.id,
//       });
//       return;
//     }

//     await offerLaundryForBooking(bookingId);
//   },
// );

// exports.expireLaundryOffers = onDocumentUpdated(
//   "bookings/{bookingId}",
//   async (event) => {
//     const before = event.data?.before?.data();
//     const after = event.data?.after?.data();
//     const bookingId = event.params.bookingId;

//     if (!before || !after) return;
//     if (after.status !== "offered_to_laundry") return;

//     const offerExpiresAt = after.laundryOffer?.offerExpiresAt;
//     if (!offerExpiresAt || typeof offerExpiresAt.toDate !== "function") {
//       return;
//     }

//     if (new Date() < offerExpiresAt.toDate()) return;

//     const offeredLaundryId = after.laundryOffer?.offeredLaundryId;
//     if (!offeredLaundryId) return;

//     const bookingRef = db.collection("bookings").doc(bookingId);

//     await db.runTransaction(async (tx) => {
//       const freshSnap = await tx.get(bookingRef);
//       const fresh = freshSnap.data();

//       if (!fresh) throw new Error("Booking not found while expiring offer");
//       if (fresh.status !== "offered_to_laundry") return;

//       const freshOfferExpiresAt = fresh.laundryOffer?.offerExpiresAt;

//       if (
//         !freshOfferExpiresAt ||
//         typeof freshOfferExpiresAt.toDate !== "function" ||
//         freshOfferExpiresAt.toDate() > new Date()
//       ) {
//         return;
//       }

//       const rejectedLaundryIds = Array.isArray(fresh.rejectedLaundryIds)
//         ? fresh.rejectedLaundryIds
//         : [];

//       const updatedRejectedLaundryIds = rejectedLaundryIds.includes(
//         offeredLaundryId,
//       )
//         ? rejectedLaundryIds
//         : [...rejectedLaundryIds, offeredLaundryId];

//       tx.update(bookingRef, {
//         status: "awaiting_laundry_assignment",
//         laundrySnapshot: null,
//         rejectedLaundryIds: updatedRejectedLaundryIds,

//         "laundryOffer.offeredLaundryId": null,
//         "laundryOffer.offeredAt": null,
//         "laundryOffer.offerExpiresAt": null,

//         updatedAt: FieldValue.serverTimestamp(),
//       });

//       tx.set(bookingRef.collection("status_history").doc(), {
//         status: "awaiting_laundry_assignment",
//         title: "Offer Expired",
//         description:
//           "Laundry did not respond in time. Looking for another laundry.",
//         createdAt: FieldValue.serverTimestamp(),
//       });
//     });

//     logger.info("Expired laundry offer and reset booking for reassignment.", {
//       bookingId,
//       offeredLaundryId,
//     });
//   },
// );

// exports.acceptLaundryOffer = onDocumentUpdated(
//   "bookings/{bookingId}",
//   async (event) => {
//     const before = event.data?.before?.data();
//     const after = event.data?.after?.data();
//     const bookingId = event.params.bookingId;

//     if (!before || !after) return;

//     const acceptedNow =
//       before.status === "offered_to_laundry" && after.status === "pending";

//     if (!acceptedNow) return;

//     const laundrySnapshot = getLaundrySnapshot(after);

//     logger.info("Laundry accepted booking offer.", {
//       bookingId,
//       laundryId: laundrySnapshot.id || null,
//       laundryName: laundrySnapshot.name || null,
//     });
//   },
// );

// async function offerLaundryForBooking(bookingId) {
//   const bookingRef = db.collection("bookings").doc(bookingId);
//   const bookingSnap = await bookingRef.get();

//   if (!bookingSnap.exists) {
//     logger.warn("Booking does not exist for offer flow.", { bookingId });
//     return;
//   }

//   const booking = bookingSnap.data();

//   if (!booking) {
//     logger.warn("Booking data missing for offer flow.", { bookingId });
//     return;
//   }

//   if (booking.status !== "awaiting_laundry_assignment") {
//     logger.info("Skipping offer flow. Booking not awaiting assignment.", {
//       bookingId,
//       status: booking.status,
//     });
//     return;
//   }

//   const existingLaundrySnapshot = getLaundrySnapshot(booking);

//   if (existingLaundrySnapshot.id) {
//     logger.info("Skipping offer flow. Booking already has laundrySnapshot.", {
//       bookingId,
//       laundryId: existingLaundrySnapshot.id,
//     });
//     return;
//   }

//   const bookingPoint =
//     booking.pickup?.geopoint ||
//     booking.pickupAddress?.geopoint ||
//     booking.customerAddress?.geopoint;

//   const center = getGeoPointLatLng(bookingPoint);

//   if (!center) {
//     logger.warn("Booking missing pickup/customer GeoPoint for laundry flow.", {
//       bookingId,
//     });
//     return;
//   }

//   const selectedAddOns = Array.isArray(booking.selectedAddOns)
//     ? booking.selectedAddOns
//     : [];

//   const serviceType = booking.serviceType || "";

//   const rejectedLaundryIds = Array.isArray(booking.rejectedLaundryIds)
//     ? booking.rejectedLaundryIds
//     : [];

//   let nearbyLaundries = [];

//   try {
//     nearbyLaundries = await queryNearbyCollection({
//       collectionName: "laundries",
//       geohashField: "location.geohash",
//       geopointField: "location.geopoint",
//       center,
//       radiusKm: MAX_MATCH_DISTANCE_KM,
//       applyBaseQuery: (query) =>
//         query
//           .where("role", "==", "laundry")
//           .where("business.isApproved", "==", true)
//           .where("business.acceptingOrders", "==", true)
//           .where("business.acceptingAutoAssignments", "==", true),
//     });
//   } catch (error) {
//     logger.error("Laundry geohash query failed.", {
//       bookingId,
//       center,
//       error: error.message,
//       stack: error.stack,
//     });
//     throw error;
//   }

//   if (nearbyLaundries.length === 0) {
//     logger.info("No nearby laundries available for matching.", { bookingId });
//     await markNoLaundryFound(bookingId);
//     return;
//   }

//   const eligible = [];

//   for (const item of nearbyLaundries) {
//     const doc = item.doc;
//     const laundry = item.data;

//     if (rejectedLaundryIds.includes(doc.id)) continue;

//     const currentOrderCount = Number(laundry.business?.currentOrderCount ?? 0);
//     const maxConcurrentOrders = Number(
//       laundry.business?.maxConcurrentOrders ?? 0,
//     );

//     if (maxConcurrentOrders > 0 && currentOrderCount >= maxConcurrentOrders) {
//       continue;
//     }

//     if (!isLaundryOpenNow(laundry.openingHours)) continue;
//     if (!supportsRequestedService(laundry, serviceType)) continue;
//     if (!supportsRequestedAddOns(laundry, selectedAddOns)) continue;

//     const rating = Number(laundry.ratings?.rating ?? 0);

//     eligible.push({
//       id: doc.id,
//       distanceKm: item.distanceKm,
//       rating,
//       score: item.distanceKm - rating * 0.05,
//       data: laundry,
//     });
//   }

//   if (eligible.length === 0) {
//     logger.info("No eligible laundries matched booking.", {
//       bookingId,
//       serviceType,
//       selectedAddOns,
//       rejectedLaundryIds,
//     });
//     await markNoLaundryFound(bookingId);
//     return;
//   }

//   eligible.sort((a, b) => a.score - b.score);
//   const best = eligible[0];

//   const offerExpiresAt = Timestamp.fromDate(
//     new Date(Date.now() + OFFER_EXPIRY_MINUTES * 60 * 1000),
//   );

//   const selectedLaundrySnapshot = buildLaundrySnapshot(best.id, best.data);

//   await db.runTransaction(async (tx) => {
//     const freshSnap = await tx.get(bookingRef);
//     const fresh = freshSnap.data();

//     if (!fresh) throw new Error("Booking disappeared before laundry offer");

//     if (fresh.status !== "awaiting_laundry_assignment") {
//       logger.info("Booking status changed before offer transaction.", {
//         bookingId,
//         status: fresh.status,
//       });
//       return;
//     }

//     const freshLaundrySnapshot = getLaundrySnapshot(fresh);

//     if (freshLaundrySnapshot.id) {
//       logger.info("Booking already has laundrySnapshot before transaction.", {
//         bookingId,
//         laundryId: freshLaundrySnapshot.id,
//       });
//       return;
//     }

//     const nextAttempts = Number(fresh.searchMeta?.assignmentAttempts ?? 0) + 1;

//     tx.update(bookingRef, {
//       laundrySnapshot: selectedLaundrySnapshot,

//       status: "offered_to_laundry",
//       updatedAt: FieldValue.serverTimestamp(),

//       "laundryOffer.offeredLaundryId": best.id,
//       "laundryOffer.offeredAt": FieldValue.serverTimestamp(),
//       "laundryOffer.offerExpiresAt": offerExpiresAt,

//       "searchMeta.assignmentAttempts": nextAttempts,
//       "searchMeta.lastAssignmentAttemptAt": FieldValue.serverTimestamp(),
//     });

//     tx.set(bookingRef.collection("status_history").doc(), {
//       status: "offered_to_laundry",
//       title: "Offer Sent To Laundry",
//       description: `${selectedLaundrySnapshot.name || "A laundry"} received this order offer.`,
//       createdAt: FieldValue.serverTimestamp(),
//     });
//   });

//   logger.info("Laundry offer created successfully.", {
//     bookingId,
//     laundryId: selectedLaundrySnapshot.id,
//     laundryName: selectedLaundrySnapshot.name || "",
//     distanceKm: best.distanceKm,
//     rating: best.rating,
//   });
// }

// async function markNoLaundryFound(bookingId) {
//   const bookingRef = db.collection("bookings").doc(bookingId);

//   await db.runTransaction(async (tx) => {
//     const bookingSnap = await tx.get(bookingRef);
//     const booking = bookingSnap.data();

//     if (!booking) {
//       throw new Error("Booking not found while marking no laundry found");
//     }

//     const laundrySnapshot = getLaundrySnapshot(booking);

//     if (laundrySnapshot.id) return;

//     const nextAttempts =
//       Number(booking.searchMeta?.assignmentAttempts ?? 0) + 1;

//     tx.update(bookingRef, {
//       status: "no_laundry_found",
//       updatedAt: FieldValue.serverTimestamp(),
//       "searchMeta.assignmentAttempts": nextAttempts,
//       "searchMeta.lastAssignmentAttemptAt": FieldValue.serverTimestamp(),
//     });

//     tx.set(bookingRef.collection("status_history").doc(), {
//       status: "no_laundry_found",
//       title: "No Laundry Found",
//       description: "No suitable laundry was found for this booking.",
//       createdAt: FieldValue.serverTimestamp(),
//     });
//   });
// }

// /* -------------------------------------------------------------------------- */
// /*                               RIDER MATCHING                               */
// /* -------------------------------------------------------------------------- */

// exports.offerPickupRiderOnBookingUpdate = onDocumentUpdated(
//   "bookings/{bookingId}",
//   async (event) => {
//     const before = event.data?.before?.data();
//     const after = event.data?.after?.data();
//     const bookingId = event.params.bookingId;

//     if (!before || !after) return;

//     const changedToLookingForPickupRider =
//       before.status !== after.status &&
//       after.status === "looking_for_pickup_rider";

//     if (!changedToLookingForPickupRider) return;

//     await assignPickupRiderForBooking(bookingId);
//   },
// );

// exports.offerDeliveryRiderOnBookingUpdate = onDocumentUpdated(
//   "bookings/{bookingId}",
//   async (event) => {
//     const before = event.data?.before?.data();
//     const after = event.data?.after?.data();
//     const bookingId = event.params.bookingId;

//     if (!before || !after) return;

//     const changedToReadyForDropoff =
//       before.status !== after.status && after.status === "ready_for_dropoff";

//     if (!changedToReadyForDropoff) return;

//     await assignDeliveryRiderForBooking(bookingId);
//   },
// );

// async function assignPickupRiderForBooking(bookingId) {
//   const bookingRef = db.collection("bookings").doc(bookingId);
//   const bookingSnap = await bookingRef.get();

//   if (!bookingSnap.exists) {
//     logger.warn("Booking does not exist for pickup rider flow.", { bookingId });
//     return;
//   }

//   const booking = bookingSnap.data();

//   if (!booking) {
//     logger.warn("Booking data missing for pickup rider flow.", { bookingId });
//     return;
//   }

//   if (booking.status !== "looking_for_pickup_rider") {
//     logger.info("Skipping pickup rider assignment. Wrong booking status.", {
//       bookingId,
//       status: booking.status,
//     });
//     return;
//   }

//   if (booking.pickupRider?.riderId) {
//     logger.info("Skipping pickup rider assignment. Rider already assigned.", {
//       bookingId,
//       riderId: booking.pickupRider?.riderId,
//     });
//     return;
//   }

//   const pickupCenter = getGeoPointLatLng(
//     booking.pickup?.geopoint ||
//       booking.pickupAddress?.geopoint ||
//       booking.customerAddress?.geopoint,
//   );

//   if (!pickupCenter) {
//     logger.warn("Booking missing pickup GeoPoint for pickup rider flow.", {
//       bookingId,
//     });
//     return;
//   }

//   const best = await findBestNearbyRiderWithFallback({
//     center: pickupCenter,
//     bookingId,
//     flow: "pickup",
//   });

//   if (!best) {
//     logger.info("No eligible riders matched booking for pickup.", {
//       bookingId,
//     });
//     return;
//   }

//   await db.runTransaction(async (tx) => {
//     const freshBookingSnap = await tx.get(bookingRef);
//     const freshBooking = freshBookingSnap.data();

//     if (!freshBooking) {
//       throw new Error("Booking disappeared before pickup rider assignment");
//     }

//     if (freshBooking.status !== "looking_for_pickup_rider") {
//       logger.info("Booking status changed before pickup rider transaction.", {
//         bookingId,
//         status: freshBooking.status,
//       });
//       return;
//     }

//     if (freshBooking.pickupRider?.riderId) {
//       logger.info("Pickup rider already assigned before transaction.", {
//         bookingId,
//         riderId: freshBooking.pickupRider?.riderId,
//       });
//       return;
//     }

//     const riderRef = db.collection("riders").doc(best.id);
//     const riderSnap = await tx.get(riderRef);
//     const riderData = riderSnap.data();

//     if (!riderData) {
//       throw new Error("Matched rider disappeared before assignment");
//     }

//     if (!isRiderStillAssignable(riderData, best.maxAgeMinutes)) {
//       logger.info("Matched rider became unavailable before transaction.", {
//         bookingId,
//         riderId: best.id,
//       });
//       return;
//     }

//     const businessUpdate = buildRiderBusinessAssignmentUpdate({
//       riderData,
//       bookingId,
//       booking: freshBooking,
//     });

//     tx.update(bookingRef, {
//       "pickupRider.riderId": best.id,
//       "pickupRider.fullName": best.data.profile?.fullName || "",
//       "pickupRider.phoneNumber": best.data.contact?.phoneNumber || "",
//       "pickupRider.photoUrl": best.data.profile?.photoUrl || "",
//       "pickupRider.vehicleType": best.data.vehicle?.type || "",
//       "pickupRider.plateNumber": best.data.vehicle?.plateNumber || "",
//       "pickupRider.assignedAt": FieldValue.serverTimestamp(),
//       updatedAt: FieldValue.serverTimestamp(),
//     });

//     tx.update(riderRef, businessUpdate);

//     tx.set(bookingRef.collection("status_history").doc(), {
//       status: "looking_for_pickup_rider",
//       title: "Pickup Rider Assigned",
//       description: `${best.data.profile?.fullName || "A rider"} was assigned for pickup.`,
//       createdAt: FieldValue.serverTimestamp(),
//     });
//   });

//   logger.info("Pickup rider assigned successfully.", {
//     bookingId,
//     riderId: best.id,
//     riderName: best.data.profile?.fullName || "",
//     distanceKm: best.distanceKm,
//     rating: best.rating,
//     maxAgeMinutes: best.maxAgeMinutes,
//   });
// }

// async function assignDeliveryRiderForBooking(bookingId) {
//   const bookingRef = db.collection("bookings").doc(bookingId);
//   const bookingSnap = await bookingRef.get();

//   if (!bookingSnap.exists) {
//     logger.warn("Booking does not exist for delivery rider flow.", {
//       bookingId,
//     });
//     return;
//   }

//   const booking = bookingSnap.data();

//   if (!booking) {
//     logger.warn("Booking data missing for delivery rider flow.", { bookingId });
//     return;
//   }

//   if (booking.status !== "ready_for_dropoff") {
//     logger.info("Skipping delivery rider assignment. Wrong booking status.", {
//       bookingId,
//       status: booking.status,
//     });
//     return;
//   }

//   if (booking.deliveryRider?.riderId) {
//     logger.info("Skipping delivery rider assignment. Rider already assigned.", {
//       bookingId,
//       riderId: booking.deliveryRider?.riderId,
//     });
//     return;
//   }

//   const deliveryCenter = getGeoPointLatLng(
//     booking.customerAddress?.geopoint ||
//       booking.dropoff?.geopoint ||
//       booking.pickup?.geopoint,
//   );

//   if (!deliveryCenter) {
//     logger.warn("Booking missing customer GeoPoint for delivery rider flow.", {
//       bookingId,
//     });
//     return;
//   }

//   const best = await findBestNearbyRiderWithFallback({
//     center: deliveryCenter,
//     bookingId,
//     flow: "delivery",
//   });

//   if (!best) {
//     logger.info("No eligible riders matched booking for delivery.", {
//       bookingId,
//     });
//     return;
//   }

//   await db.runTransaction(async (tx) => {
//     const freshBookingSnap = await tx.get(bookingRef);
//     const freshBooking = freshBookingSnap.data();

//     if (!freshBooking) {
//       throw new Error("Booking disappeared before delivery rider assignment");
//     }

//     if (freshBooking.status !== "ready_for_dropoff") {
//       logger.info("Booking status changed before delivery rider transaction.", {
//         bookingId,
//         status: freshBooking.status,
//       });
//       return;
//     }

//     if (freshBooking.deliveryRider?.riderId) {
//       logger.info("Delivery rider already assigned before transaction.", {
//         bookingId,
//         riderId: freshBooking.deliveryRider?.riderId,
//       });
//       return;
//     }

//     const riderRef = db.collection("riders").doc(best.id);
//     const riderSnap = await tx.get(riderRef);
//     const riderData = riderSnap.data();

//     if (!riderData) {
//       throw new Error("Matched rider disappeared before delivery assignment");
//     }

//     if (!isRiderStillAssignable(riderData, best.maxAgeMinutes)) {
//       logger.info(
//         "Matched delivery rider became unavailable before transaction.",
//         {
//           bookingId,
//           riderId: best.id,
//         },
//       );
//       return;
//     }

//     const businessUpdate = buildRiderBusinessAssignmentUpdate({
//       riderData,
//       bookingId,
//       booking: freshBooking,
//     });

//     tx.update(bookingRef, {
//       "deliveryRider.riderId": best.id,
//       "deliveryRider.fullName": best.data.profile?.fullName || "",
//       "deliveryRider.phoneNumber": best.data.contact?.phoneNumber || "",
//       "deliveryRider.photoUrl": best.data.profile?.photoUrl || "",
//       "deliveryRider.vehicleType": best.data.vehicle?.type || "",
//       "deliveryRider.plateNumber": best.data.vehicle?.plateNumber || "",
//       "deliveryRider.assignedAt": FieldValue.serverTimestamp(),
//       updatedAt: FieldValue.serverTimestamp(),
//     });

//     tx.update(riderRef, businessUpdate);

//     tx.set(bookingRef.collection("status_history").doc(), {
//       status: "ready_for_dropoff",
//       title: "Delivery Rider Assigned",
//       description: `${best.data.profile?.fullName || "A rider"} was assigned for delivery.`,
//       createdAt: FieldValue.serverTimestamp(),
//     });
//   });

//   logger.info("Delivery rider assigned successfully.", {
//     bookingId,
//     riderId: best.id,
//     riderName: best.data.profile?.fullName || "",
//     distanceKm: best.distanceKm,
//     rating: best.rating,
//     maxAgeMinutes: best.maxAgeMinutes,
//   });
// }

// async function findBestNearbyRiderWithFallback({ center, bookingId, flow }) {
//   for (const maxAgeMinutes of RIDER_LOCATION_FRESHNESS_WINDOWS_MINUTES) {
//     const best = await findBestNearbyRider({
//       center,
//       bookingId,
//       flow,
//       maxAgeMinutes,
//     });

//     if (best) {
//       logger.info("Rider matched using freshness fallback.", {
//         bookingId,
//         flow,
//         riderId: best.id,
//         maxAgeMinutes,
//       });

//       return best;
//     }

//     logger.info("No rider found for freshness window. Trying next window.", {
//       bookingId,
//       flow,
//       maxAgeMinutes,
//     });
//   }

//   return null;
// }

// async function findBestNearbyRider({ center, bookingId, flow, maxAgeMinutes }) {
//   let nearbyRiders = [];

//   try {
//     nearbyRiders = await queryNearbyCollection({
//       collectionName: "riders",
//       geohashField: "location.geohash",
//       geopointField: "location.geopoint",
//       center,
//       radiusKm: MAX_RIDER_MATCH_DISTANCE_KM,
//       applyBaseQuery: (query) =>
//         query
//           .where("role", "==", "rider")
//           .where("business.isApproved", "==", true)
//           .where("business.isOnline", "==", true)
//           .where("business.acceptingAssignments", "==", true),
//     });
//   } catch (error) {
//     logger.error("Rider geohash query failed.", {
//       bookingId,
//       flow,
//       center,
//       maxAgeMinutes,
//       error: error.message,
//       stack: error.stack,
//     });
//     throw error;
//   }

//   const eligible = [];

//   for (const item of nearbyRiders) {
//     const rider = item.data;

//     if (!isRiderStillAssignable(rider, maxAgeMinutes)) continue;

//     const rating = Number(rider.ratings?.rating ?? 0);

//     eligible.push({
//       id: item.doc.id,
//       distanceKm: item.distanceKm,
//       rating,
//       score: item.distanceKm - rating * 0.05,
//       data: rider,
//       maxAgeMinutes,
//     });
//   }

//   if (eligible.length === 0) {
//     logger.info("No eligible nearby riders after filtering.", {
//       bookingId,
//       flow,
//       maxAgeMinutes,
//     });
//     return null;
//   }

//   eligible.sort((a, b) => a.score - b.score);
//   return eligible[0];
// }

// function isRiderStillAssignable(rider, maxAgeMinutes = 5) {
//   const business = rider.business || {};

//   if (business.isApproved !== true) return false;
//   if (business.isOnline !== true) return false;
//   if (business.acceptingAssignments !== true) return false;

//   const availabilityStatus = business.availabilityStatus || "";

//   if (
//     availabilityStatus &&
//     availabilityStatus !== "available" &&
//     availabilityStatus !== "online"
//   ) {
//     return false;
//   }

//   const currentActiveRequestCount = Number(
//     business.currentActiveRequestCount ?? 0,
//   );

//   const maxActiveRequests = Number(business.maxActiveRequests ?? 0);

//   if (maxActiveRequests > 0 && currentActiveRequestCount >= maxActiveRequests) {
//     return false;
//   }

//   if (!isRecentLocation(rider.location?.lastLocationUpdatedAt, maxAgeMinutes)) {
//     return false;
//   }

//   return true;
// }

// function buildRiderBusinessAssignmentUpdate({ riderData, bookingId, booking }) {
//   const business = riderData.business || {};

//   const currentActiveRequestCount = Number(
//     business.currentActiveRequestCount ?? 0,
//   );

//   const maxActiveRequests = Number(business.maxActiveRequests ?? 0);

//   const existingActiveRequestIds = Array.isArray(business.activeRequestIds)
//     ? business.activeRequestIds
//     : [];

//   const existingLaundryIds = Array.isArray(business.currentLaundryIds)
//     ? business.currentLaundryIds
//     : [];

//   const existingCustomerIds = Array.isArray(business.currentCustomerIds)
//     ? business.currentCustomerIds
//     : [];

//   const laundrySnapshot = getLaundrySnapshot(booking);
//   const laundryId = laundrySnapshot.id || null;

//   const newActiveRequestIds = existingActiveRequestIds.includes(bookingId)
//     ? existingActiveRequestIds
//     : [...existingActiveRequestIds, bookingId];

//   const newCurrentLaundryIds =
//     laundryId && !existingLaundryIds.includes(laundryId)
//       ? [...existingLaundryIds, laundryId]
//       : existingLaundryIds;

//   const newCurrentCustomerIds =
//     booking.customerId && !existingCustomerIds.includes(booking.customerId)
//       ? [...existingCustomerIds, booking.customerId]
//       : existingCustomerIds;

//   const nextActiveCount = currentActiveRequestCount + 1;

//   return {
//     "business.currentActiveRequestCount": nextActiveCount,
//     "business.activeRequestIds": newActiveRequestIds,
//     "business.currentLaundryIds": newCurrentLaundryIds,
//     "business.currentCustomerIds": newCurrentCustomerIds,
//     "business.availabilityStatus":
//       maxActiveRequests > 0 && nextActiveCount >= maxActiveRequests
//         ? "busy"
//         : "available",
//     "business.acceptingAssignments":
//       maxActiveRequests > 0 ? nextActiveCount < maxActiveRequests : true,
//     "timestamps.updatedAt": FieldValue.serverTimestamp(),
//   };
// }

// /* -------------------------------------------------------------------------- */
// /*                               RIDER CLEANUP                                */
// /* -------------------------------------------------------------------------- */

// exports.cleanupRejectedPickupRider = onDocumentUpdated(
//   "bookings/{bookingId}",
//   async (event) => {
//     const before = event.data?.before?.data();
//     const after = event.data?.after?.data();
//     const bookingId = event.params.bookingId;

//     if (!before || !after) return;

//     const beforeRiderId = before.pickupRider?.riderId || null;
//     const afterRiderId = after.pickupRider?.riderId || null;

//     const riderWasRemoved = beforeRiderId && !afterRiderId;

//     if (!riderWasRemoved) return;

//     const laundrySnapshot = getLaundrySnapshot(before);

//     await releaseRiderFromBooking({
//       riderId: beforeRiderId,
//       bookingId,
//       laundryId: laundrySnapshot.id || null,
//       customerId: before.customerId || null,
//     });
//   },
// );

// exports.cleanupRejectedDeliveryRider = onDocumentUpdated(
//   "bookings/{bookingId}",
//   async (event) => {
//     const before = event.data?.before?.data();
//     const after = event.data?.after?.data();
//     const bookingId = event.params.bookingId;

//     if (!before || !after) return;

//     const beforeRiderId = before.deliveryRider?.riderId || null;
//     const afterRiderId = after.deliveryRider?.riderId || null;

//     const riderWasRemoved = beforeRiderId && !afterRiderId;

//     if (!riderWasRemoved) return;

//     const laundrySnapshot = getLaundrySnapshot(before);

//     await releaseRiderFromBooking({
//       riderId: beforeRiderId,
//       bookingId,
//       laundryId: laundrySnapshot.id || null,
//       customerId: before.customerId || null,
//     });
//   },
// );

// exports.cleanupRidersOnBookingClosed = onDocumentUpdated(
//   "bookings/{bookingId}",
//   async (event) => {
//     const before = event.data?.before?.data();
//     const after = event.data?.after?.data();
//     const bookingId = event.params.bookingId;

//     if (!before || !after) return;

//     const wasOpen = !isBookingClosed(before.status);
//     const isNowClosed = isBookingClosed(after.status);

//     if (!wasOpen || !isNowClosed) return;

//     const pickupRiderId =
//       after.pickupRider?.riderId || before.pickupRider?.riderId || null;

//     const deliveryRiderId =
//       after.deliveryRider?.riderId || before.deliveryRider?.riderId || null;

//     const afterLaundrySnapshot = getLaundrySnapshot(after);
//     const beforeLaundrySnapshot = getLaundrySnapshot(before);

//     const laundryId =
//       afterLaundrySnapshot.id || beforeLaundrySnapshot.id || null;

//     const customerId = after.customerId || before.customerId || null;

//     const jobs = [];

//     if (pickupRiderId) {
//       jobs.push(
//         releaseRiderFromBooking({
//           riderId: pickupRiderId,
//           bookingId,
//           laundryId,
//           customerId,
//         }),
//       );
//     }

//     if (deliveryRiderId && deliveryRiderId !== pickupRiderId) {
//       jobs.push(
//         releaseRiderFromBooking({
//           riderId: deliveryRiderId,
//           bookingId,
//           laundryId,
//           customerId,
//         }),
//       );
//     }

//     await Promise.all(jobs);
//   },
// );

// async function releaseRiderFromBooking({
//   riderId,
//   bookingId,
//   laundryId,
//   customerId,
// }) {
//   if (!riderId) return;

//   const riderRef = db.collection("riders").doc(riderId);

//   await db.runTransaction(async (tx) => {
//     const riderSnap = await tx.get(riderRef);
//     const rider = riderSnap.data();

//     if (!rider) return;

//     const business = rider.business || {};

//     const currentActiveRequestCount = Number(
//       business.currentActiveRequestCount ?? 0,
//     );

//     const maxActiveRequests = Number(business.maxActiveRequests ?? 0);

//     const activeRequestIds = Array.isArray(business.activeRequestIds)
//       ? business.activeRequestIds.filter((id) => id !== bookingId)
//       : [];

//     const currentLaundryIds = Array.isArray(business.currentLaundryIds)
//       ? laundryId
//         ? business.currentLaundryIds.filter((id) => id !== laundryId)
//         : business.currentLaundryIds
//       : [];

//     const currentCustomerIds = Array.isArray(business.currentCustomerIds)
//       ? customerId
//         ? business.currentCustomerIds.filter((id) => id !== customerId)
//         : business.currentCustomerIds
//       : [];

//     const nextCount = Math.max(0, currentActiveRequestCount - 1);

//     tx.update(riderRef, {
//       "business.currentActiveRequestCount": nextCount,
//       "business.activeRequestIds": activeRequestIds,
//       "business.currentLaundryIds": currentLaundryIds,
//       "business.currentCustomerIds": currentCustomerIds,
//       "business.availabilityStatus":
//         nextCount <= 0
//           ? rider.business?.isOnline
//             ? "available"
//             : "offline"
//           : maxActiveRequests > 0 && nextCount >= maxActiveRequests
//             ? "busy"
//             : "available",
//       "business.acceptingAssignments":
//         rider.business?.isOnline === true &&
//         (maxActiveRequests <= 0 || nextCount < maxActiveRequests),
//       "timestamps.updatedAt": FieldValue.serverTimestamp(),
//     });
//   });
// }

// function isBookingClosed(status) {
//   return status === "completed" || status === "cancelled";
// }

// /* -------------------------------------------------------------------------- */
// /*                            GEOHASH QUERY HELPERS                           */
// /* -------------------------------------------------------------------------- */

// async function queryNearbyCollection({
//   collectionName,
//   geohashField,
//   geopointField,
//   center,
//   radiusKm,
//   applyBaseQuery,
// }) {
//   const radiusInM = radiusKm * 1000;

//   const bounds = geofire.geohashQueryBounds(
//     [center.latitude, center.longitude],
//     radiusInM,
//   );

//   const seen = new Set();
//   const results = [];

//   const queries = bounds.map(([start, end]) => {
//     let query = db.collection(collectionName);

//     if (typeof applyBaseQuery === "function") {
//       query = applyBaseQuery(query);
//     }

//     return query.orderBy(geohashField).startAt(start).endAt(end).get();
//   });

//   const snapshots = await Promise.all(queries);

//   logger.info("Geo bounds query returned snapshots.", {
//     collectionName,
//     boundsCount: bounds.length,
//     docsPerBound: snapshots.map((snapshot) => snapshot.size),
//   });

//   for (const snap of snapshots) {
//     for (const doc of snap.docs) {
//       if (seen.has(doc.id)) continue;
//       seen.add(doc.id);

//       const data = doc.data();
//       const point = getNestedValue(data, geopointField);
//       const itemCenter = getGeoPointLatLng(point);

//       if (!itemCenter) continue;

//       const distanceKm = geofire.distanceBetween(
//         [center.latitude, center.longitude],
//         [itemCenter.latitude, itemCenter.longitude],
//       );

//       if (distanceKm > radiusKm) continue;

//       results.push({
//         doc,
//         data,
//         distanceKm,
//       });
//     }
//   }

//   logger.info("Geo query completed.", {
//     collectionName,
//     resultsCount: results.length,
//     center,
//     radiusKm,
//   });

//   return results;
// }

// function getGeoPointLatLng(geoPoint) {
//   if (!geoPoint) return null;

//   const latitude = geoPoint.latitude;
//   const longitude = geoPoint.longitude;

//   if (typeof latitude !== "number" || typeof longitude !== "number") {
//     return null;
//   }

//   return { latitude, longitude };
// }

// function getNestedValue(object, path) {
//   if (!object || !path) return null;

//   return path.split(".").reduce((current, key) => {
//     if (!current || typeof current !== "object") return null;
//     return current[key];
//   }, object);
// }

// function isRecentLocation(timestamp, maxAgeMinutes) {
//   if (!timestamp || typeof timestamp.toMillis !== "function") {
//     return false;
//   }

//   const ageMs = Date.now() - timestamp.toMillis();
//   return ageMs <= maxAgeMinutes * 60 * 1000;
// }

// /* -------------------------------------------------------------------------- */
// /*                                   HELPERS                                  */
// /* -------------------------------------------------------------------------- */

// function buildLaundrySnapshot(laundryId, laundry) {
//   return {
//     id: laundryId,
//     name: laundry.profile?.name || "",
//     phoneNumber: laundry.contact?.phoneNumber || "",
//     whatsappNumber: laundry.contact?.whatsappNumber || "",
//     photoUrl: laundry.profile?.photoUrl || laundry.profile?.logoUrl || "",
//     addressLine: laundry.location?.addressLine || "",
//     geohash: laundry.location?.geohash || "",
//     geopoint: laundry.location?.geopoint || null,
//     rating: Number(laundry.ratings?.rating ?? 0),
//     totalRatings: Number(laundry.ratings?.totalRatings ?? 0),
//     capturedAt: FieldValue.serverTimestamp(),
//   };
// }

// function getLaundrySnapshot(booking) {
//   const snapshot =
//     booking && typeof booking.laundrySnapshot === "object"
//       ? booking.laundrySnapshot
//       : {};

//   return {
//     id: snapshot.id || snapshot.laundryId || "",
//     name: snapshot.name || snapshot.laundryName || "",
//     phoneNumber: snapshot.phoneNumber || snapshot.phone || "",
//     whatsappNumber: snapshot.whatsappNumber || "",
//     photoUrl: snapshot.photoUrl || snapshot.logoUrl || "",
//     addressLine: snapshot.addressLine || "",
//     geohash: snapshot.geohash || "",
//     geopoint: snapshot.geopoint || null,
//     rating: Number(snapshot.rating ?? 0),
//     totalRatings: Number(snapshot.totalRatings ?? 0),
//   };
// }

// function supportsRequestedService(laundry, serviceType) {
//   if (!serviceType) return true;

//   const services = laundry.services || {};

//   if (serviceType === "wash_fold") {
//     return services.washFold === true || services.wash_fold === true;
//   }

//   if (serviceType === "wash_iron") {
//     if (services.washIron === true || services.wash_iron === true) {
//       return true;
//     }

//     const washIronExtraPerKg = laundry.pricing?.washIronExtraPerKg;
//     return typeof washIronExtraPerKg === "number";
//   }

//   return true;
// }

// function supportsRequestedAddOns(laundry, selectedAddOns) {
//   if (!Array.isArray(selectedAddOns) || selectedAddOns.length === 0) {
//     return true;
//   }

//   const supportedAddOns = Array.isArray(laundry.supportedAddOns)
//     ? laundry.supportedAddOns
//     : [];

//   if (supportedAddOns.length === 0) {
//     return true;
//   }

//   return selectedAddOns.every((addOn) => supportedAddOns.includes(addOn));
// }

// function isLaundryOpenNow(openingHours) {
//   if (!openingHours || typeof openingHours !== "object") {
//     return true;
//   }

//   const dayKeys = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];
//   const now = new Date();
//   const todayKey = dayKeys[now.getDay()];
//   const today = openingHours[todayKey];

//   if (!today) return true;
//   if (today.isOpen !== true) return false;

//   const open = today.open;
//   const close = today.close;

//   if (!open || !close) return true;

//   const currentMinutes = now.getHours() * 60 + now.getMinutes();
//   const openMinutes = parseTimeToMinutes(open);
//   const closeMinutes = parseTimeToMinutes(close);

//   if (openMinutes == null || closeMinutes == null) return true;

//   return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
// }

// function parseTimeToMinutes(time) {
//   if (typeof time !== "string" || !time.includes(":")) {
//     return null;
//   }

//   const parts = time.split(":");

//   if (parts.length !== 2) return null;

//   const hours = Number(parts[0]);
//   const minutes = Number(parts[1]);

//   if (Number.isNaN(hours) || Number.isNaN(minutes)) return null;

//   return hours * 60 + minutes;
// }

const { initializeApp } = require("firebase-admin/app");
const {
  getFirestore,
  FieldValue,
  Timestamp,
} = require("firebase-admin/firestore");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const geofire = require("geofire-common");

initializeApp();

const db = getFirestore();

const MAX_MATCH_DISTANCE_KM = 8;
const MAX_RIDER_MATCH_DISTANCE_KM = 5;
const OFFER_EXPIRY_MINUTES = 2;

// Rider fallback freshness windows
const RIDER_LOCATION_FRESHNESS_WINDOWS_MINUTES = [5, 10, 30];

/* -------------------------------------------------------------------------- */
/*                              LAUNDRY MATCHING                              */
/* -------------------------------------------------------------------------- */

exports.offerLaundryOnBookingCreate = onDocumentCreated(
  "bookings/{bookingId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const bookingId = event.params.bookingId;
    const booking = snapshot.data();

    if (booking.status !== "awaiting_laundry_assignment") {
      logger.info("Skipping create trigger. Booking not awaiting assignment.", {
        bookingId,
        status: booking.status,
      });
      return;
    }

    await offerLaundryForBooking(bookingId);
  },
);

exports.reofferLaundryOnBookingUpdate = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) return;

    const statusChanged =
      before.status !== after.status &&
      after.status === "awaiting_laundry_assignment";

    const offerExpired =
      before.status === "offered_to_laundry" &&
      after.status === "awaiting_laundry_assignment";

    if (!statusChanged && !offerExpired) return;

    const laundrySnapshot = getLaundrySnapshot(after);

    if (laundrySnapshot.id) {
      logger.info("Skipping re-offer because laundrySnapshot still exists.", {
        bookingId,
        laundryId: laundrySnapshot.id,
      });
      return;
    }

    await offerLaundryForBooking(bookingId);
  },
);

exports.expireLaundryOffers = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) return;
    if (after.status !== "offered_to_laundry") return;

    const offerExpiresAt = after.laundryOffer?.offerExpiresAt;
    if (!offerExpiresAt || typeof offerExpiresAt.toDate !== "function") {
      return;
    }

    if (new Date() < offerExpiresAt.toDate()) return;

    const offeredLaundryId = after.laundryOffer?.offeredLaundryId;
    if (!offeredLaundryId) return;

    const bookingRef = db.collection("bookings").doc(bookingId);

    await db.runTransaction(async (tx) => {
      const freshSnap = await tx.get(bookingRef);
      const fresh = freshSnap.data();

      if (!fresh) throw new Error("Booking not found while expiring offer");
      if (fresh.status !== "offered_to_laundry") return;

      const freshOfferExpiresAt = fresh.laundryOffer?.offerExpiresAt;

      if (
        !freshOfferExpiresAt ||
        typeof freshOfferExpiresAt.toDate !== "function" ||
        freshOfferExpiresAt.toDate() > new Date()
      ) {
        return;
      }

      const rejectedLaundryIds = Array.isArray(fresh.rejectedLaundryIds)
        ? fresh.rejectedLaundryIds
        : [];

      const updatedRejectedLaundryIds = rejectedLaundryIds.includes(
        offeredLaundryId,
      )
        ? rejectedLaundryIds
        : [...rejectedLaundryIds, offeredLaundryId];

      tx.update(bookingRef, {
        status: "awaiting_laundry_assignment",
        laundrySnapshot: null,
        rejectedLaundryIds: updatedRejectedLaundryIds,

        "laundryOffer.offeredLaundryId": null,
        "laundryOffer.offeredAt": null,
        "laundryOffer.offerExpiresAt": null,

        updatedAt: FieldValue.serverTimestamp(),
      });

      tx.set(bookingRef.collection("status_history").doc(), {
        status: "awaiting_laundry_assignment",
        title: "Offer Expired",
        description:
          "Laundry did not respond in time. Looking for another laundry.",
        createdAt: FieldValue.serverTimestamp(),
      });
    });

    logger.info("Expired laundry offer and reset booking for reassignment.", {
      bookingId,
      offeredLaundryId,
    });
  },
);

exports.acceptLaundryOffer = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) return;

    const acceptedNow =
      before.status === "offered_to_laundry" && after.status === "pending";

    if (!acceptedNow) return;

    const laundrySnapshot = getLaundrySnapshot(after);

    logger.info("Laundry accepted booking offer.", {
      bookingId,
      laundryId: laundrySnapshot.id || null,
      laundryName: laundrySnapshot.name || null,
    });
  },
);

async function offerLaundryForBooking(bookingId) {
  const bookingRef = db.collection("bookings").doc(bookingId);
  const bookingSnap = await bookingRef.get();

  if (!bookingSnap.exists) {
    logger.warn("Booking does not exist for offer flow.", { bookingId });
    return;
  }

  const booking = bookingSnap.data();

  if (!booking) {
    logger.warn("Booking data missing for offer flow.", { bookingId });
    return;
  }

  if (booking.status !== "awaiting_laundry_assignment") {
    logger.info("Skipping offer flow. Booking not awaiting assignment.", {
      bookingId,
      status: booking.status,
    });
    return;
  }

  const existingLaundrySnapshot = getLaundrySnapshot(booking);

  if (existingLaundrySnapshot.id) {
    logger.info("Skipping offer flow. Booking already has laundrySnapshot.", {
      bookingId,
      laundryId: existingLaundrySnapshot.id,
    });
    return;
  }

  const bookingPoint =
    booking.pickup?.geopoint ||
    booking.pickupAddress?.geopoint ||
    booking.customerAddress?.geopoint;

  const center = getGeoPointLatLng(bookingPoint);

  if (!center) {
    logger.warn("Booking missing pickup/customer GeoPoint for laundry flow.", {
      bookingId,
    });
    return;
  }

  const selectedAddOns = Array.isArray(booking.selectedAddOns)
    ? booking.selectedAddOns
    : [];

  const serviceType = booking.serviceType || "";

  const rejectedLaundryIds = Array.isArray(booking.rejectedLaundryIds)
    ? booking.rejectedLaundryIds
    : [];

  let nearbyLaundries = [];

  try {
    nearbyLaundries = await queryNearbyCollection({
      collectionName: "laundries",
      geohashField: "location.geohash",
      geopointField: "location.geopoint",
      center,
      radiusKm: MAX_MATCH_DISTANCE_KM,
      applyBaseQuery: (query) =>
        query
          .where("role", "==", "laundry")
          .where("business.isApproved", "==", true)
          .where("business.acceptingOrders", "==", true)
          .where("business.acceptingAutoAssignments", "==", true),
    });
  } catch (error) {
    logger.error("Laundry geohash query failed.", {
      bookingId,
      center,
      error: error.message,
      stack: error.stack,
    });
    throw error;
  }

  if (nearbyLaundries.length === 0) {
    logger.info("No nearby laundries available for matching.", { bookingId });
    await markNoLaundryFound(bookingId);
    return;
  }

  const eligible = [];

  for (const item of nearbyLaundries) {
    const doc = item.doc;
    const laundry = item.data;

    if (rejectedLaundryIds.includes(doc.id)) continue;

    const currentOrderCount = Number(laundry.business?.currentOrderCount ?? 0);
    const maxConcurrentOrders = Number(
      laundry.business?.maxConcurrentOrders ?? 0,
    );

    if (maxConcurrentOrders > 0 && currentOrderCount >= maxConcurrentOrders) {
      continue;
    }

    if (!isLaundryOpenNow(laundry.openingHours)) continue;
    if (!supportsRequestedService(laundry, serviceType)) continue;
    if (!supportsRequestedAddOns(laundry, selectedAddOns)) continue;

    const rating = Number(laundry.ratings?.rating ?? 0);

    eligible.push({
      id: doc.id,
      distanceKm: item.distanceKm,
      rating,
      score: item.distanceKm - rating * 0.05,
      data: laundry,
    });
  }

  if (eligible.length === 0) {
    logger.info("No eligible laundries matched booking.", {
      bookingId,
      serviceType,
      selectedAddOns,
      rejectedLaundryIds,
    });
    await markNoLaundryFound(bookingId);
    return;
  }

  eligible.sort((a, b) => a.score - b.score);
  const best = eligible[0];

  const offerExpiresAt = Timestamp.fromDate(
    new Date(Date.now() + OFFER_EXPIRY_MINUTES * 60 * 1000),
  );

  const selectedLaundrySnapshot = buildLaundrySnapshot(best.id, best.data);

  await db.runTransaction(async (tx) => {
    const freshSnap = await tx.get(bookingRef);
    const fresh = freshSnap.data();

    if (!fresh) throw new Error("Booking disappeared before laundry offer");

    if (fresh.status !== "awaiting_laundry_assignment") {
      logger.info("Booking status changed before offer transaction.", {
        bookingId,
        status: fresh.status,
      });
      return;
    }

    const freshLaundrySnapshot = getLaundrySnapshot(fresh);

    if (freshLaundrySnapshot.id) {
      logger.info("Booking already has laundrySnapshot before transaction.", {
        bookingId,
        laundryId: freshLaundrySnapshot.id,
      });
      return;
    }

    const freshRejectedLaundryIds = Array.isArray(fresh.rejectedLaundryIds)
      ? fresh.rejectedLaundryIds
      : [];

    if (freshRejectedLaundryIds.includes(best.id)) {
      logger.info("Selected laundry was rejected before transaction.", {
        bookingId,
        laundryId: best.id,
      });
      return;
    }

    const nextAttempts = Number(fresh.searchMeta?.assignmentAttempts ?? 0) + 1;

    tx.update(bookingRef, {
      laundrySnapshot: selectedLaundrySnapshot,

      status: "offered_to_laundry",
      updatedAt: FieldValue.serverTimestamp(),

      "laundryOffer.offeredLaundryId": best.id,
      "laundryOffer.offeredAt": FieldValue.serverTimestamp(),
      "laundryOffer.offerExpiresAt": offerExpiresAt,

      "searchMeta.assignmentAttempts": nextAttempts,
      "searchMeta.lastAssignmentAttemptAt": FieldValue.serverTimestamp(),
    });

    tx.set(bookingRef.collection("status_history").doc(), {
      status: "offered_to_laundry",
      title: "Offer Sent To Laundry",
      description: `${selectedLaundrySnapshot.name || "A laundry"} received this order offer.`,
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  logger.info("Laundry offer created successfully.", {
    bookingId,
    laundryId: selectedLaundrySnapshot.id,
    laundryName: selectedLaundrySnapshot.name || "",
    distanceKm: best.distanceKm,
    rating: best.rating,
  });
}

async function markNoLaundryFound(bookingId) {
  const bookingRef = db.collection("bookings").doc(bookingId);

  await db.runTransaction(async (tx) => {
    const bookingSnap = await tx.get(bookingRef);
    const booking = bookingSnap.data();

    if (!booking) {
      throw new Error("Booking not found while marking no laundry found");
    }

    const laundrySnapshot = getLaundrySnapshot(booking);

    if (laundrySnapshot.id) return;

    const nextAttempts =
      Number(booking.searchMeta?.assignmentAttempts ?? 0) + 1;

    tx.update(bookingRef, {
      status: "no_laundry_found",
      updatedAt: FieldValue.serverTimestamp(),
      "searchMeta.assignmentAttempts": nextAttempts,
      "searchMeta.lastAssignmentAttemptAt": FieldValue.serverTimestamp(),
    });

    tx.set(bookingRef.collection("status_history").doc(), {
      status: "no_laundry_found",
      title: "No Laundry Found",
      description: "No suitable laundry was found for this booking.",
      createdAt: FieldValue.serverTimestamp(),
    });
  });
}

/* -------------------------------------------------------------------------- */
/*                               RIDER MATCHING                               */
/* -------------------------------------------------------------------------- */

exports.offerPickupRiderOnBookingUpdate = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) return;

    const changedToLookingForPickupRider =
      before.status !== after.status &&
      after.status === "looking_for_pickup_rider";

    const pickupRiderWasRemovedWhileStillLooking =
      before.pickupRider?.riderId &&
      !after.pickupRider?.riderId &&
      after.status === "looking_for_pickup_rider";

    if (
      !changedToLookingForPickupRider &&
      !pickupRiderWasRemovedWhileStillLooking
    ) {
      return;
    }

    await assignPickupRiderForBooking(bookingId);
  },
);

exports.offerDeliveryRiderOnBookingUpdate = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) return;

    const changedToReadyForDropoff =
      before.status !== after.status && after.status === "ready_for_dropoff";

    const deliveryRiderWasRemovedWhileStillReady =
      before.deliveryRider?.riderId &&
      !after.deliveryRider?.riderId &&
      after.status === "ready_for_dropoff";

    if (!changedToReadyForDropoff && !deliveryRiderWasRemovedWhileStillReady) {
      return;
    }

    await assignDeliveryRiderForBooking(bookingId);
  },
);

async function assignPickupRiderForBooking(bookingId) {
  const bookingRef = db.collection("bookings").doc(bookingId);
  const bookingSnap = await bookingRef.get();

  if (!bookingSnap.exists) {
    logger.warn("Booking does not exist for pickup rider flow.", { bookingId });
    return;
  }

  const booking = bookingSnap.data();

  if (!booking) {
    logger.warn("Booking data missing for pickup rider flow.", { bookingId });
    return;
  }

  if (booking.status !== "looking_for_pickup_rider") {
    logger.info("Skipping pickup rider assignment. Wrong booking status.", {
      bookingId,
      status: booking.status,
    });
    return;
  }

  if (booking.pickupRider?.riderId) {
    logger.info("Skipping pickup rider assignment. Rider already assigned.", {
      bookingId,
      riderId: booking.pickupRider?.riderId,
    });
    return;
  }

  const rejectedPickupRiderIds = Array.isArray(booking.rejectedPickupRiderIds)
    ? booking.rejectedPickupRiderIds
    : [];

  const pickupCenter = getGeoPointLatLng(
    booking.pickup?.geopoint ||
      booking.pickupAddress?.geopoint ||
      booking.customerAddress?.geopoint,
  );

  if (!pickupCenter) {
    logger.warn("Booking missing pickup GeoPoint for pickup rider flow.", {
      bookingId,
    });
    return;
  }

  const best = await findBestNearbyRiderWithFallback({
    center: pickupCenter,
    bookingId,
    flow: "pickup",
    rejectedRiderIds: rejectedPickupRiderIds,
  });

  if (!best) {
    logger.info("No eligible riders matched booking for pickup.", {
      bookingId,
      rejectedPickupRiderIds,
    });
    return;
  }

  await db.runTransaction(async (tx) => {
    const freshBookingSnap = await tx.get(bookingRef);
    const freshBooking = freshBookingSnap.data();

    if (!freshBooking) {
      throw new Error("Booking disappeared before pickup rider assignment");
    }

    if (freshBooking.status !== "looking_for_pickup_rider") {
      logger.info("Booking status changed before pickup rider transaction.", {
        bookingId,
        status: freshBooking.status,
      });
      return;
    }

    if (freshBooking.pickupRider?.riderId) {
      logger.info("Pickup rider already assigned before transaction.", {
        bookingId,
        riderId: freshBooking.pickupRider?.riderId,
      });
      return;
    }

    const freshRejectedPickupRiderIds = Array.isArray(
      freshBooking.rejectedPickupRiderIds,
    )
      ? freshBooking.rejectedPickupRiderIds
      : [];

    if (freshRejectedPickupRiderIds.includes(best.id)) {
      logger.info("Selected pickup rider was rejected before transaction.", {
        bookingId,
        riderId: best.id,
      });
      return;
    }

    const riderRef = db.collection("riders").doc(best.id);
    const riderSnap = await tx.get(riderRef);
    const riderData = riderSnap.data();

    if (!riderData) {
      throw new Error("Matched rider disappeared before assignment");
    }

    if (!isRiderStillAssignable(riderData, best.maxAgeMinutes)) {
      logger.info("Matched rider became unavailable before transaction.", {
        bookingId,
        riderId: best.id,
      });
      return;
    }

    const businessUpdate = buildRiderBusinessAssignmentUpdate({
      riderData,
      bookingId,
      booking: freshBooking,
    });

    tx.update(bookingRef, {
      "pickupRider.riderId": best.id,
      "pickupRider.fullName": best.data.profile?.fullName || "",
      "pickupRider.phoneNumber": best.data.contact?.phoneNumber || "",
      "pickupRider.photoUrl": best.data.profile?.photoUrl || "",
      "pickupRider.vehicleType": best.data.vehicle?.type || "",
      "pickupRider.plateNumber": best.data.vehicle?.plateNumber || "",
      "pickupRider.assignedAt": FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.update(riderRef, businessUpdate);

    tx.set(bookingRef.collection("status_history").doc(), {
      status: "looking_for_pickup_rider",
      title: "Pickup Rider Assigned",
      description: `${best.data.profile?.fullName || "A rider"} was assigned for pickup.`,
      riderId: best.id,
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  logger.info("Pickup rider assigned successfully.", {
    bookingId,
    riderId: best.id,
    riderName: best.data.profile?.fullName || "",
    distanceKm: best.distanceKm,
    rating: best.rating,
    maxAgeMinutes: best.maxAgeMinutes,
  });
}

async function assignDeliveryRiderForBooking(bookingId) {
  const bookingRef = db.collection("bookings").doc(bookingId);
  const bookingSnap = await bookingRef.get();

  if (!bookingSnap.exists) {
    logger.warn("Booking does not exist for delivery rider flow.", {
      bookingId,
    });
    return;
  }

  const booking = bookingSnap.data();

  if (!booking) {
    logger.warn("Booking data missing for delivery rider flow.", { bookingId });
    return;
  }

  if (booking.status !== "ready_for_dropoff") {
    logger.info("Skipping delivery rider assignment. Wrong booking status.", {
      bookingId,
      status: booking.status,
    });
    return;
  }

  if (booking.deliveryRider?.riderId) {
    logger.info("Skipping delivery rider assignment. Rider already assigned.", {
      bookingId,
      riderId: booking.deliveryRider?.riderId,
    });
    return;
  }

  const rejectedDeliveryRiderIds = Array.isArray(
    booking.rejectedDeliveryRiderIds,
  )
    ? booking.rejectedDeliveryRiderIds
    : [];

  const deliveryCenter = getGeoPointLatLng(
    booking.customerAddress?.geopoint ||
      booking.dropoff?.geopoint ||
      booking.pickup?.geopoint,
  );

  if (!deliveryCenter) {
    logger.warn("Booking missing customer GeoPoint for delivery rider flow.", {
      bookingId,
    });
    return;
  }

  const best = await findBestNearbyRiderWithFallback({
    center: deliveryCenter,
    bookingId,
    flow: "delivery",
    rejectedRiderIds: rejectedDeliveryRiderIds,
  });

  if (!best) {
    logger.info("No eligible riders matched booking for delivery.", {
      bookingId,
      rejectedDeliveryRiderIds,
    });
    return;
  }

  await db.runTransaction(async (tx) => {
    const freshBookingSnap = await tx.get(bookingRef);
    const freshBooking = freshBookingSnap.data();

    if (!freshBooking) {
      throw new Error("Booking disappeared before delivery rider assignment");
    }

    if (freshBooking.status !== "ready_for_dropoff") {
      logger.info("Booking status changed before delivery rider transaction.", {
        bookingId,
        status: freshBooking.status,
      });
      return;
    }

    if (freshBooking.deliveryRider?.riderId) {
      logger.info("Delivery rider already assigned before transaction.", {
        bookingId,
        riderId: freshBooking.deliveryRider?.riderId,
      });
      return;
    }

    const freshRejectedDeliveryRiderIds = Array.isArray(
      freshBooking.rejectedDeliveryRiderIds,
    )
      ? freshBooking.rejectedDeliveryRiderIds
      : [];

    if (freshRejectedDeliveryRiderIds.includes(best.id)) {
      logger.info("Selected delivery rider was rejected before transaction.", {
        bookingId,
        riderId: best.id,
      });
      return;
    }

    const riderRef = db.collection("riders").doc(best.id);
    const riderSnap = await tx.get(riderRef);
    const riderData = riderSnap.data();

    if (!riderData) {
      throw new Error("Matched rider disappeared before delivery assignment");
    }

    if (!isRiderStillAssignable(riderData, best.maxAgeMinutes)) {
      logger.info(
        "Matched delivery rider became unavailable before transaction.",
        {
          bookingId,
          riderId: best.id,
        },
      );
      return;
    }

    const businessUpdate = buildRiderBusinessAssignmentUpdate({
      riderData,
      bookingId,
      booking: freshBooking,
    });

    tx.update(bookingRef, {
      "deliveryRider.riderId": best.id,
      "deliveryRider.fullName": best.data.profile?.fullName || "",
      "deliveryRider.phoneNumber": best.data.contact?.phoneNumber || "",
      "deliveryRider.photoUrl": best.data.profile?.photoUrl || "",
      "deliveryRider.vehicleType": best.data.vehicle?.type || "",
      "deliveryRider.plateNumber": best.data.vehicle?.plateNumber || "",
      "deliveryRider.assignedAt": FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.update(riderRef, businessUpdate);

    tx.set(bookingRef.collection("status_history").doc(), {
      status: "ready_for_dropoff",
      title: "Delivery Rider Assigned",
      description: `${best.data.profile?.fullName || "A rider"} was assigned for delivery.`,
      riderId: best.id,
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  logger.info("Delivery rider assigned successfully.", {
    bookingId,
    riderId: best.id,
    riderName: best.data.profile?.fullName || "",
    distanceKm: best.distanceKm,
    rating: best.rating,
    maxAgeMinutes: best.maxAgeMinutes,
  });
}

async function findBestNearbyRiderWithFallback({
  center,
  bookingId,
  flow,
  rejectedRiderIds = [],
}) {
  for (const maxAgeMinutes of RIDER_LOCATION_FRESHNESS_WINDOWS_MINUTES) {
    const best = await findBestNearbyRider({
      center,
      bookingId,
      flow,
      maxAgeMinutes,
      rejectedRiderIds,
    });

    if (best) {
      logger.info("Rider matched using freshness fallback.", {
        bookingId,
        flow,
        riderId: best.id,
        maxAgeMinutes,
      });

      return best;
    }

    logger.info("No rider found for freshness window. Trying next window.", {
      bookingId,
      flow,
      maxAgeMinutes,
      rejectedRiderIds,
    });
  }

  return null;
}

async function findBestNearbyRider({
  center,
  bookingId,
  flow,
  maxAgeMinutes,
  rejectedRiderIds = [],
}) {
  let nearbyRiders = [];

  try {
    nearbyRiders = await queryNearbyCollection({
      collectionName: "riders",
      geohashField: "location.geohash",
      geopointField: "location.geopoint",
      center,
      radiusKm: MAX_RIDER_MATCH_DISTANCE_KM,
      applyBaseQuery: (query) =>
        query
          .where("role", "==", "rider")
          .where("business.isApproved", "==", true)
          .where("business.isOnline", "==", true)
          .where("business.acceptingAssignments", "==", true),
    });
  } catch (error) {
    logger.error("Rider geohash query failed.", {
      bookingId,
      flow,
      center,
      maxAgeMinutes,
      error: error.message,
      stack: error.stack,
    });
    throw error;
  }

  const eligible = [];

  for (const item of nearbyRiders) {
    const riderId = item.doc.id;
    const rider = item.data;

    if (rejectedRiderIds.includes(riderId)) {
      logger.info(
        "Skipping rider because rider already rejected this booking.",
        {
          bookingId,
          flow,
          riderId,
        },
      );
      continue;
    }

    if (!isRiderStillAssignable(rider, maxAgeMinutes)) continue;

    const rating = Number(rider.ratings?.rating ?? 0);

    eligible.push({
      id: riderId,
      distanceKm: item.distanceKm,
      rating,
      score: item.distanceKm - rating * 0.05,
      data: rider,
      maxAgeMinutes,
    });
  }

  if (eligible.length === 0) {
    logger.info("No eligible nearby riders after filtering.", {
      bookingId,
      flow,
      maxAgeMinutes,
      rejectedRiderIds,
    });
    return null;
  }

  eligible.sort((a, b) => a.score - b.score);
  return eligible[0];
}

function isRiderStillAssignable(rider, maxAgeMinutes = 5) {
  const business = rider.business || {};

  if (business.isApproved !== true) return false;
  if (business.isOnline !== true) return false;
  if (business.acceptingAssignments !== true) return false;

  const availabilityStatus = business.availabilityStatus || "";

  if (
    availabilityStatus &&
    availabilityStatus !== "available" &&
    availabilityStatus !== "online"
  ) {
    return false;
  }

  const currentActiveRequestCount = Number(
    business.currentActiveRequestCount ?? 0,
  );

  const maxActiveRequests = Number(business.maxActiveRequests ?? 0);

  if (maxActiveRequests > 0 && currentActiveRequestCount >= maxActiveRequests) {
    return false;
  }

  if (!isRecentLocation(rider.location?.lastLocationUpdatedAt, maxAgeMinutes)) {
    return false;
  }

  return true;
}

function buildRiderBusinessAssignmentUpdate({ riderData, bookingId, booking }) {
  const business = riderData.business || {};

  const currentActiveRequestCount = Number(
    business.currentActiveRequestCount ?? 0,
  );

  const maxActiveRequests = Number(business.maxActiveRequests ?? 0);

  const existingActiveRequestIds = Array.isArray(business.activeRequestIds)
    ? business.activeRequestIds
    : [];

  const existingLaundryIds = Array.isArray(business.currentLaundryIds)
    ? business.currentLaundryIds
    : [];

  const existingCustomerIds = Array.isArray(business.currentCustomerIds)
    ? business.currentCustomerIds
    : [];

  const laundrySnapshot = getLaundrySnapshot(booking);
  const laundryId = laundrySnapshot.id || null;

  const newActiveRequestIds = existingActiveRequestIds.includes(bookingId)
    ? existingActiveRequestIds
    : [...existingActiveRequestIds, bookingId];

  const newCurrentLaundryIds =
    laundryId && !existingLaundryIds.includes(laundryId)
      ? [...existingLaundryIds, laundryId]
      : existingLaundryIds;

  const newCurrentCustomerIds =
    booking.customerId && !existingCustomerIds.includes(booking.customerId)
      ? [...existingCustomerIds, booking.customerId]
      : existingCustomerIds;

  const nextActiveCount = currentActiveRequestCount + 1;

  return {
    "business.currentActiveRequestCount": nextActiveCount,
    "business.activeRequestIds": newActiveRequestIds,
    "business.currentLaundryIds": newCurrentLaundryIds,
    "business.currentCustomerIds": newCurrentCustomerIds,
    "business.availabilityStatus":
      maxActiveRequests > 0 && nextActiveCount >= maxActiveRequests
        ? "busy"
        : "available",
    "business.acceptingAssignments":
      maxActiveRequests > 0 ? nextActiveCount < maxActiveRequests : true,
    "timestamps.updatedAt": FieldValue.serverTimestamp(),
  };
}

/* -------------------------------------------------------------------------- */
/*                               RIDER CLEANUP                                */
/* -------------------------------------------------------------------------- */

exports.cleanupRejectedPickupRider = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) return;

    const beforeRiderId = before.pickupRider?.riderId || null;
    const afterRiderId = after.pickupRider?.riderId || null;

    const riderWasRemoved = beforeRiderId && !afterRiderId;

    if (!riderWasRemoved) return;

    const laundrySnapshot = getLaundrySnapshot(before);

    await releaseRiderFromBooking({
      riderId: beforeRiderId,
      bookingId,
      laundryId: laundrySnapshot.id || null,
      customerId: before.customerId || null,
    });
  },
);

exports.cleanupRejectedDeliveryRider = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) return;

    const beforeRiderId = before.deliveryRider?.riderId || null;
    const afterRiderId = after.deliveryRider?.riderId || null;

    const riderWasRemoved = beforeRiderId && !afterRiderId;

    if (!riderWasRemoved) return;

    const laundrySnapshot = getLaundrySnapshot(before);

    await releaseRiderFromBooking({
      riderId: beforeRiderId,
      bookingId,
      laundryId: laundrySnapshot.id || null,
      customerId: before.customerId || null,
    });
  },
);

exports.cleanupRidersOnBookingClosed = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) return;

    const wasOpen = !isBookingClosed(before.status);
    const isNowClosed = isBookingClosed(after.status);

    if (!wasOpen || !isNowClosed) return;

    const pickupRiderId =
      after.pickupRider?.riderId || before.pickupRider?.riderId || null;

    const deliveryRiderId =
      after.deliveryRider?.riderId || before.deliveryRider?.riderId || null;

    const afterLaundrySnapshot = getLaundrySnapshot(after);
    const beforeLaundrySnapshot = getLaundrySnapshot(before);

    const laundryId =
      afterLaundrySnapshot.id || beforeLaundrySnapshot.id || null;

    const customerId = after.customerId || before.customerId || null;

    const jobs = [];

    if (pickupRiderId) {
      jobs.push(
        releaseRiderFromBooking({
          riderId: pickupRiderId,
          bookingId,
          laundryId,
          customerId,
        }),
      );
    }

    if (deliveryRiderId && deliveryRiderId !== pickupRiderId) {
      jobs.push(
        releaseRiderFromBooking({
          riderId: deliveryRiderId,
          bookingId,
          laundryId,
          customerId,
        }),
      );
    }

    await Promise.all(jobs);
  },
);

async function releaseRiderFromBooking({
  riderId,
  bookingId,
  laundryId,
  customerId,
}) {
  if (!riderId) return;

  const riderRef = db.collection("riders").doc(riderId);

  await db.runTransaction(async (tx) => {
    const riderSnap = await tx.get(riderRef);
    const rider = riderSnap.data();

    if (!rider) return;

    const business = rider.business || {};

    const currentActiveRequestCount = Number(
      business.currentActiveRequestCount ?? 0,
    );

    const maxActiveRequests = Number(business.maxActiveRequests ?? 0);

    const activeRequestIds = Array.isArray(business.activeRequestIds)
      ? business.activeRequestIds.filter((id) => id !== bookingId)
      : [];

    const currentLaundryIds = Array.isArray(business.currentLaundryIds)
      ? laundryId
        ? business.currentLaundryIds.filter((id) => id !== laundryId)
        : business.currentLaundryIds
      : [];

    const currentCustomerIds = Array.isArray(business.currentCustomerIds)
      ? customerId
        ? business.currentCustomerIds.filter((id) => id !== customerId)
        : business.currentCustomerIds
      : [];

    const nextCount = Math.max(0, currentActiveRequestCount - 1);

    tx.update(riderRef, {
      "business.currentActiveRequestCount": nextCount,
      "business.activeRequestIds": activeRequestIds,
      "business.currentLaundryIds": currentLaundryIds,
      "business.currentCustomerIds": currentCustomerIds,
      "business.availabilityStatus":
        nextCount <= 0
          ? rider.business?.isOnline
            ? "available"
            : "offline"
          : maxActiveRequests > 0 && nextCount >= maxActiveRequests
            ? "busy"
            : "available",
      "business.acceptingAssignments":
        rider.business?.isOnline === true &&
        (maxActiveRequests <= 0 || nextCount < maxActiveRequests),
      "timestamps.updatedAt": FieldValue.serverTimestamp(),
    });
  });
}

function isBookingClosed(status) {
  return status === "completed" || status === "cancelled";
}

/* -------------------------------------------------------------------------- */
/*                            GEOHASH QUERY HELPERS                           */
/* -------------------------------------------------------------------------- */

async function queryNearbyCollection({
  collectionName,
  geohashField,
  geopointField,
  center,
  radiusKm,
  applyBaseQuery,
}) {
  const radiusInM = radiusKm * 1000;

  const bounds = geofire.geohashQueryBounds(
    [center.latitude, center.longitude],
    radiusInM,
  );

  const seen = new Set();
  const results = [];

  const queries = bounds.map(([start, end]) => {
    let query = db.collection(collectionName);

    if (typeof applyBaseQuery === "function") {
      query = applyBaseQuery(query);
    }

    return query.orderBy(geohashField).startAt(start).endAt(end).get();
  });

  const snapshots = await Promise.all(queries);

  logger.info("Geo bounds query returned snapshots.", {
    collectionName,
    boundsCount: bounds.length,
    docsPerBound: snapshots.map((snapshot) => snapshot.size),
  });

  for (const snap of snapshots) {
    for (const doc of snap.docs) {
      if (seen.has(doc.id)) continue;
      seen.add(doc.id);

      const data = doc.data();
      const point = getNestedValue(data, geopointField);
      const itemCenter = getGeoPointLatLng(point);

      if (!itemCenter) continue;

      const distanceKm = geofire.distanceBetween(
        [center.latitude, center.longitude],
        [itemCenter.latitude, itemCenter.longitude],
      );

      if (distanceKm > radiusKm) continue;

      results.push({
        doc,
        data,
        distanceKm,
      });
    }
  }

  logger.info("Geo query completed.", {
    collectionName,
    resultsCount: results.length,
    center,
    radiusKm,
  });

  return results;
}

function getGeoPointLatLng(geoPoint) {
  if (!geoPoint) return null;

  const latitude = geoPoint.latitude;
  const longitude = geoPoint.longitude;

  if (typeof latitude !== "number" || typeof longitude !== "number") {
    return null;
  }

  return { latitude, longitude };
}

function getNestedValue(object, path) {
  if (!object || !path) return null;

  return path.split(".").reduce((current, key) => {
    if (!current || typeof current !== "object") return null;
    return current[key];
  }, object);
}

function isRecentLocation(timestamp, maxAgeMinutes) {
  if (!timestamp || typeof timestamp.toMillis !== "function") {
    return false;
  }

  const ageMs = Date.now() - timestamp.toMillis();
  return ageMs <= maxAgeMinutes * 60 * 1000;
}

/* -------------------------------------------------------------------------- */
/*                                   HELPERS                                  */
/* -------------------------------------------------------------------------- */

function buildLaundrySnapshot(laundryId, laundry) {
  return {
    id: laundryId,
    name: laundry.profile?.name || "",
    phoneNumber: laundry.contact?.phoneNumber || "",
    whatsappNumber: laundry.contact?.whatsappNumber || "",
    photoUrl: laundry.profile?.photoUrl || laundry.profile?.logoUrl || "",
    addressLine: laundry.location?.addressLine || "",
    geohash: laundry.location?.geohash || "",
    geopoint: laundry.location?.geopoint || null,
    rating: Number(laundry.ratings?.rating ?? 0),
    totalRatings: Number(laundry.ratings?.totalRatings ?? 0),
    capturedAt: FieldValue.serverTimestamp(),
  };
}

function getLaundrySnapshot(booking) {
  const snapshot =
    booking && typeof booking.laundrySnapshot === "object"
      ? booking.laundrySnapshot
      : {};

  return {
    id: snapshot.id || snapshot.laundryId || "",
    name: snapshot.name || snapshot.laundryName || "",
    phoneNumber: snapshot.phoneNumber || snapshot.phone || "",
    whatsappNumber: snapshot.whatsappNumber || "",
    photoUrl: snapshot.photoUrl || snapshot.logoUrl || "",
    addressLine: snapshot.addressLine || "",
    geohash: snapshot.geohash || "",
    geopoint: snapshot.geopoint || null,
    rating: Number(snapshot.rating ?? 0),
    totalRatings: Number(snapshot.totalRatings ?? 0),
  };
}

function supportsRequestedService(laundry, serviceType) {
  if (!serviceType) return true;

  const services = laundry.services || {};

  if (serviceType === "wash_fold") {
    return services.washFold === true || services.wash_fold === true;
  }

  if (serviceType === "wash_iron") {
    if (services.washIron === true || services.wash_iron === true) {
      return true;
    }

    const washIronExtraPerKg = laundry.pricing?.washIronExtraPerKg;
    return typeof washIronExtraPerKg === "number";
  }

  return true;
}

function supportsRequestedAddOns(laundry, selectedAddOns) {
  if (!Array.isArray(selectedAddOns) || selectedAddOns.length === 0) {
    return true;
  }

  const supportedAddOns = Array.isArray(laundry.supportedAddOns)
    ? laundry.supportedAddOns
    : [];

  if (supportedAddOns.length === 0) {
    return true;
  }

  return selectedAddOns.every((addOn) => supportedAddOns.includes(addOn));
}

function isLaundryOpenNow(openingHours) {
  if (!openingHours || typeof openingHours !== "object") {
    return true;
  }

  const dayKeys = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];
  const now = new Date();
  const todayKey = dayKeys[now.getDay()];
  const today = openingHours[todayKey];

  if (!today) return true;
  if (today.isOpen !== true) return false;

  const open = today.open;
  const close = today.close;

  if (!open || !close) return true;

  const currentMinutes = now.getHours() * 60 + now.getMinutes();
  const openMinutes = parseTimeToMinutes(open);
  const closeMinutes = parseTimeToMinutes(close);

  if (openMinutes == null || closeMinutes == null) return true;

  return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
}

function parseTimeToMinutes(time) {
  if (typeof time !== "string" || !time.includes(":")) {
    return null;
  }

  const parts = time.split(":");

  if (parts.length !== 2) return null;

  const hours = Number(parts[0]);
  const minutes = Number(parts[1]);

  if (Number.isNaN(hours) || Number.isNaN(minutes)) return null;

  return hours * 60 + minutes;
}
