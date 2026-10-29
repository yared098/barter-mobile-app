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

  @override
  String get postARequest => 'ጥያቄ ይለጥፉ';

  @override
  String get whatDoYouNeed => 'ምን ይፈልጋሉ?';

  @override
  String get requestTitleHint => 'ለምሳሌ፡ iPhone 12፣ 40GB ማከማቻ፣ 6GB RAM';

  @override
  String get details => 'ዝርዝር';

  @override
  String get requestDescriptionHint => 'ሁኔታ፣ ቀለም፣ ተጨማሪ መስፈርቶች…';

  @override
  String get category => 'ምድብ';

  @override
  String get couldNotLoadCategories => 'ምድቦችን መጫን አልተቻለም';

  @override
  String get howWillYouPay => 'እንዴት ይክፈላሉ?';

  @override
  String get cash => 'ጥሬ ገንዘብ';

  @override
  String get barter => 'ልውውጥ';

  @override
  String get either => 'ሁለቱም';

  @override
  String get budgetEthOptional => 'በጀት (ብር፣ አማራጭ)';

  @override
  String get min => 'ዝቅተኛ';

  @override
  String get max => 'ከፍተኛ';

  @override
  String get specificationsOptional => 'ዝርዝር መረጃ (አማራጭ)';

  @override
  String get add => 'ጨምር';

  @override
  String get specKeyHint => 'ቁልፍ (ለምሳሌ፡ storage)';

  @override
  String get specValueHint => 'እሴት (ለምሳሌ፡ 40GB)';

  @override
  String get pickupLocationOptional => 'የመውሰጃ ቦታ (አማራጭ)';

  @override
  String get gettingYourLocation => 'ቦታዎን በማግኘት ላይ…';

  @override
  String get updateMyLocation => 'ቦታዬን አዘምን';

  @override
  String get useMyCurrentLocation => 'የአሁኑን ቦታዬን ተጠቀም';

  @override
  String gpsCaptured(String lat, String lng) {
    return 'GPS ተይዟል · $lat፣ $lng';
  }

  @override
  String get locationNameHint => 'ለምሳሌ፡ አዲስ አበባ፣ ቦሌ';

  @override
  String get locationEditHint =>
      'መለያውን ለማስተካከል መስኩን ይንኩ — GPS መጋጠሚያዎች እንዳሉ ይቆያሉ።';

  @override
  String get locationAttachHint =>
      'GPS ለማያያዝ ከላይ ያለውን ቁልፍ ይንኩ፣ ወይም ቦታ በእጅ ይተይቡ።';

  @override
  String get postRequest => 'ጥያቄ ይለጥፉ';

  @override
  String get titleTooShort => 'ርዕስ ቢያንስ 3 ፊደሎች መሆን አለበት';

  @override
  String get addDescriptionPrompt => 'እባክዎ አጭር መግለጫ ያክሉ';

  @override
  String get pickCategoryPrompt => 'ምድብ ይምረጡ';

  @override
  String get budgetRangeInvalid => 'ዝቅተኛ በጀት ከከፍተኛ በጀት መብለጥ አይችልም';

  @override
  String get requestPostedSuccess => 'ጥያቄው ተለጥፏል — ተመሳሳይ ሻጮች ተመልክተዋል ✅';

  @override
  String get turnOnLocation => 'እባክዎ የመሣሪያዎን ቦታ አገልግሎት ያብሩ፣ ከዚያ እንደገና ይሞክሩ።';

  @override
  String get locationPermissionDenied => 'የቦታ ፈቃድ ተከልክሏል።';

  @override
  String get locationPermissionBlocked =>
      'የቦታ ፈቃድ ታግዷል። በመተግበሪያ ቅንብሮች ውስጥ ያብሩት።';

  @override
  String get locationCaptured => 'ቦታ ተይዟል 📍';

  @override
  String get locationServicesDisabled => 'የቦታ አገልግሎቶች ጠፍተዋል።';

  @override
  String get locationTimeout =>
      'ቦታውን በሰዓቱ ማግኘት አልተቻለም። ክፍት ቦታ ይሂዱ እና እንደገና ይሞክሩ።';

  @override
  String get locationDeniedByUser => 'ፈቃድ ተከልክሏል። ቦታ አልተያዘም።';

  @override
  String locationError(String error) {
    return 'የቦታ ስህተት: $error';
  }

  @override
  String get wantedBoard => 'የፍላጎት ሰሌዳ';

  @override
  String get wantedBoardSubtitle => 'ሰዎች ምን እንደሚፈልጉ ይመልከቱ';

  @override
  String get browse => 'ያስሱ';

  @override
  String get myRequests => 'የእኔ ጥያቄዎች';

  @override
  String get myReplies => 'የእኔ ምላሾች';

  @override
  String get loadingRequests => 'ጥያቄዎችን በመጫን ላይ…';

  @override
  String get noRequestsYet => 'እስካሁን ጥያቄዎች የሉም';

  @override
  String get noRepliesYet => 'እስካሁን ምላሾች የሉም';

  @override
  String get nobodyAskingYet => 'እስካሁን ማንም አልጠየቀም';

  @override
  String get tapPostRequestHint => 'ሻጮች ምን እንደሚፈልጉ ለመንገር \"ጥያቄ ይለጥፉ\" ን ይንኩ።';

  @override
  String get browseBoardHint => 'ሰሌዳውን ያስሱ እና ለክፍት ጥያቄዎች ምላሽ ይስጡ።';

  @override
  String get boardQuietHint => 'ሰሌዳው ጸጥ ይላል። የመጀመሪያው ይሁኑ።';

  @override
  String get request => 'ጥያቄ';

  @override
  String get acceptThisReply => 'ይህን ምላሽ ይቀበሉ?';

  @override
  String get acceptReplyBody => 'ሌላኛው ሰው ይመለከታል እና ለመጨረሻ ለማድረግ ውይይት ይከፈታል።';

  @override
  String get accept => 'ተቀበል';

  @override
  String get replyAcceptedSuccess => 'ምላሽ ተቀብሏል — ውይይት በመክፈት ላይ 🎉';

  @override
  String get replyWithdrawn => 'ምላሽ ተሰርዟል';

  @override
  String get respondToRequest => 'ለዚህ ጥያቄ ምላሽ ይስጡ';

  @override
  String get pickBestOffer => 'ምርጥ ቅናሹን ይምረጡ';

  @override
  String replyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ምላሾች',
      one: '1 ምላሽ',
      zero: 'እስካሁን ምላሾች የሉም',
    );
    return '$_temp0';
  }

  @override
  String get noRepliesPullToRefresh =>
      'እስካሁን ምላሾች የሉም። ተመሳሳይ ሻጮች ተመልክተዋል — ለማደስ ወደታች ይጎትቱ።';

  @override
  String get yourReply => 'የእርስዎ ምላሽ';

  @override
  String get replyAcceptedBanner => 'ምላሽ ተቀብሏል — ስምምነት በሂደት ላይ ነው።';

  @override
  String get withdrawMyReply => 'ምላሼን ሰርዝ';

  @override
  String get replyToRequest => 'ለጥያቄ ምላሽ ይስጡ';

  @override
  String get requesterWillBeNotified => 'ጠያቂው ይመለከታል።';

  @override
  String get attachProductOptional => 'ምርት ያያዙ (አማራጭ)';

  @override
  String get noAvailableProductsMessage => 'ያሉ ምርቶች የሉም — ምላሹ መልእክት ብቻ ይሆናል።';

  @override
  String get askPriceOptional => 'የሚጠይቁት ዋጋ (ብር፣ አማራጭ)';

  @override
  String get replyMessageHint => 'መልእክትዎን ይጻፉ…';

  @override
  String get sendReply => 'ምላሽ ላክ';

  @override
  String get loading => 'በመጫን ላይ…';

  @override
  String offers(String title) {
    return 'ቅናሾች: $title';
  }

  @override
  String get replySentSuccess => 'ምላሽ ተልኳል ✅';

  @override
  String postedBy(String name) {
    return 'በ$name';
  }

  @override
  String etbAmount(String amount) {
    return 'ብር $amount';
  }

  @override
  String etbRange(String min, String max) {
    return 'ብር $min – $max';
  }

  @override
  String etbMinPlus(String min) {
    return 'ብር $min+';
  }

  @override
  String etbUpTo(String max) {
    return 'እስከ ብር $max';
  }

  @override
  String get statusOpen => 'ክፍት';

  @override
  String get statusClosed => 'ተዘግቷል';

  @override
  String get statusFulfilled => 'ተጠናቅቋል';

  @override
  String get statusExpired => 'ጊዜው አልፎበታል';

  @override
  String get statusCancelled => 'ተሰርዟል';

  @override
  String get replyPendingStatus => 'በመጠባበቅ ላይ';

  @override
  String get replyAcceptedStatus => 'ተቀብሏል';

  @override
  String get replyRejectedStatus => 'ተከልክሏል';

  @override
  String get replyWithdrawnStatus => 'ተሰርዟል';

  @override
  String get premiumUpgradeTitle => 'እቅድዎን ያሻሽሉ';

  @override
  String get premiumPickSubtitle => 'ለልጥፍ ፍላጎትዎ የሚስማማውን እቅድ ይምረጡ።';

  @override
  String get premiumSectionDaily => 'ፈጣን ጭማሪ';

  @override
  String get premiumSectionCredits => 'የልጥፍ ጥቅሎች';

  @override
  String get premiumSectionPro => 'PRO አባልነት';

  @override
  String get premiumMaybeLater => 'ምናልባት በኋላ';

  @override
  String get premiumFallbackBanner => 'ነባሪ ዋጋዎች እየታዩ ነው — ለማደስ ይገናኙ።';

  @override
  String get planDailyPass => 'የቀን ማለፊያ';

  @override
  String get planDailyPassDesc => 'ዛሬ 10 ልጥፎች · እኩለ ሌሊት ያበቃል';

  @override
  String get planCredit100 => '100 ልጥፎች';

  @override
  String get planCredit100Desc => 'ጊዜው አያልቅም · በቀን 2 ብቻ';

  @override
  String get planCredit500 => '500 ልጥፎች';

  @override
  String get planCredit500Desc => 'ጊዜው አያልቅም · በቀን 2 ብቻ';

  @override
  String get planCredit1000 => '1000 ልጥፎች';

  @override
  String get planCredit1000Desc => 'ጊዜው አያልቅም · በቀን 2 ብቻ';

  @override
  String get planMonthlyPro => 'PRO · 30 ቀናት';

  @override
  String get planMonthlyProDesc => '60 ልጥፎች · በቀን 2 ብቻ';

  @override
  String get planYearlyPro => 'PRO · 1 ዓመት';

  @override
  String get planYearlyProDesc => '720 ልጥፎች · በቀን 2 ብቻ';

  @override
  String get badgeSave20 => '20% ቆጥብ';

  @override
  String get badgeSave16 => '16% ቆጥብ';

  @override
  String get badgeBestValue => 'ምርጥ ዋጋ';

  @override
  String get premiumCompletePayment => 'ክፍያዎን ያጠናቅቁ';

  @override
  String get premiumUpdatesAutomatically => 'ከተከፈለ በኋላ ይህ ገጽ በራሱ ይዘምናል።';

  @override
  String get premiumScanWith => 'በቴሌብር፣ CBE ወይም Chapa ይቃኙ';

  @override
  String get premiumOpenCheckout => 'የChapa ክፍያ ይክፈቱ';

  @override
  String get premiumCopyLink => 'የክፍያ አገናኝ ይቅዱ';

  @override
  String get premiumLinkCopied => 'የክፍያ አገናኝ ተቀድቷል';

  @override
  String get premiumWaiting => 'ክፍያ በመጠበቅ ላይ…';

  @override
  String get premiumStep1 => 'በሌላ ስልክ ቴሌብር ወይም Chapa ይክፈቱ';

  @override
  String get premiumStep2 => 'ከላይ ያለውን QR ይቃኙ ወይም ክፍያ ይክፈቱ የሚለውን ይንኩ';

  @override
  String get premiumStep3 => 'ክፍያውን ያረጋግጡ — ይህ ገጽ በራሱ ይዘምናል';

  @override
  String get premiumPaidTitle => 'ክፍያ ተረጋግጧል!';

  @override
  String get premiumPaidSubtitle => 'አዲሱ እቅድዎ አሁን በመለያዎ ላይ ንቁ ነው።';

  @override
  String get premiumFailedTitle => 'ክፍያ አልተሳካም';

  @override
  String get premiumExpiredTitle => 'QR ጊዜው አልፏል';

  @override
  String get premiumWindowExpired => 'የክፍያ ጊዜው አልፏል።';

  @override
  String get premiumTryAgain => 'እንደገና ይሞክሩ';

  @override
  String get premiumChooseAnotherPlan => 'ሌላ እቅድ ይምረጡ';

  @override
  String get premiumClose => 'ዝጋ';
}
