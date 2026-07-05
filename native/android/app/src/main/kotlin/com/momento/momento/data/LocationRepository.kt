package com.momento.momento.data

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import androidx.core.content.ContextCompat
import androidx.core.location.LocationManagerCompat
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withTimeoutOrNull

/**
 * Typed outcome of a location lookup — mirror of the Dart
 * `LocationResult`/`LocationFailure` pair (lib/services/location_service.dart)
 * so the UI can show the same targeted snackbars per failure case.
 *
 * PermissionDeniedForever mapping (differs from geolocator by necessity):
 * geolocator detects "denied forever" during its own permission REQUEST. On
 * native Android that distinction needs `Activity.shouldShowRequestPermission-
 * Rationale` evaluated after a launcher result — both the Activity and the
 * request flow live in the UI layer, not here. A repository holding only an
 * application Context can merely CHECK `checkSelfPermission`, which reports
 * granted / not-granted with no "forever" signal. Therefore:
 *  - [getCurrentPosition] never emits [Failure.PermissionDeniedForever]; a
 *    missing permission surfaces as [Failure.PermissionDenied].
 *  - The UI owns the request: launch the permission launcher, and when the
 *    result is denied AND `shouldShowRequestPermissionRationale == false`,
 *    treat it as [Failure.PermissionDeniedForever] (→ "open settings"
 *    snackbar). The case lives in this sealed type so that UI code and any
 *    downstream branching stay 1:1 with the Dart enum's five failures.
 */
sealed interface LocationResult {
    data class Success(val lat: Double, val lng: Double) : LocationResult

    sealed interface Failure : LocationResult {
        data object ServicesDisabled : Failure
        data object PermissionDenied : Failure
        data object PermissionDeniedForever : Failure
        data object Timeout : Failure
        data object Unknown : Failure
    }
}

// Port of lib/services/location_service.dart on FusedLocationProviderClient.
// Ladder order preserved: services enabled → permission → high-accuracy fix
// with a 10s budget. The REQUEST step of the Dart ladder is deliberately not
// here (see LocationResult docs) — callers check [hasLocationPermission],
// request via their launcher if needed, then call [getCurrentPosition].
object LocationRepository {

    // Mirrors `timeLimit: Duration(seconds: 10)` in the Dart service.
    private const val LOCATION_TIMEOUT_MS = 10_000L

    // Boxes the fused fix so "task resolved with null Location" (provider
    // couldn't produce one → Unknown) is distinguishable from the null that
    // withTimeoutOrNull returns on timeout (→ Timeout).
    private class Fix(val location: Location?)

    // checkSelfPermission only — the geolocator "granted" equivalent is either
    // fine or coarse granted. Exposed so the UI can pre-check before deciding
    // to launch a permission request.
    fun hasLocationPermission(context: Context): Boolean {
        val fine = ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_FINE_LOCATION
        )
        val coarse = ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_COARSE_LOCATION
        )
        return fine == PackageManager.PERMISSION_GRANTED ||
            coarse == PackageManager.PERMISSION_GRANTED
    }

    // Geolocator.isLocationServiceEnabled equivalent (Compat handles < API 28).
    fun isLocationServiceEnabled(context: Context): Boolean {
        val lm = context.applicationContext
            .getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return LocationManagerCompat.isLocationEnabled(lm)
    }

    /**
     * Get the current device position. Never throws — every outcome is a
     * [LocationResult] the UI can branch on, exactly like the Dart service.
     * Fail-closed consumers (geofenced posting, contract B3) treat any
     * [LocationResult.Failure] as "no coords" → post lands pending.
     */
    suspend fun getCurrentPosition(context: Context): LocationResult {
        val appContext = context.applicationContext

        if (!isLocationServiceEnabled(appContext)) {
            return LocationResult.Failure.ServicesDisabled
        }
        if (!hasLocationPermission(appContext)) {
            // Repository-level ceiling: can't distinguish "forever" here — see
            // the LocationResult docs for how the UI upgrades this case.
            return LocationResult.Failure.PermissionDenied
        }

        val fused = LocationServices.getFusedLocationProviderClient(appContext)
        val cts = CancellationTokenSource()
        return try {
            val fix = withTimeoutOrNull(LOCATION_TIMEOUT_MS) {
                Fix(
                    fused.getCurrentLocation(
                        Priority.PRIORITY_HIGH_ACCURACY, cts.token
                    ).await()
                )
            }
            when {
                fix == null -> {
                    // Timed out — tell the provider to stop working on the fix
                    // (the stable await() doesn't propagate cancellation).
                    cts.cancel()
                    LocationResult.Failure.Timeout
                }
                fix.location == null -> LocationResult.Failure.Unknown
                else -> LocationResult.Success(
                    fix.location.latitude, fix.location.longitude
                )
            }
        } catch (e: CancellationException) {
            cts.cancel()
            throw e // caller's scope was cancelled — never swallow this
        } catch (e: SecurityException) {
            // Permission revoked between the check and the fix request.
            LocationResult.Failure.PermissionDenied
        } catch (e: Exception) {
            LocationResult.Failure.Unknown
        }
    }
}
