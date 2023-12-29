import 'package:isar/isar.dart';
import 'package:mangayomi/main.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/history.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/modules/manga/reader/providers/reader_controller_provider.dart';
import 'package:mangayomi/modules/more/settings/player/providers/player_state_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'anime_player_controller_provider.g.dart';

@riverpod
class AnimeStreamController extends _$AnimeStreamController {
  @override
  void build({required Chapter episode}) {}

  Manga getAnime() {
    return episode.manga.value!;
  }

  final incognitoMode = isar.settings.getSync(227)!.incognitoMode!;

  Settings getIsarSetting() {
    return isar.settings.getSync(227)!;
  }

  (int, bool) getEpisodeIndex() {
    final episodes = getAnime().getFilteredChapterList();
    int? index;
    for (var i = 0; i < episodes.length; i++) {
      if (episodes[i].id == episode.id) {
        index = i;
      }
    }
    if (index == null) {
      final episodes = getAnime().chapters.toList().reversed.toList();
      for (var i = 0; i < episodes.length; i++) {
        if (episodes[i].id == episode.id) {
          index = i;
        }
      }
      return (index!, false);
    }
    return (index, true);
  }

  (int, bool) getPrevEpisodeIndex() {
    final episodes = getAnime().getFilteredChapterList();
    int? index;
    for (var i = 0; i < episodes.length; i++) {
      if (episodes[i].id == episode.id) {
        index = i + 1;
      }
    }
    if (index == null) {
      final episodes = getAnime().chapters.toList().reversed.toList();
      for (var i = 0; i < episodes.length; i++) {
        if (episodes[i].id == episode.id) {
          index = i + 1;
        }
      }
      return (index!, false);
    }
    return (index, true);
  }

  (int, bool) getNextEpisodeIndex() {
    final episodes = getAnime().getFilteredChapterList();
    int? index;
    for (var i = 0; i < episodes.length; i++) {
      if (episodes[i].id == episode.id) {
        index = i - 1;
      }
    }
    if (index == null) {
      final episodes = getAnime().chapters.toList().reversed.toList();
      for (var i = 0; i < episodes.length; i++) {
        if (episodes[i].id == episode.id) {
          index = i - 1;
        }
      }
      return (index!, false);
    }
    return (index, true);
  }

  Chapter getPrevEpisode() {
    final prevEpIdx = getPrevEpisodeIndex();
    return prevEpIdx.$2
        ? getAnime().getFilteredChapterList()[prevEpIdx.$1]
        : getAnime().chapters.toList().reversed.toList()[prevEpIdx.$1];
  }

  Chapter getNextEpisode() {
    final nextEpIdx = getNextEpisodeIndex();
    return nextEpIdx.$2
        ? getAnime().getFilteredChapterList()[nextEpIdx.$1]
        : getAnime().chapters.toList().reversed.toList()[nextEpIdx.$1];
  }

  int getEpisodesLength(bool isInFilterList) {
    return isInFilterList
        ? getAnime().getFilteredChapterList().length
        : getAnime().chapters.length;
  }

  Duration geTCurrentPosition() {
    if (incognitoMode) return Duration.zero;
    String position = episode.lastPageRead ?? "0";
    return Duration(
        milliseconds:
            episode.isRead! ? 0 : int.parse(position.isEmpty ? "0" : position));
  }

  void setAnimeHistoryUpdate() {
    if (incognitoMode) return;
    isar.writeTxnSync(() {
      Manga? anime = episode.manga.value;
      anime!.lastRead = DateTime.now().millisecondsSinceEpoch;
      isar.mangas.putSync(anime);
    });
    History? history;

    final empty =
        isar.historys.filter().mangaIdEqualTo(getAnime().id).isEmptySync();

    if (empty) {
      history = History(
          mangaId: getAnime().id,
          date: DateTime.now().millisecondsSinceEpoch.toString(),
          isManga: getAnime().isManga,
          chapterId: episode.id)
        ..chapter.value = episode;
    } else {
      history = (isar.historys
          .filter()
          .mangaIdEqualTo(getAnime().id)
          .findFirstSync())!
        ..chapter.value = episode
        ..date = DateTime.now().millisecondsSinceEpoch.toString();
    }
    isar.writeTxnSync(() {
      isar.historys.putSync(history!);
      history.chapter.saveSync();
    });
  }

  void setCurrentPosition(Duration duration, Duration? totalDuration,
      {bool save = false}) {
    if (episode.isRead!) return;
    if (incognitoMode) return;
    final markEpisodeAsSeenType = ref.watch(markEpisodeAsSeenTypeStateProvider);
    final isWatch = totalDuration != null &&
            totalDuration != Duration.zero &&
            duration != Duration.zero
        ? duration.inSeconds >=
            ((totalDuration.inSeconds * markEpisodeAsSeenType) / 100).ceil()
        : false;
    if (isWatch || save) {
      final ep = episode;
      isar.writeTxnSync(() {
        ep.isRead = isWatch;
        ep.lastPageRead = (duration.inMilliseconds).toString();
        isar.chapters.putSync(ep);
      });
      if (isWatch) {
        episode.updateTrackChapterRead(ref);
      }
    }
  }
  
}
