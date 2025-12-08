class PromptStyle {
  final String borderTop;
  final String borderBottom;
  final String borderVertical;
  final String borderConnector;
  final String arrow;
  final String checkboxOnSymbol;
  final String checkboxOffSymbol;
  final bool useInverseHighlight;
  final bool boldPrompt;
  final bool showBorder;

  const PromptStyle({
    this.borderTop = '┌',
    this.borderBottom = '└',
    this.borderVertical = '│',
    this.borderConnector = '├',
    this.arrow = '▶',
    this.checkboxOnSymbol = '■',
    this.checkboxOffSymbol = '□',
    this.useInverseHighlight = true,
    this.boldPrompt = true,
    this.showBorder = true,
  });
}
