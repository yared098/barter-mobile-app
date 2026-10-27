// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appName => 'ባርተር ኢትዮ';

  @override
  String get tagline => 'ያለህን አስተካክለህ የፈለግከውን አግኝ።';

  @override
  String get welcome => 'እንኳን ወደ ባርተር በደህና መጡ';

  @override
  String get signInToContinue => 'ባርተርን ለመቀጠል ይግቡ።';

  @override
  String get continueWithGoogle => 'በGoogle ይቀጥሉ';

  @override
  String get orSignInWithEmail => 'ወይም በኢሜይል ይግቡ';

  @override
  String get orContinueWith => 'ወይም ይቀጥሉ በ';

  @override
  String get email => 'ኢሜይል';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get emailRequired => 'ኢሜይል ያስፈልጋል';

  @override
  String get emailInvalid => 'ትክክለኛ ኢሜይል ያስገቡ';

  @override
  String get password => 'የይለፍ ቃል';

  @override
  String get passwordHint => 'የይለፍ ቃልዎን ያስገቡ';

  @override
  String get passwordRequired => 'የይለፍ ቃል ያስፈልጋል';

  @override
  String get passwordMinLength => 'ቢያንስ 6 ፊደል';

  @override
  String get showPassword => 'የይለፍ ቃል አሳይ';

  @override
  String get hidePassword => 'የይለፍ ቃል ደብቅ';

  @override
  String get signIn => 'ይግቡ';

  @override
  String get signOut => 'ውጣ';

  @override
  String get facebook => 'Facebook';

  @override
  String get apple => 'Apple';

  @override
  String get phone => 'ስልክ';

  @override
  String comingSoon(String provider) {
    return '$provider ግቤት በቅርቡ ይመጣል';
  }

  @override
  String get testAccounts => 'የፍተኛ መለያዎች (የይለፍ ቃል: password123)';

  @override
  String get loginFailed => 'ግቤት አልተሳካም';

  @override
  String get invalidCredentials => 'ልክ ያልሆነ መረጃ';

  @override
  String get homeTitle => 'ግጥሚያዎችዎ';

  @override
  String get noMatchesYet => 'እስካሁን ግጥሚያ የለም';

  @override
  String get noMatchesMessage =>
      'ተጨማሪ ምርት ለጥፈው ተጨማሪ ምድቦችን ይምረጡ — ግጥሚያዎች እዚህ ይታያሉ።';

  @override
  String get findingMatches => 'ግጥሚያዎችን በመፈለግ ላይ...';

  @override
  String get refresh => 'አድስ';

  @override
  String get upgradeForMore => 'ለተጨማሪ ያሻሽሉ';

  @override
  String matchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ግጥሚያዎች',
      one: '1 ግጥሚያ',
      zero: 'ግጥሚያ የለም',
    );
    return '$_temp0';
  }

  @override
  String get chats => 'ቻቶች';

  @override
  String get noChatsYet => 'እስካሁን ውይይት የለም';

  @override
  String get noChatsMessage =>
      'ውይይት ለመጀመር ከግጥሚያ ቅናሽ ይላኩ። ሁሉም ንቁ የባርተር ድርድሮችዎ እዚህ ይታያሉ።';

  @override
  String get noMessagesYet => 'እስካሁን መልእክት የለም';

  @override
  String get sayHi => 'ሰላም በሉ እና ዝርዝሮችን ያዘጋጁ።';

  @override
  String get writeMessage => 'መልእክት ይጻፉ...';

  @override
  String get send => 'ላክ';

  @override
  String get postProduct => 'ምርት ለጥፍ';

  @override
  String get postYourFirstProduct => 'የመጀመሪያ ምርትዎን ይለጥፉ';

  @override
  String get postProductTitle => 'ምርት ይለጥፉ';

  @override
  String get title => 'ርዕስ';

  @override
  String get titleHint => 'iPhone 15 Pro';

  @override
  String get titleMinLength => 'ቢያንስ 3 ፊደሎች';

  @override
  String get description => 'መግለጫ';

  @override
  String get descriptionHint => 'ሁኔታ, ዕድሜ, ተጨማሪ ነገሮች...';

  @override
  String get descriptionMinLength => 'ቢያንስ 10 ፊደሎች';

  @override
  String get condition => 'ሁኔታ';

  @override
  String get conditionNew => 'አዲስ';

  @override
  String get conditionLikeNew => 'እንደ አዲስ';

  @override
  String get conditionGood => 'ጥሩ';

  @override
  String get conditionFair => 'መካከለኛ';

  @override
  String get estimatedValue => 'የሚገመት ዋጋ (ብር)';

  @override
  String get estimatedValueHint => '12000';

  @override
  String get invalidNumber => 'ቁጥር ያስገቡ';

  @override
  String get categoryPrompt => 'የእቃዎ ምድብ ምንድነው?';

  @override
  String get wantedPrompt => 'በምትክ ምን ይፈልጋሉ?';

  @override
  String get selectCategory => 'ምድብ ይምረጡ';

  @override
  String get selectCategoryError => 'የእቃዎን ምድብ ይምረጡ';

  @override
  String get selectWantedError => 'ቢያንስ አንድ ምድብ ይምረጡ';

  @override
  String get addPhoto => 'ፎቶ ያክሉ';

  @override
  String get offer => 'ቅናሽ';

  @override
  String get sendOffer => 'ቅናሽ ላክ';

  @override
  String get acceptOffer => 'ተቀበል';

  @override
  String get declineOffer => 'አትቀበል';

  @override
  String get cancelOffer => 'ቅናሹን ሰርዝ';

  @override
  String get completeSwap => 'እንደተጠናቀቀ ምልክት አድርግ';

  @override
  String get offerAccepted => 'ቅናሹ ተቀባይነት አግኝቷል';

  @override
  String get offerDeclined => 'ቅናሹ አልተቀበለም';

  @override
  String get offerCancelled => 'ቅናሹ ተሰርዟል';

  @override
  String get swapCompleted => 'ልውውጡ ተጠናቅቋል';

  @override
  String get offerSent => 'ቅናሽ ተልኳል! ባለቤቱ ይመለከታል።';

  @override
  String get youGive => 'የምትሰጡት';

  @override
  String get youGet => 'የምታገኙት';

  @override
  String get barterDeal => 'የባርተር ስምምነት';

  @override
  String aboutProduct(String title) {
    return 'ስለ: $title';
  }

  @override
  String fromPerson(String name) {
    return 'ከ $name';
  }

  @override
  String get pending => 'በመጠባበቅ ላይ';

  @override
  String get accepted => 'ተቀባይነት አግኝቷል';

  @override
  String get completed => 'ተጠናቅቋል';

  @override
  String get declined => 'አልተቀበለም';

  @override
  String get cancelled => 'ተሰርዟል';

  @override
  String get available => 'ይገኛል';

  @override
  String get swapped => 'ተለውጧል';

  @override
  String get errorGeneric => 'የተሳሳተ ነገር ተከስቷል';

  @override
  String get tryAgain => 'እንደገና ሞክር';

  @override
  String get cancel => 'ሰርዝ';

  @override
  String get confirm => 'አረጋግጥ';

  @override
  String get gotIt => 'ገባኝ';

  @override
  String get back => 'ተመለስ';

  @override
  String get done => 'ተጠናቀቀ';

  @override
  String get language => 'ቋንቋ';

  @override
  String get english => 'English';

  @override
  String get amharic => 'አማርኛ';

  @override
  String get declineOfferConfirmTitle => 'ቅናሹን አትቀበል?';

  @override
  String get declineOfferConfirmMessage => 'ቅናሹ ይዘጋል፤ ሁለቱም ምርቶች እንደገና ይከፈታሉ።';

  @override
  String get acceptOfferConfirmTitle => 'ቅናሹን ተቀበል?';

  @override
  String get acceptOfferConfirmMessage =>
      'የሁለቱም ምርቶች ባለቤትነት ወዲያውኑ ይተላለፋል። እቃዎቹን በአካል ለመለዋወጥ ሌላውን ሰው ያግኙ።';

  @override
  String get cancelOfferConfirmTitle => 'ቅናሹን ሰርዝ?';

  @override
  String get cancelOfferConfirmMessage => 'ቅናሹ ይሰረዛል። ሁለቱም ምርቶች ይከፈታሉ።';

  @override
  String get completeSwapConfirmTitle => 'ልውውጡ ተጠናቅቋል ብለው ያመልክቱ?';

  @override
  String get completeSwapConfirmMessage => 'እቃዎቹን በአካል ከተለዋወጡ በኋላ ብቻ ይህን ያድርጉ።';

  @override
  String get chatClosedCompleted => 'ልውውጡ ተጠናቅቋል — ቻቱ ተዘግቷል።';

  @override
  String chatClosedOther(String status) {
    return 'ይህ ቅናሽ $status ነው። ቻቱ ተዘግቷል።';
  }

  @override
  String get someone => 'አንድ ሰው';

  @override
  String get product => 'ምርት';

  @override
  String get loadingConversations => 'ውይይቶችን በመጫን ላይ...';

  @override
  String get sender => 'ላኪ';

  @override
  String get receiver => 'ተቀባይ';

  @override
  String get newOffer => 'አዲስ ቅናሽ';

  @override
  String get attachment => '📎 መልእክት';

  @override
  String get timeNow => 'አሁን';

  @override
  String timeMinutes(int count) {
    return '$count ደቂቃ';
  }

  @override
  String timeHours(int count) {
    return '$count ሰዓት';
  }

  @override
  String timeDays(int count) {
    return '$count ቀናት';
  }

  @override
  String get productTitle => 'ምርት';

  @override
  String matchPercentBadge(int score) {
    return '$score% ተመሳሳይነት';
  }

  @override
  String get untitled => 'ያልተሰየመ';

  @override
  String get categoryLabel => 'ምድብ';

  @override
  String get noDescription => 'መግለጫ የለም';

  @override
  String get ownerWantsInExchange => 'ባለቤቱ በምትክ የሚፈልገው';

  @override
  String lookingFor(String kw) {
    return 'የሚፈልገው: $kw';
  }

  @override
  String get listedBy => 'የተለጠፈው በ';

  @override
  String productUnavailable(String status) {
    return 'ይህ ምርት $status ነው — ከእንግዲህ ቅናሽ መላክ አይቻልም።';
  }

  @override
  String get categoryFallback => 'ምድብ';
}
