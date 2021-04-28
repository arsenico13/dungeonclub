import 'dart:convert';
import 'dart:html';

import '../main.dart';
import 'font_awesome.dart';
import 'game.dart';
import 'panels/code_panel.dart';
import 'panels/dialog.dart';
import 'panels/edit_game.dart' as edit_game;
import 'panels/join_session.dart' as join_session;
import 'section_page.dart';

final HtmlElement _gamesContainer = querySelector('#gamesContainer');
final ButtonElement _createGameButton = querySelector('#create');
final HtmlElement _loginTab = querySelector('#loginTab');
final ButtonElement _logout = querySelector('#logOut')
  ..onClick.listen((_) {
    window.localStorage.remove('token');
    window.location.reload();
  });

Future<void> init() {
  _createGameButton.onClick.listen((event) async {
    if (!user.registered) return print('No permissions to create a new game!');

    var name = await Dialog<String>(
      'New Campaign',
      okText: 'Create',
      onClose: () => null,
    ).withInput(placeholder: 'Campaign name...').display();

    if (name == null) return;

    var game = await user.account.createNewGame(name);
    _addEnteredGame(game, instantEdit: true);
  });

  _displayLocalEnteredGames();

  showPage('home');
  return _initLogInTab();
}

Future<bool> _initLogInTab() async {
  InputElement loginEmail = querySelector('#loginEmail');
  InputElement loginPassword = querySelector('#loginPassword');
  ButtonElement loginButton = querySelector('button#login');
  HtmlElement loginError = querySelector('#loginError');
  AnchorElement resetPassword = querySelector('#resetPassword');

  resetPassword.onClick.listen((_) => resetPanel.display());

  loginButton.onClick.listen((_) async {
    loginButton.disabled = true;
    loginError.text = null;
    if (!await user.login(loginEmail.value, loginPassword.value)) {
      loginError.text = 'Failed to log in.';
      loginButton.disabled = false;
    } else {
      loginError.text = null;
    }
  });

  var token = window.localStorage['token'];
  if (token != null) {
    if (await user.loginToken(token)) return true;
  }
  _loginTab.classes.remove('hidden');
  return false;
}

void onLogin() {
  _loginTab.classes.add('hidden');
  _logout.classes.remove('hidden');
  _displayAccountEnteredGames();
  querySelectorAll('.acc-enable').forEach((element) {
    (element as ButtonElement).disabled = false;
  });
}

Future<void> _displayAccountEnteredGames() async {
  for (var g in user.account.games) {
    _addEnteredGame(g);
  }
}

Future<void> _displayLocalEnteredGames() async {
  var idNames = Map<String, String>.from(
      jsonDecode(window.localStorage['joined'] ?? '{}'));

  for (var g in idNames.entries) {
    _addEnteredGame(Game(g.key, g.value, false));
  }
}

void _addEnteredGame(Game game, {bool instantEdit = false}) {
  HtmlElement nameEl;
  HtmlElement topRow;
  var e = DivElement()
    ..className = 'game'
    ..append(topRow = SpanElement()
      ..append(nameEl = HeadingElement.h3()..text = game.name))
    ..append(ButtonElement()
      ..text = 'Join session'
      ..onClick.listen((event) {
        if (game.owned) {
          user.joinSession(game.id);
        } else {
          join_session.display(game.id);
        }
      }));

  var displayEdit = () {
    edit_game.display(game, nameEl, e);
  };

  if (game.owned) {
    topRow.append(iconButton('cog')..onClick.listen((_) => displayEdit()));
  }

  _gamesContainer.insertBefore(e, _createGameButton);

  if (instantEdit) displayEdit();
}
