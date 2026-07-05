package com.momento.momento.data.model

// Outcome of a multi-room post (contract B9): postToRooms writes one post
// doc per target room in a single WriteBatch and counts how many landed
// live vs pending (approval/geofence). The camera screen picks its result
// snackbar from these (all-live / all-pending / mixed).
data class PostResult(val live: Int, val pending: Int)
