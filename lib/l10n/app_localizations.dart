import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Barter Ethio'**
  String get appName;

  /// Slogan on login screen
  ///
  /// In en, this message translates to:
  /// **'Trade what you have for what you want.'**
  String get tagline;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Barter'**
  String get welcome;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue bartering.'**
  String get signInToContinue;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @orSignInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'or sign in with email'**
  String get orSignInWithEmail;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalid;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get passwordMinLength;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get signOut;

  /// No description provided for @facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// No description provided for @apple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Shown when tapping a not-yet-implemented login option
  ///
  /// In en, this message translates to:
  /// **'{provider} login is coming soon'**
  String comingSoon(String provider);

  /// No description provided for @testAccounts.
  ///
  /// In en, this message translates to:
  /// **'Test accounts (password: password123)'**
  String get testAccounts;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials'**
  String get invalidCredentials;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your matches'**
  String get homeTitle;

  /// No description provided for @noMatchesYet.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get noMatchesYet;

  /// No description provided for @noMatchesMessage.
  ///
  /// In en, this message translates to:
  /// **'Post another product with more categories you want — matches appear here automatically.'**
  String get noMatchesMessage;

  /// No description provided for @findingMatches.
  ///
  /// In en, this message translates to:
  /// **'Finding matches...'**
  String get findingMatches;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @upgradeForMore.
  ///
  /// In en, this message translates to:
  /// **'upgrade for more'**
  String get upgradeForMore;

  /// No description provided for @matchesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No matches} =1{1 match} other{{count} matches}}'**
  String matchesCount(int count);

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @noChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noChatsYet;

  /// No description provided for @noChatsMessage.
  ///
  /// In en, this message translates to:
  /// **'Send an offer from a match to start a conversation. All your active barter negotiations appear here.'**
  String get noChatsMessage;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @sayHi.
  ///
  /// In en, this message translates to:
  /// **'Say hi and arrange the details.'**
  String get sayHi;

  /// No description provided for @writeMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get writeMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @postProduct.
  ///
  /// In en, this message translates to:
  /// **'Post product'**
  String get postProduct;

  /// No description provided for @postYourFirstProduct.
  ///
  /// In en, this message translates to:
  /// **'Post your first product'**
  String get postYourFirstProduct;

  /// No description provided for @postProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Post a product'**
  String get postProductTitle;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'iPhone 15 Pro'**
  String get titleHint;

  /// No description provided for @titleMinLength.
  ///
  /// In en, this message translates to:
  /// **'Min 3 characters'**
  String get titleMinLength;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Condition, age, extras...'**
  String get descriptionHint;

  /// No description provided for @descriptionMinLength.
  ///
  /// In en, this message translates to:
  /// **'Min 10 characters'**
  String get descriptionMinLength;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @conditionNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get conditionNew;

  /// No description provided for @conditionLikeNew.
  ///
  /// In en, this message translates to:
  /// **'Like new'**
  String get conditionLikeNew;

  /// No description provided for @conditionGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get conditionGood;

  /// No description provided for @conditionFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get conditionFair;

  /// No description provided for @estimatedValue.
  ///
  /// In en, this message translates to:
  /// **'Estimated value (ETB)'**
  String get estimatedValue;

  /// No description provided for @estimatedValueHint.
  ///
  /// In en, this message translates to:
  /// **'12000'**
  String get estimatedValueHint;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get invalidNumber;

  /// No description provided for @categoryPrompt.
  ///
  /// In en, this message translates to:
  /// **'What category is your item?'**
  String get categoryPrompt;

  /// No description provided for @wantedPrompt.
  ///
  /// In en, this message translates to:
  /// **'What do you want in exchange?'**
  String get wantedPrompt;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// No description provided for @selectCategoryError.
  ///
  /// In en, this message translates to:
  /// **'Select what category your item is'**
  String get selectCategoryError;

  /// No description provided for @selectWantedError.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one category you want'**
  String get selectWantedError;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addPhoto;

  /// No description provided for @offer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get offer;

  /// No description provided for @sendOffer.
  ///
  /// In en, this message translates to:
  /// **'Send offer'**
  String get sendOffer;

  /// No description provided for @acceptOffer.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptOffer;

  /// No description provided for @declineOffer.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineOffer;

  /// No description provided for @cancelOffer.
  ///
  /// In en, this message translates to:
  /// **'Cancel offer'**
  String get cancelOffer;

  /// No description provided for @completeSwap.
  ///
  /// In en, this message translates to:
  /// **'Mark as completed'**
  String get completeSwap;

  /// No description provided for @offerAccepted.
  ///
  /// In en, this message translates to:
  /// **'Offer accepted'**
  String get offerAccepted;

  /// No description provided for @offerDeclined.
  ///
  /// In en, this message translates to:
  /// **'Offer declined'**
  String get offerDeclined;

  /// No description provided for @offerCancelled.
  ///
  /// In en, this message translates to:
  /// **'Offer cancelled'**
  String get offerCancelled;

  /// No description provided for @swapCompleted.
  ///
  /// In en, this message translates to:
  /// **'Swap completed'**
  String get swapCompleted;

  /// No description provided for @offerSent.
  ///
  /// In en, this message translates to:
  /// **'Offer sent! The owner will be notified.'**
  String get offerSent;

  /// No description provided for @youGive.
  ///
  /// In en, this message translates to:
  /// **'You give'**
  String get youGive;

  /// No description provided for @youGet.
  ///
  /// In en, this message translates to:
  /// **'You get'**
  String get youGet;

  /// No description provided for @barterDeal.
  ///
  /// In en, this message translates to:
  /// **'Barter deal'**
  String get barterDeal;

  /// No description provided for @aboutProduct.
  ///
  /// In en, this message translates to:
  /// **'About: {title}'**
  String aboutProduct(String title);

  /// No description provided for @fromPerson.
  ///
  /// In en, this message translates to:
  /// **'From {name}'**
  String fromPerson(String name);

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @swapped.
  ///
  /// In en, this message translates to:
  /// **'Swapped'**
  String get swapped;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGeneric;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @amharic.
  ///
  /// In en, this message translates to:
  /// **'አማርኛ'**
  String get amharic;

  /// No description provided for @declineOfferConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline offer?'**
  String get declineOfferConfirmTitle;

  /// No description provided for @declineOfferConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'The offer will be closed and both products unlocked.'**
  String get declineOfferConfirmMessage;

  /// No description provided for @acceptOfferConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept offer?'**
  String get acceptOfferConfirmTitle;

  /// No description provided for @acceptOfferConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Ownership of both products will transfer immediately. Meet the other person to physically exchange items.'**
  String get acceptOfferConfirmMessage;

  /// No description provided for @cancelOfferConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel offer?'**
  String get cancelOfferConfirmTitle;

  /// No description provided for @cancelOfferConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'The offer will be withdrawn. Both products unlock.'**
  String get cancelOfferConfirmMessage;

  /// No description provided for @completeSwapConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark swap complete?'**
  String get completeSwapConfirmTitle;

  /// No description provided for @completeSwapConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Only do this after you have physically exchanged items.'**
  String get completeSwapConfirmMessage;

  /// No description provided for @chatClosedCompleted.
  ///
  /// In en, this message translates to:
  /// **'Swap completed — chat is closed.'**
  String get chatClosedCompleted;

  /// No description provided for @chatClosedOther.
  ///
  /// In en, this message translates to:
  /// **'This offer is {status}. Chat is closed.'**
  String chatClosedOther(String status);

  /// Fallback when name is missing
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get someone;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @loadingConversations.
  ///
  /// In en, this message translates to:
  /// **'Loading conversations...'**
  String get loadingConversations;

  /// No description provided for @sender.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get sender;

  /// No description provided for @receiver.
  ///
  /// In en, this message translates to:
  /// **'Receiver'**
  String get receiver;

  /// No description provided for @newOffer.
  ///
  /// In en, this message translates to:
  /// **'New offer'**
  String get newOffer;

  /// No description provided for @attachment.
  ///
  /// In en, this message translates to:
  /// **'📎 Message'**
  String get attachment;

  /// No description provided for @timeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeNow;

  /// No description provided for @timeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String timeMinutes(int count);

  /// No description provided for @timeHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String timeHours(int count);

  /// No description provided for @timeDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String timeDays(int count);

  /// No description provided for @productTitle.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get productTitle;

  /// No description provided for @matchPercentBadge.
  ///
  /// In en, this message translates to:
  /// **'{score}% match'**
  String matchPercentBadge(int score);

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @ownerWantsInExchange.
  ///
  /// In en, this message translates to:
  /// **'Owner wants in exchange'**
  String get ownerWantsInExchange;

  /// No description provided for @lookingFor.
  ///
  /// In en, this message translates to:
  /// **'Looking for: {kw}'**
  String lookingFor(String kw);

  /// No description provided for @listedBy.
  ///
  /// In en, this message translates to:
  /// **'Listed by'**
  String get listedBy;

  /// No description provided for @productUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This product is {status} — you can no longer send an offer.'**
  String productUnavailable(String status);

  /// No description provided for @categoryFallback.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryFallback;

  /// AppBar title of CreateRequestScreen
  ///
  /// In en, this message translates to:
  /// **'Post a request'**
  String get postARequest;

  /// Section label for title field
  ///
  /// In en, this message translates to:
  /// **'What do you need?'**
  String get whatDoYouNeed;

  /// Hint text for Create Request title field
  ///
  /// In en, this message translates to:
  /// **'e.g. iPhone 12, 40GB storage, 6GB RAM'**
  String get requestTitleHint;

  /// Section label for description
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Hint for Create Request description field
  ///
  /// In en, this message translates to:
  /// **'Condition, color, extra requirements…'**
  String get requestDescriptionHint;

  /// Category section label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Error when categories fail
  ///
  /// In en, this message translates to:
  /// **'Could not load categories'**
  String get couldNotLoadCategories;

  /// Payment type section label
  ///
  /// In en, this message translates to:
  /// **'How will you pay?'**
  String get howWillYouPay;

  /// Cash payment type
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// Barter payment type
  ///
  /// In en, this message translates to:
  /// **'Barter'**
  String get barter;

  /// Either cash or barter
  ///
  /// In en, this message translates to:
  /// **'Either'**
  String get either;

  /// Budget section label
  ///
  /// In en, this message translates to:
  /// **'Budget (ETB, optional)'**
  String get budgetEthOptional;

  /// Minimum label
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// Maximum label
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// Specifications section label
  ///
  /// In en, this message translates to:
  /// **'Specifications (optional)'**
  String get specificationsOptional;

  /// Add button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Spec key input hint
  ///
  /// In en, this message translates to:
  /// **'Key (e.g. storage)'**
  String get specKeyHint;

  /// Spec value input hint
  ///
  /// In en, this message translates to:
  /// **'Value (e.g. 40GB)'**
  String get specValueHint;

  /// Location section label
  ///
  /// In en, this message translates to:
  /// **'Pickup location (optional)'**
  String get pickupLocationOptional;

  /// Spinner message while GPS is fetching
  ///
  /// In en, this message translates to:
  /// **'Getting your location…'**
  String get gettingYourLocation;

  /// Location button when already captured
  ///
  /// In en, this message translates to:
  /// **'Update my location'**
  String get updateMyLocation;

  /// Location button before capture
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get useMyCurrentLocation;

  /// Chip showing captured coordinates
  ///
  /// In en, this message translates to:
  /// **'GPS captured · {lat}, {lng}'**
  String gpsCaptured(String lat, String lng);

  /// Location name text field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. Addis Ababa, Bole'**
  String get locationNameHint;

  /// Hint shown under the location field when GPS is captured
  ///
  /// In en, this message translates to:
  /// **'Tap the field to edit the text label — GPS coordinates stay attached.'**
  String get locationEditHint;

  /// Hint shown under the location field when no GPS yet
  ///
  /// In en, this message translates to:
  /// **'Tap the button above to attach GPS, or type a location manually.'**
  String get locationAttachHint;

  /// Post request button and FAB label
  ///
  /// In en, this message translates to:
  /// **'Post request'**
  String get postRequest;

  /// Validation error snackbar
  ///
  /// In en, this message translates to:
  /// **'Title must be at least 3 characters'**
  String get titleTooShort;

  /// Validation error snackbar
  ///
  /// In en, this message translates to:
  /// **'Please add a short description'**
  String get addDescriptionPrompt;

  /// Validation error snackbar
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get pickCategoryPrompt;

  /// Validation error snackbar
  ///
  /// In en, this message translates to:
  /// **'Min budget cannot exceed max budget'**
  String get budgetRangeInvalid;

  /// Success snackbar after posting a request
  ///
  /// In en, this message translates to:
  /// **'Request posted — matching sellers notified ✅'**
  String get requestPostedSuccess;

  /// Location service disabled snackbar
  ///
  /// In en, this message translates to:
  /// **'Please turn on your device location, then try again.'**
  String get turnOnLocation;

  /// Permission denied snackbar
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get locationPermissionDenied;

  /// Permission permanently denied snackbar
  ///
  /// In en, this message translates to:
  /// **'Location permission blocked. Enable it in app settings.'**
  String get locationPermissionBlocked;

  /// Success snackbar after GPS capture
  ///
  /// In en, this message translates to:
  /// **'Location captured 📍'**
  String get locationCaptured;

  /// Geolocator exception snackbar
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled.'**
  String get locationServicesDisabled;

  /// GPS timeout snackbar
  ///
  /// In en, this message translates to:
  /// **'Could not get location in time. Move to an open area and retry.'**
  String get locationTimeout;

  /// Permission exception snackbar
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Location was not captured.'**
  String get locationDeniedByUser;

  /// Generic location error snackbar
  ///
  /// In en, this message translates to:
  /// **'Location error: {error}'**
  String locationError(String error);

  /// Title of WantedBoardScreen
  ///
  /// In en, this message translates to:
  /// **'Wanted board'**
  String get wantedBoard;

  /// Subtitle of WantedBoardScreen
  ///
  /// In en, this message translates to:
  /// **'See what people are looking for'**
  String get wantedBoardSubtitle;

  /// Browse tab label
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// My Requests tab label
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// My Replies tab label
  ///
  /// In en, this message translates to:
  /// **'My Replies'**
  String get myReplies;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading requests…'**
  String get loadingRequests;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get noRequestsYet;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No replies yet'**
  String get noRepliesYet;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'Nobody is asking yet'**
  String get nobodyAskingYet;

  /// Empty state hint for My Requests
  ///
  /// In en, this message translates to:
  /// **'Tap “Post request” to tell sellers what you need.'**
  String get tapPostRequestHint;

  /// Empty state hint for My Replies
  ///
  /// In en, this message translates to:
  /// **'Browse the board and respond to open requests.'**
  String get browseBoardHint;

  /// Empty state hint for Browse
  ///
  /// In en, this message translates to:
  /// **'The board is quiet. Be the first to post.'**
  String get boardQuietHint;

  /// AppBar title of RequestDetailScreen
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// Accept confirmation title
  ///
  /// In en, this message translates to:
  /// **'Accept this reply?'**
  String get acceptThisReply;

  /// Accept confirmation body
  ///
  /// In en, this message translates to:
  /// **'The other person will be notified and a chat will open so you can finalize the deal.'**
  String get acceptReplyBody;

  /// Accept button label
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// Success snackbar after accepting a reply
  ///
  /// In en, this message translates to:
  /// **'Reply accepted — starting chat 🎉'**
  String get replyAcceptedSuccess;

  /// Success snackbar after withdrawing reply
  ///
  /// In en, this message translates to:
  /// **'Reply withdrawn'**
  String get replyWithdrawn;

  /// Primary CTA for non-author
  ///
  /// In en, this message translates to:
  /// **'Respond to this request'**
  String get respondToRequest;

  /// Header above replies for author
  ///
  /// In en, this message translates to:
  /// **'Pick the best offer'**
  String get pickBestOffer;

  /// Reply count with plural
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No replies yet} =1{1 reply} other{{count} replies}}'**
  String replyCount(int count);

  /// Empty replies hint for author
  ///
  /// In en, this message translates to:
  /// **'No replies yet. Matching sellers were notified — pull down to refresh.'**
  String get noRepliesPullToRefresh;

  /// Section label for own reply
  ///
  /// In en, this message translates to:
  /// **'Your reply'**
  String get yourReply;

  /// Banner for closed request
  ///
  /// In en, this message translates to:
  /// **'A reply was accepted — deal is in progress.'**
  String get replyAcceptedBanner;

  /// Button to withdraw own reply
  ///
  /// In en, this message translates to:
  /// **'Withdraw my reply'**
  String get withdrawMyReply;

  /// Reply bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Reply to request'**
  String get replyToRequest;

  /// Reply bottom sheet subtitle
  ///
  /// In en, this message translates to:
  /// **'The requester will be notified.'**
  String get requesterWillBeNotified;

  /// Product picker label
  ///
  /// In en, this message translates to:
  /// **'Attach a product (optional)'**
  String get attachProductOptional;

  /// Hint when user has no available products
  ///
  /// In en, this message translates to:
  /// **'No available products — reply will be message-only.'**
  String get noAvailableProductsMessage;

  /// Price field hint
  ///
  /// In en, this message translates to:
  /// **'Ask price (ETB, optional)'**
  String get askPriceOptional;

  /// Message field hint in reply sheet
  ///
  /// In en, this message translates to:
  /// **'Write your message…'**
  String get replyMessageHint;

  /// Send button in reply sheet
  ///
  /// In en, this message translates to:
  /// **'Send reply'**
  String get sendReply;

  /// Generic loading
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// Label for attached product in a reply
  ///
  /// In en, this message translates to:
  /// **'Offers: {title}'**
  String offers(String title);

  /// Success snackbar after replying
  ///
  /// In en, this message translates to:
  /// **'Reply sent ✅'**
  String get replySentSuccess;

  /// Author byline
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String postedBy(String name);

  /// ETB amount label
  ///
  /// In en, this message translates to:
  /// **'ETB {amount}'**
  String etbAmount(String amount);

  /// Budget range
  ///
  /// In en, this message translates to:
  /// **'ETB {min} – {max}'**
  String etbRange(String min, String max);

  /// Minimum budget
  ///
  /// In en, this message translates to:
  /// **'ETB {min}+'**
  String etbMinPlus(String min);

  /// Maximum budget
  ///
  /// In en, this message translates to:
  /// **'up to ETB {max}'**
  String etbUpTo(String max);

  /// Request status OPEN
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get statusOpen;

  /// Request status CLOSED
  ///
  /// In en, this message translates to:
  /// **'CLOSED'**
  String get statusClosed;

  /// Request status FULFILLED
  ///
  /// In en, this message translates to:
  /// **'FULFILLED'**
  String get statusFulfilled;

  /// Request status EXPIRED
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get statusExpired;

  /// Request status CANCELLED
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get statusCancelled;

  /// Reply status PENDING
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get replyPendingStatus;

  /// Reply status ACCEPTED
  ///
  /// In en, this message translates to:
  /// **'ACCEPTED'**
  String get replyAcceptedStatus;

  /// Reply status REJECTED
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get replyRejectedStatus;

  /// Reply status WITHDRAWN
  ///
  /// In en, this message translates to:
  /// **'WITHDRAWN'**
  String get replyWithdrawnStatus;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
