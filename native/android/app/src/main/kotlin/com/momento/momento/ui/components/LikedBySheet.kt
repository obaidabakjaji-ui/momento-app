package com.momento.momento.ui.components

import android.util.Log
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.momento.momento.R
import com.momento.momento.data.UserRepository
import com.momento.momento.data.model.AppUser
import com.momento.momento.ui.theme.Coral
import com.momento.momento.ui.theme.DeepPlum
import com.momento.momento.ui.theme.SoftPink
import kotlinx.coroutines.CancellationException

/**
 * Port of `lib/widgets/liked_by_sheet.dart` — modal bottom sheet listing the
 * users who liked a post, loaded via [UserRepository.getUsers] (chunked
 * whereIn). Deliberately NOT filtered by blocked senders (contract B10).
 *
 * Deviation: the Flutter DraggableScrollableSheet (0.3–0.9, initial 0.5) is
 * replaced by an M3 ModalBottomSheet whose content is fixed at half the
 * available height.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LikedBySheet(likerIds: List<String>, onDismiss: () -> Unit) {
    val users by produceState<List<AppUser>?>(initialValue = null, likerIds) {
        value = try {
            UserRepository.getUsers(likerIds)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w("LikedBySheet", "getUsers failed", e)
            emptyList()
        }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = Color.White,
        shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp),
        dragHandle = { SheetDragHandle() },
    ) {
        Column(
            Modifier
                .fillMaxWidth()
                .fillMaxHeight(0.5f)
                .navigationBarsPadding()
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    imageVector = Icons.Filled.Favorite,
                    contentDescription = null,
                    tint = Coral,
                    modifier = Modifier.size(18.dp),
                )
                Spacer(Modifier.width(8.dp))
                Text(
                    text = pluralStringResource(
                        R.plurals.liked_by_count, likerIds.size, likerIds.size
                    ),
                    fontSize = 16.sp,
                    fontWeight = FontWeight.W700,
                    color = DeepPlum,
                )
            }
            Spacer(Modifier.height(8.dp))
            val loaded = users
            if (loaded == null) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = Coral)
                }
            } else {
                LazyColumn(Modifier.fillMaxSize()) {
                    items(loaded, key = { it.uid }) { user ->
                        LikerRow(user)
                    }
                }
            }
        }
    }
}

@Composable
private fun LikerRow(user: AppUser) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(SoftPink),
            contentAlignment = Alignment.Center,
        ) {
            if (user.photoUrl != null) {
                AsyncImage(
                    model = user.photoUrl,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.matchParentSize(),
                )
            } else {
                Text(
                    text = user.displayName.firstOrNull()?.uppercase() ?: "?",
                    color = Coral,
                    fontWeight = FontWeight.Bold,
                )
            }
        }
        Spacer(Modifier.width(16.dp))
        Text(
            text = user.displayName,
            fontWeight = FontWeight.W600,
            color = DeepPlum,
        )
    }
}

/** Flutter-styled drag handle (36x4, plum 20%, r2) shared by the sheets. */
@Composable
internal fun SheetDragHandle() {
    Box(
        modifier = Modifier
            .padding(top = 8.dp, bottom = 12.dp)
            .size(width = 36.dp, height = 4.dp)
            .clip(RoundedCornerShape(2.dp))
            .background(DeepPlum.copy(alpha = 0.2f)),
    )
}
