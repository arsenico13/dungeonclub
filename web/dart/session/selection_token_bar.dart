import 'dart:html';

import 'package:dungeonclub/models/token_bar.dart';

import '../html/component.dart';
import '../html/input_soft_limits.dart';
import '../html_helpers.dart';
import '../lazy_input.dart';
import 'movable.dart';
import 'selection_token_bar_config.dart';

class SelectionTokenBar extends Component {
  static final panel = TokenBarConfigPanel();

  final Movable token;
  final TokenBar data;

  late Element _clickableContainer;
  late Element _iconElement;
  late Element _labelElement;
  late InputElement _valueInput;
  late InputElement _maxInput;

  SelectionTokenBar(this.token, this.data) : super.element(LIElement()) {
    htmlRoot
      ..classes = ['token-bar-mini', 'list-setting']
      ..append(_clickableContainer = SpanElement()
        ..append(_iconElement = icon('lock'))
        ..append(_labelElement = SpanElement()))
      ..append(_valueInput = InputElement(type: 'number'))
      ..append(SpanElement()..text = '/')
      ..append(_maxInput = InputElement(type: 'number'));

    _clickableContainer
      ..classes = ['label', 'interactable']
      ..onClick.listen((_) {
        panel.attachTo(this);
      });

    _valueInput
      ..placeholder = 'Value...'
      ..step = 'any';
    _maxInput
      ..placeholder = 'Max...'
      ..step = 'any';

    _valueInput.registerSoftLimits(
      getMin: () => 0,
      getMax: () => data.maxValue,
    );

    listenLazyUpdate(
      _valueInput,
      onChange: (_) => _applyInputsToData(),
      onSubmit: (_) => submitData(),
    );

    listenLazyUpdate(
      _maxInput,
      onChange: (_) => _applyInputsToData(),
      onSubmit: (_) => submitData(),
    );

    applyDataToInputs();
  }

  void applyVisibilityIcon() {
    final showIcon = data.visibility != TokenBarVisibility.VISIBLE_TO_ALL;

    if (showIcon) {
      final hidden = data.visibility == TokenBarVisibility.HIDDEN;

      applyIconClasses(_iconElement, hidden ? 'user-slash' : 'user-lock');
      _clickableContainer.children.insert(0, _iconElement);
    } else {
      _iconElement.remove();
    }
  }

  void applyDataToInputs() {
    applyVisibilityIcon();
    _labelElement.text = data.label;
    _valueInput.valueAsNumber = data.value;
    _maxInput.valueAsNumber = data.maxValue;
  }

  bool _isValidNumber(num? number) {
    if (number == null) return false;

    return number.isFinite;
  }

  void _applyInputsToData() {
    final value = _valueInput.valueAsNumber;
    final max = _maxInput.valueAsNumber;

    if (_isValidNumber(value) && _isValidNumber(max)) {
      data.value = value!.toDouble();
      data.maxValue = max!.toDouble();
      token.applyBars();
    }
  }

  void submitData() {
    token.board.sendSelectedMovablesUpdate();
  }
}
