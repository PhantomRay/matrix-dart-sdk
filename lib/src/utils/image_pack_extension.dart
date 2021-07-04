/*
 *   Famedly Matrix SDK
 *   Copyright (C) 2020, 2021 Famedly GmbH
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as
 *   published by the Free Software Foundation, either version 3 of the
 *   License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:slugify/slugify.dart';
import 'package:matrix_api_lite/matrix_api_lite.dart';

import '../room.dart';

extension ImagePackRoomExtension on Room {
  /// Get all the active image packs for the specified [usage], mapped by their slug
  Map<String, ImagePackContent> getImagePacks([ImagePackUsage usage]) {
    final allMxcs = <Uri>{}; // used for easy deduplication
    final packs = <String, ImagePackContent>{};
    final addImagePack = (BasicEvent event, {Room room, String slug}) {
      if (event == null) return;
      final imagePack = event.parsedImagePackContent;
      final finalSlug = slugify(slug ?? 'pack');
      for (final entry in imagePack.images.entries) {
        final image = entry.value;
        if (allMxcs.contains(image.url)) {
          continue;
        }
        final imageUsage = image.usage ?? imagePack.pack.usage;
        if (usage != null &&
            imageUsage != null &&
            !imageUsage.contains(usage)) {
          continue;
        }
        if (!packs.containsKey(finalSlug)) {
          packs[finalSlug] = ImagePackContent.fromJson(<String, dynamic>{});
          packs[finalSlug].pack.displayName = imagePack.pack.displayName ??
              room?.displayname ??
              finalSlug ??
              '';
          packs[finalSlug].pack.avatarUrl =
              imagePack.pack.avatarUrl ?? room?.avatar;
          packs[finalSlug].pack.attribution = imagePack.pack.attribution;
        }
        packs[finalSlug].images[entry.key] = image;
        allMxcs.add(image.url);
      }
    };
    // first we add the user image pack
    addImagePack(client.accountData['im.ponies.user_emotes'], slug: 'user');
    // next we add all the external image packs
    final packRooms = client.accountData['im.ponies.emote_rooms'];
    if (packRooms != null && packRooms.content['rooms'] is Map) {
      for (final roomEntry in packRooms.content['rooms'].entries) {
        final roomId = roomEntry.key;
        final room = client.getRoomById(roomId);
        if (room != null && roomEntry.value is Map) {
          for (final stateKeyEntry in roomEntry.value.entries) {
            final stateKey = stateKeyEntry.key;
            final fallbackSlug =
                '${room.displayname}-${stateKey.isNotEmpty ? '$stateKey-' : ''}${room.id}';
            addImagePack(room.getState('im.ponies.room_emotes', stateKey),
                room: room, slug: fallbackSlug);
          }
        }
      }
    }
    // finally we add all of this rooms state
    final allRoomEmotes = states['im.ponies.room_emotes'];
    if (allRoomEmotes != null) {
      for (final entry in allRoomEmotes.entries) {
        addImagePack(entry.value,
            room: this,
            slug: entry.value.stateKey.isEmpty ? 'room' : entry.value.stateKey);
      }
    }
    return packs;
  }

  /// Get a flat view of all the image packs of a specified [usage], that is a map of all
  /// slugs to a map of the image code to their mxc url
  Map<String, Map<String, String>> getImagePacksFlat([ImagePackUsage usage]) =>
      getImagePacks(usage).map((k, v) =>
          MapEntry(k, v.images.map((k, v) => MapEntry(k, v.url.toString()))));
}
