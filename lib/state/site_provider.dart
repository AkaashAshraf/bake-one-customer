import 'package:flutter/foundation.dart';

import '../core/api.dart';
import '../core/models.dart';

/// Storefront data shared by all tabs: public content + catalogue, and -
/// once a customer logs in - their own price list.
class SiteProvider extends ChangeNotifier {
  SiteData? site;
  Catalog? catalog;
  String? error;
  bool loading = false;

  /// Customer-priced catalogue (only when logged in).
  Catalog? myCatalog;
  bool myLoading = false;
  String? myError;

  /// Cross-tab requests (e.g. Home → Products with a category selected).
  String? requestedCategory;
  bool requestSpecialOnly = false;
  bool requestSearchFocus = false;

  Business get business => site?.business ?? Business(name: 'Bake One');

  /// The catalogue to show right now: the customer's own prices when
  /// logged in, the public one otherwise.
  Catalog? catalogFor(bool loggedIn) => loggedIn ? (myCatalog ?? catalog) : catalog;

  Future<void> load({bool force = false}) async {
    if (loading) return;
    if (!force && site != null && catalog != null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([Api.instance.get('/site'), Api.instance.get('/catalog')]);
      site = SiteData.fromJson(results[0]);
      catalog = Catalog.fromJson(results[1]);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMine({bool force = false}) async {
    if (myLoading) return;
    if (!force && myCatalog != null) return;
    myLoading = true;
    myError = null;
    notifyListeners();
    try {
      myCatalog = Catalog.fromJson(await Api.instance.get('/products'));
    } catch (e) {
      myError = e.toString();
    } finally {
      myLoading = false;
      notifyListeners();
    }
  }

  void clearMine() {
    myCatalog = null;
    myError = null;
    notifyListeners();
  }

  void requestCategory(String? category, {bool specialOnly = false}) {
    requestedCategory = category;
    requestSpecialOnly = specialOnly;
    notifyListeners();
  }

  void requestSearch() {
    requestSearchFocus = true;
    notifyListeners();
  }

  void clearRequest() {
    requestedCategory = null;
    requestSpecialOnly = false;
    requestSearchFocus = false;
  }
}
