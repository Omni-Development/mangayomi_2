import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:mangayomi/utils/constant.dart';

Map<String, String> headers(String source) {
  source = source.toLowerCase();
  final cookie = Hive.box(HiveConstant.hiveBoxAppSettings)
      .get("$source-cookie", defaultValue: "");
  log(cookie);
  final userAgent = Hive.box(HiveConstant.hiveBoxAppSettings)
      .get("ua", defaultValue: defaultUserAgent);
  return source == 'mangakawaii'
      ? {
          'Referer': 'https://www.mangakawaii.io/',
          'User-Agent': userAgent,
          'Accept-Language': 'fr'
        }
      : source == 'mangahere'
          ? {"Referer": "https://www.mangahere.cc/", "Cookie": "isAdult=1"}
          : source == 'comick'
              ? {
                  'Referer': 'https://comick.app/',
                  'User-Agent': 'Tachiyomi $userAgent'
                }
              : source == "japscan"
                  ? {
                      'User-Agent': userAgent,
                      'Referer': "https://www.japscan.lol/",
                      "Cookie": cookie
                    }
                  : source == 'sushiscan'
                      ? {
                          'User-Agent': userAgent,
                          'Referer': "https://www.sushscan.net/",
                          "Cookie": cookie
                        }
                      : {'User-Agent': userAgent, "Cookie": cookie};
}
