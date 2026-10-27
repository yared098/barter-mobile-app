// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Barter Ethio';

  @override
  String get tagline => 'Trade what you have for what you want.';

  @override
  String get welcome => 'Welcome to Barter';

  @override
  String get signInToContinue => 'Sign in to continue bartering.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orSignInWithEmail => 'or sign in with email';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinLength => 'Min 6 characters';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Log out';

  @override
  String get facebook => 'Facebook';

  @override
  String get apple => 'Apple';

  @override
  String get phone => 'Phone';

  @override
  String comingSoon(String provider) {
    return '$provider login is coming soon';
  }

  @override
  String get testAccounts => 'Test accounts (password: password123)';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get invalidCredentials => 'Invalid credentials';

  @override
  String get homeTitle => 'Your matches';

  @override
  String get noMatchesYet => 'No matches yet';

  @override
  String get noMatchesMessage =>
      'Post another product with more categories you want — matches appear here automatically.';

  @override
  String get findingMatches => 'Finding matches...';

  @override
  String get refresh => 'Refresh';

  @override
  String get upgradeForMore => 'upgrade for more';

  @override
  String matchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
      zero: 'No matches',
    );
    return '$_temp0';
  }

  @override
  String get chats => 'Chats';

  @override
  String get noChatsYet => 'No conversations yet';

  @override
  String get noChatsMessage =>
      'Send an offer from a match to start a conversation. All your active barter negotiations appear here.';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get sayHi => 'Say hi and arrange the details.';

  @override
  String get writeMessage => 'Write a message...';

  @override
  String get send => 'Send';

  @override
  String get postProduct => 'Post product';

  @override
  String get postYourFirstProduct => 'Post your first product';

  @override
  String get postProductTitle => 'Post a product';

  @override
  String get title => 'Title';

  @override
  String get titleHint => 'iPhone 15 Pro';

  @override
  String get titleMinLength => 'Min 3 characters';

  @override
  String get description => 'Description';

  @override
  String get descriptionHint => 'Condition, age, extras...';

  @override
  String get descriptionMinLength => 'Min 10 characters';

  @override
  String get condition => 'Condition';

  @override
  String get conditionNew => 'New';

  @override
  String get conditionLikeNew => 'Like new';

  @override
  String get conditionGood => 'Good';

  @override
  String get conditionFair => 'Fair';

  @override
  String get estimatedValue => 'Estimated value (ETB)';

  @override
  String get estimatedValueHint => '12000';

  @override
  String get invalidNumber => 'Enter a number';

  @override
  String get categoryPrompt => 'What category is your item?';

  @override
  String get wantedPrompt => 'What do you want in exchange?';

  @override
  String get selectCategory => 'Select category';

  @override
  String get selectCategoryError => 'Select what category your item is';

  @override
  String get selectWantedError => 'Pick at least one category you want';

  @override
  String get addPhoto => 'Add a photo';

  @override
  String get offer => 'Offer';

  @override
  String get sendOffer => 'Send offer';

  @override
  String get acceptOffer => 'Accept';

  @override
  String get declineOffer => 'Decline';

  @override
  String get cancelOffer => 'Cancel offer';

  @override
  String get completeSwap => 'Mark as completed';

  @override
  String get offerAccepted => 'Offer accepted';

  @override
  String get offerDeclined => 'Offer declined';

  @override
  String get offerCancelled => 'Offer cancelled';

  @override
  String get swapCompleted => 'Swap completed';

  @override
  String get offerSent => 'Offer sent! The owner will be notified.';

  @override
  String get youGive => 'You give';

  @override
  String get youGet => 'You get';

  @override
  String get barterDeal => 'Barter deal';

  @override
  String aboutProduct(String title) {
    return 'About: $title';
  }

  @override
  String fromPerson(String name) {
    return 'From $name';
  }

  @override
  String get pending => 'Pending';

  @override
  String get accepted => 'Accepted';

  @override
  String get completed => 'Completed';

  @override
  String get declined => 'Declined';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get available => 'Available';

  @override
  String get swapped => 'Swapped';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get tryAgain => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get gotIt => 'Got it';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get amharic => 'አማርኛ';

  @override
  String get declineOfferConfirmTitle => 'Decline offer?';

  @override
  String get declineOfferConfirmMessage =>
      'The offer will be closed and both products unlocked.';

  @override
  String get acceptOfferConfirmTitle => 'Accept offer?';

  @override
  String get acceptOfferConfirmMessage =>
      'Ownership of both products will transfer immediately. Meet the other person to physically exchange items.';

  @override
  String get cancelOfferConfirmTitle => 'Cancel offer?';

  @override
  String get cancelOfferConfirmMessage =>
      'The offer will be withdrawn. Both products unlock.';

  @override
  String get completeSwapConfirmTitle => 'Mark swap complete?';

  @override
  String get completeSwapConfirmMessage =>
      'Only do this after you have physically exchanged items.';

  @override
  String get chatClosedCompleted => 'Swap completed — chat is closed.';

  @override
  String chatClosedOther(String status) {
    return 'This offer is $status. Chat is closed.';
  }

  @override
  String get someone => 'Someone';

  @override
  String get product => 'Product';

  @override
  String get loadingConversations => 'Loading conversations...';

  @override
  String get sender => 'Sender';

  @override
  String get receiver => 'Receiver';

  @override
  String get newOffer => 'New offer';

  @override
  String get attachment => '📎 Message';

  @override
  String get timeNow => 'now';

  @override
  String timeMinutes(int count) {
    return '${count}m';
  }

  @override
  String timeHours(int count) {
    return '${count}h';
  }

  @override
  String timeDays(int count) {
    return '${count}d';
  }

  @override
  String get productTitle => 'Product';

  @override
  String matchPercentBadge(int score) {
    return '$score% match';
  }

  @override
  String get untitled => 'Untitled';

  @override
  String get categoryLabel => 'Category';

  @override
  String get noDescription => 'No description';

  @override
  String get ownerWantsInExchange => 'Owner wants in exchange';

  @override
  String lookingFor(String kw) {
    return 'Looking for: $kw';
  }

  @override
  String get listedBy => 'Listed by';

  @override
  String productUnavailable(String status) {
    return 'This product is $status — you can no longer send an offer.';
  }

  @override
  String get categoryFallback => 'Category';
}
